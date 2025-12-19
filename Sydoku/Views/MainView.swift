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
    
    /// Whether the statistics sheet is showing.
    @State private var showingStats = false
    
    /// Whether the settings sheet is showing.
    @State private var showingSettings = false
    
    /// Whether the continue game alert is showing.
    @State private var showingContinueAlert = false
    
    /// Whether the expired daily challenge alert is showing.
    @State private var showingExpiredDailyAlert = false
    
    /// Whether the about overlay is showing.
    @State private var showingAbout = false
    
    /// Whether the CloudKit info sheet is showing.
    @State private var showingCloudKitInfo = false
    
    /// Whether to show the auto error checking toast.
    @State private var showingErrorCheckingToast = false
    
    /// The current theme for the app.
    @State private var theme = Theme()
    
    /// App scene phase to detect foreground/background transitions.
    @Environment(\.scenePhase) private var scenePhase
    
    /// The environment color scheme.
    @Environment(\.colorScheme) var systemColorScheme
    
    /// The horizontal size class for responsive layout.
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    
    /// Whether to show the mistakes counter.
    private var showMistakes: Bool {
        game.settings.autoErrorChecking && (game.settings.mistakeLimit > 0 || game.mistakes > 0)
    }
    
    var body: some View {
        ZStack {
            VStack {
                // Header with title and controls
                HeaderView(
                    game: game,
                    theme: theme,
                    showingNewGamePicker: $showingNewGamePicker,
                    showingContinueAlert: $showingContinueAlert,
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
                    
                    // iPad: Mistakes counter overlaid on the left, aligned with board edge
                    if horizontalSizeClass == .regular && showMistakes {
                        HStack {
                            MistakesCounter(game: game, theme: theme)
                                .padding(.leading, 24) // Match board padding (16) + additional spacing
                            Spacer()
                        }
                    }
                }
                
                // Number Pad
                NumberPad(game: game)
                    .disabled(game.isGenerating || game.isPaused || game.isGameOver)
                
                // Bottom row layout (iPhone only)
                if horizontalSizeClass == .compact {
                    // iPhone: Timer centered when no mistakes, side by side when mistakes showing
                    if showMistakes {
                        // Mistakes showing: side by side
                        HStack(spacing: 16) {
                            MistakesCounter(game: game, theme: theme)
                            Spacer()
                            TimerButtonView(game: game, theme: theme)
                        }
                        .padding(.horizontal)
                        .padding(.top, 8)
                    } else {
                        // No mistakes: timer centered
                        HStack {
                            Spacer()
                            TimerButtonView(game: game, theme: theme)
                            Spacer()
                        }
                        .padding(.horizontal)
                        .padding(.top, 8)
                    }
                }
                
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
        .alert(isPresented: Binding(
            get: { showingContinueAlert || showingExpiredDailyAlert },
            set: { if !$0 { showingContinueAlert = false; showingExpiredDailyAlert = false } }
        )) {
            if showingExpiredDailyAlert {
                return Alert(
                    title: Text("Yesterday's Daily Challenge"),
                    message: Text("This daily challenge is from a previous day. You can continue playing, but it won't count toward your statistics or streak. Start today's challenge instead?"),
                    primaryButton: .default(Text("Today's Challenge")) {
                        showingNewGamePicker = true
                    },
                    secondaryButton: .cancel(Text("Continue Anyway")) {
                        game.loadSavedGame()
                    }
                )
            } else {
                return Alert(
                    title: Text("Saved Game Found"),
                    message: Text("Would you like to continue your saved game or start a new one?"),
                    primaryButton: .default(Text("Continue")) {
                        game.loadSavedGame()
                    },
                    secondaryButton: .default(Text("New Game")) {
                        showingNewGamePicker = true
                    }
                )
            }
        }
        .newGamePicker(isPresented: $showingNewGamePicker, game: game, theme: theme)
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
        .onAppear {
            // Configure SwiftData persistence
            let persistence = PersistenceService(modelContext: modelContext)
            game.configurePersistence(persistenceService: persistence)
            
            loadTheme()
            if game.hasSavedGame {
                // Check if it's an expired daily challenge
                if game.isDailyChallengeExpired {
                    showingExpiredDailyAlert = true
                } else {
                    showingContinueAlert = true
                }
            } else {
                // No saved game - show the new game picker so user can choose difficulty
                showingNewGamePicker = true
            }
        }
        .onChange(of: scenePhase) { oldPhase, newPhase in
            switch newPhase {
            case .active:
                // App came to foreground - refresh game data from CloudKit
                game.reloadFromPersistence()
            case .background:
                // App going to background - save current state
                if !game.isComplete && !game.isGameOver {
                    game.saveGame()
                }
            default:
                break
            }
        }
    }
    
    /// Loads the theme from settings.
    private func loadTheme() {
        let colorScheme = game.settings.preferredColorScheme.toColorScheme(system: systemColorScheme)
        theme = Theme(type: game.settings.themeType, colorScheme: colorScheme)
    }
}


