import SwiftUI

/// The main view of the Sudoku application.
///
/// `ContentView` coordinates the game interface, displaying the Sudoku board,
/// controls, number pad, and various overlays (pause, game over, confetti).
/// It also manages sheets for statistics and settings. Uses a theme system for
/// customizable visual styling.
struct MainView: View {
    /// The game instance managing puzzle state and logic.
    @StateObject private var game = SudokuGame()
    
    /// The SwiftData model context for persistence operations.
    @Environment(\.modelContext) private var modelContext
    
    /// Whether the difficulty picker dialog is showing.
    @State private var showingNewGamePicker = false
    
    /// Whether the game history sheet is showing.
    @State private var showingHistory = false
    
    /// Whether the statistics sheet is showing.
    @State private var showingStats = false
    
    /// Whether the settings sheet is showing.
    @State private var showingSettings = false
    
    /// Whether the expired daily challenge alert is showing.
    @State private var showingExpiredDailyAlert = false
    
    /// Whether the about overlay is showing.
    @State private var showingAbout = false
    
    /// Whether the CloudKit info sheet is showing.
    @State private var showingCloudKitInfo = false
    
    /// Whether to show the auto error checking toast.
    @State private var showingErrorCheckingToast = false
    
    /// Whether the app is still loading (syncing from CloudKit).
    @State private var isLoading = true
    
    /// Whether the sync is taking longer than expected.
    @State private var isSlowConnection = false
    
    /// Whether the sync timed out (offline or slow connection).
    @State private var syncTimedOut = false
    
    /// Whether a retry sync is currently in progress.
    @State private var isRetrying = false
    
    /// Whether a background sync is in progress (after user dismissed loading overlay).
    @State private var isBackgroundSyncing = false
    
    /// Whether this is the initial app launch (to avoid double-syncing on first scene activation).
    @State private var isInitialLaunch = true
    
    /// The current theme for the app.
    @State private var theme = Theme()
    
    /// App scene phase to detect foreground/background transitions.
    @Environment(\.scenePhase) private var scenePhase
    
    /// The environment color scheme.
    @Environment(\.colorScheme) var systemColorScheme
    
     var body: some View {
        ZStack {
            // Main game interface (always present)
            mainContent
            
            // Loading overlay (shown on top during sync)
            if isLoading {
                LaunchLoadingView(
                    isSlowConnection: isSlowConnection,
                    onCancel: {
                        // User chose to continue - dismiss overlay but keep syncing in background
                        withAnimation {
                            isLoading = false
                            isBackgroundSyncing = true
                        }
                        
                        // Show new game picker or load saved game
                        if game.hasInProgressGame {
                            if game.isDailyChallengeExpired {
                                showingExpiredDailyAlert = true
                            }
                            // Timer already started by loadGame() if game is not paused
                        } else {
                            showingNewGamePicker = true
                        }
                    }
                )
                .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: isLoading)
        .environment(\.theme, theme)
        .onAppear {
            // Configure SwiftData persistence
            let persistence = PersistenceService(modelContext: modelContext)
            game.configurePersistence(persistenceService: persistence)
            
            loadTheme()
            
            // Perform initial sync - delay slightly to let UI render first
            Task {
                // Give the loading view a moment to fully render
                try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
                
                await performSync()
                
                // After sync completes, check for saved game
                await MainActor.run {
                    if game.hasInProgressGame {
                        // Check if it's an expired daily challenge
                        if game.isDailyChallengeExpired {
                            showingExpiredDailyAlert = true
                        }
                        // Timer already started by loadGame() during sync if game is not paused
                    } else {
                        // No saved game - show the new game picker so user can choose difficulty
                        showingNewGamePicker = true
                    }
                }
            }
        }
        .onChange(of: scenePhase) { oldPhase, newPhase in
            switch newPhase {
            case .active:
                // Skip sync on initial launch (already handled in onAppear)
                guard !isInitialLaunch else {
                    isInitialLaunch = false
                    return
                }
                
                // App came to foreground - sync from CloudKit
                Task {
                    await performSync()
                }
                
            case .background:
                // App going to background - save current state
                if !game.isComplete && !game.isMistakeLimitReached {
                    game.saveGame()
                }
            default:
                break
            }
        }
        .onChange(of: game.settings.themeType) { _, _ in
            loadTheme()
        }
        .onChange(of: game.settings.preferredColorScheme) { _, _ in
            loadTheme()
        }
        .onChange(of: systemColorScheme) { _, _ in
            loadTheme()
        }
    }
    
    /// The main game content shown after loading completes.
    private var mainContent: some View {
        ZStack {
            VStack(spacing: 0) {
                // Sync banner (timeout or background syncing)
                SyncBanner(
                    game: game,
                    syncTimedOut: $syncTimedOut,
                    isBackgroundSyncing: $isBackgroundSyncing,
                    isRetrying: $isRetrying
                )
                
                // Header with title and controls
                HeaderView(
                    game: game,
                    theme: theme,
                    showingNewGamePicker: $showingNewGamePicker,
                    showingHistory: $showingHistory,
                    showingStats: $showingStats,
                    showingSettings: $showingSettings,
                    showingAbout: $showingAbout,
                    showingErrorCheckingToast: $showingErrorCheckingToast,
                    showingCloudKitInfo: $showingCloudKitInfo
                )
                
                // Status messages
                StatusView(game: game, theme: theme)
                
                // Sudoku Board
                SudokuBoard(game: game, showingNewGamePicker: $showingNewGamePicker)
                
                // Footer with input controls, number pad and status indicators
                FooterView(game: game, theme: theme, showingNewGamePicker: $showingNewGamePicker)
                
                Spacer()
            }
            .background(theme.backgroundColor)
            
            // Confetti overlay
            if game.showConfetti {
                ConfettiView()
            }
        }
        .toast(isPresented: $showingErrorCheckingToast, edge: .bottom) {
            AutoErrorCheckingToast(isEnabled: game.settings.autoErrorChecking, theme: theme)
        }
        .environment(\.theme, theme)
        .sheet(isPresented: $showingHistory) {
            GameHistoryView(onResumeGame: { selectedGame in
                loadGame(from: selectedGame)
            }, onViewGame: { selectedGame in
                loadGame(from: selectedGame)
            })
            .environment(\.theme, theme)
        }
        .sheet(isPresented: $showingStats) {
            StatisticsView(game: game)
                .environment(\.theme, theme)
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView(game: game, theme: $theme)
                .environment(\.theme, theme)
        }
        .sheet(isPresented: $showingAbout) {
            AboutView()
                .environment(\.theme, theme)
        }
        .sheet(isPresented: $showingCloudKitInfo) {
            CloudKitInfo()
                .environment(\.theme, theme)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .sensoryFeedback(.error, trigger: game.triggerErrorHaptic)
        .sensoryFeedback(.success, trigger: game.triggerSuccessHaptic)
        .startTodaysChallengeAlert(
            isPresented: $showingExpiredDailyAlert,
            game: game,
            onStartToday: {
                showingNewGamePicker = true
            }
        )
        .newGamePicker(isPresented: $showingNewGamePicker, game: game, showingHistory: $showingHistory, theme: theme)
        .onChange(of: game.hasInProgressGame) { _, hasInProgressGame in
            // If a saved game is detected (e.g., from iCloud sync)
            if hasInProgressGame {
                // Only dismiss the new game picker if the board actually has content
                if game.hasBoardBeenGenerated {
                    showingNewGamePicker = false
                    // Timer already started by loadGame() if game is not paused
                }
            } else {
                // No game in progress - show the new game picker if board is empty
                if !game.hasBoardBeenGenerated {
                    showingNewGamePicker = true
                }
            }
        }
        .onChange(of: showingHistory) { _, isShowing in
            game.toggleTimer(paused: isShowing)
        }
        .onChange(of: showingStats) { _, isShowing in
            game.toggleTimer(paused: isShowing)
        }
        .onChange(of: showingSettings) { _, isShowing in
            game.toggleTimer(paused: isShowing)
        }
        .onChange(of: showingAbout) { _, isShowing in
            game.toggleTimer(paused: isShowing)
        }
        .onChange(of: showingCloudKitInfo) { _, isShowing in
            game.toggleTimer(paused: isShowing)
        }
    }
    
    /// Loads the theme from settings.
    private func loadTheme() {
        let colorScheme = game.settings.preferredColorScheme.toColorScheme(system: systemColorScheme)
        theme = Theme(type: game.settings.themeType, colorScheme: colorScheme)
    }

    /// Loads a game
    private func loadGame(from aGame: Game) {
        // Load the selected game using the helper function
        game.loadGame(from: aGame)
    }

    /// Performs a CloudKit sync with timeout and loading UI.
    private func performSync() async {
        // Show loading overlay
        await MainActor.run {
            withAnimation {
                isLoading = true
                isSlowConnection = false
                isBackgroundSyncing = false
            }
        }
        
        var didComplete = false
        
        // Race between sync, slow connection warning, and timeout
        await withTaskGroup(of: String.self) { group in
            // Sync task
            group.addTask {
                await game.syncAllFromCloudKit()
                return "completed"
            }
            
            // Slow connection warning task (3 seconds)
            group.addTask {
                try? await Task.sleep(nanoseconds: 3_000_000_000)
                return "slow"
            }
            
            // Timeout task (10 seconds total)
            group.addTask {
                try? await Task.sleep(nanoseconds: 10_000_000_000)
                return "timeout"
            }
            
            // Process results
            for await result in group {
                if result == "completed" {
                    didComplete = true
                    group.cancelAll()
                    break
                } else if result == "slow" {
                    // Show slow connection warning in loading screen
                    await MainActor.run {
                        withAnimation {
                            isSlowConnection = true
                        }
                    }
                } else if result == "timeout" {
                    // Timed out completely
                    group.cancelAll()
                    break
                }
            }
        }
        
        // Update UI after sync completes or times out
        await MainActor.run {
            withAnimation {
                isLoading = false
                
                if didComplete {
                    // Sync completed successfully
                    isBackgroundSyncing = false
                    syncTimedOut = false
                } else {
                    // Sync timed out or failed
                    if isBackgroundSyncing {
                        // Already dismissed overlay, just stop showing background sync
                        isBackgroundSyncing = false
                    }
                    syncTimedOut = true
                }
            }
        }
    }
}


