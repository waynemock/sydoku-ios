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
                            } else {
                                game.loadSavedGame()
                            }
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
                        } else {
                            // Automatically load the saved game (no alert needed)
                            game.loadSavedGame()
                        }
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
                if !game.isComplete && !game.isGameOver {
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
                if syncTimedOut || isBackgroundSyncing {
                    syncBanner
                }
                
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
                GeometryReader { geometry in
                    let boardSize = min(geometry.size.width, geometry.size.height)
                    
                    ZStack {
                        SudokuBoard(game: game, cellSize: boardSize / 9)
                            .frame(width: boardSize, height: boardSize)
                            .opacity(game.isGenerating ? 0.5 : 1.0)
                        
                        // Overlays in separate layer to avoid clipping
                        if game.isPaused {
                            PauseOverlay(game: game)
                                .frame(width: boardSize, height: boardSize)
                                .clipped()
                        }
                        if game.isGameOver {
                            GameOverOverlay(game: game, showingNewGamePicker: $showingNewGamePicker)
                                .frame(width: boardSize, height: boardSize)
                                .clipped()
                        }
                    }
                    .frame(width: boardSize, height: boardSize)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                .padding()
                .aspectRatio(1, contentMode: .fit)
                
                // Input controls (Pen/Notes/Undo/Redo) - always above number pad
                ZStack {
                    // Centered input controls
                    HStack {
                        Spacer()
                        InputControls(game: game, theme: theme)
                        Spacer()
                    }
                }
                
                // Number Pad
                NumberPad(game: game)
                    .disabled(game.isGenerating || game.isPaused || game.isGameOver)
                
                // Mistakes and Timer, always reserve space for it
                HStack(spacing: 16) {
                    MistakesCounter(game: game, theme: theme)
                    Spacer()
                    TimerButtonView(game: game, theme: theme)
                }
                .padding(.horizontal)
                .frame(maxWidth: 600, minHeight: 36)  // Limit to portrait-like width
                
                Spacer()
            }
            .background(theme.backgroundColor)
            
            // Confetti overlay
            if game.showConfetti {
                ConfettiView()
                    .allowsHitTesting(false)
            }
        }
        .toast(isPresented: $showingErrorCheckingToast, edge: .bottom) {
            HStack(spacing: 8) {
                Image(systemName: game.settings.autoErrorChecking ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                Text(game.settings.autoErrorChecking ? "Auto Error Checking On" : "Auto Error Checking Off")
                    .font(.subheadline.weight(.semibold))
            }
            .foregroundColor(.white)
            .padding(.horizontal, 16)
            .frame(height: 44)
            .background(
                Capsule()
                    .fill(theme.primaryAccent)
            )
            .shadow(radius: 8)
        }
        .environment(\.theme, theme)
        .sheet(isPresented: $showingHistory) {
            GameHistoryView()
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
        .alert(isPresented: $showingExpiredDailyAlert) {
            Alert(
                title: Text("Yesterday's Daily Challenge"),
                message: Text("This daily challenge is from a previous day. You can continue playing, but it won't count toward your statistics or streak. Start today's challenge instead?"),
                primaryButton: .default(Text("Today's Challenge")) {
                    showingNewGamePicker = true
                },
                secondaryButton: .cancel(Text("Continue Anyway")) {
                    game.loadSavedGame()
                }
            )
        }
        .newGamePicker(isPresented: $showingNewGamePicker, game: game, theme: theme)
        .onChange(of: game.hasInProgressGame) { _, hasInProgressGame in
            // If a saved game is detected (e.g., from iCloud sync), dismiss the new game picker
            if hasInProgressGame {
                showingNewGamePicker = false
                // Load the saved game if not already loaded
                if !game.isDailyChallengeExpired && game.board.allSatisfy({ $0.allSatisfy({ $0 == 0 }) }) {
                    game.loadSavedGame()
                }
            }
        }
        .onChange(of: showingStats) { _, isShowing in
            if !isShowing && !game.isComplete && !game.isGameOver {
                game.startTimer()
            }
        }
        .onChange(of: showingSettings) { _, isShowing in
            if !isShowing && !game.isComplete && !game.isGameOver {
                game.startTimer()
            }
        }
        .onChange(of: showingAbout) { _, isShowing in
            if !isShowing && !game.isComplete && !game.isGameOver {
                game.startTimer()
            }
        }
        .onChange(of: showingCloudKitInfo) { _, isShowing in
            if !isShowing && !game.isComplete && !game.isGameOver {
                game.startTimer()
            }
        }
    }
    
    /// Banner shown for sync status (background syncing or timeout).
    private var syncBanner: some View {
        HStack(spacing: 12) {
            Image(systemName: isBackgroundSyncing || isRetrying ? "icloud.and.arrow.down" : "exclamationmark.icloud")
                .font(.title3)
                .foregroundStyle(.white)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(isBackgroundSyncing || isRetrying ? "Syncing..." : "Connection Issue")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                Text(isBackgroundSyncing || isRetrying ? "Syncing with iCloud in the background" : "Playing offline with local data")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.9))
            }
            
            Spacer()
            
            // Show retry button only if not currently syncing
            if !isBackgroundSyncing && !isRetrying {
                Button {
                    // Retry sync
                    isRetrying = true
                    Task {
                        await game.syncAllFromCloudKit()
                        // If we get here, sync completed successfully
                        await MainActor.run {
                            withAnimation {
                                syncTimedOut = false
                                isRetrying = false
                            }
                        }
                    }
                } label: {
                    HStack(spacing: 6) {
                        if isRetrying {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.8)
                        }
                        Text("Retry")
                            .font(.subheadline.weight(.semibold))
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(.white.opacity(0.2))
                    )
                }
            } else {
                // Show progress indicator when syncing
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(0.9)
            }
            
            Button {
                withAnimation {
                    syncTimedOut = false
                    isRetrying = false
                    isBackgroundSyncing = false
                }
            } label: {
                Image(systemName: "xmark")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white)
                    .frame(width: 20, height: 20)
            }
            .disabled(isRetrying || isBackgroundSyncing)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            LinearGradient(
                colors: isBackgroundSyncing || isRetrying ? [.blue, .blue.opacity(0.8)] : [.orange, .orange.opacity(0.8)],
                startPoint: .leading,
                endPoint: .trailing
            )
        )
        .transition(.move(edge: .top).combined(with: .opacity))
    }
    
    /// Loads the theme from settings.
    private func loadTheme() {
        let colorScheme = game.settings.preferredColorScheme.toColorScheme(system: systemColorScheme)
        theme = Theme(type: game.settings.themeType, colorScheme: colorScheme)
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


