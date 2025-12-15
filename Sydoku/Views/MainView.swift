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
    
    /// Whether to show the auto error checking toast.
    @State private var showingErrorCheckingToast = false
    
    /// The current theme for the app.
    @State private var theme = Theme()
    
    /// The environment color scheme.
    @Environment(\.colorScheme) var systemColorScheme
    
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
                    showingErrorCheckingToast: $showingErrorCheckingToast
                )
                
                // Status messages
                StatusView(game: game, theme: theme)
                
                // Sudoku Board
                SudokuBoard(game: game)
                    .padding()
                    .aspectRatio(1, contentMode: .fit)
                    .frame(minWidth: 400, minHeight: 400)
                    .opacity(game.isGenerating ? 0.5 : 1.0)
                    .overlay(
                        Group {
                            if game.isPaused {
                                PauseOverlay(game: game)
                            }
                            if game.isGameOver {
                                GameOverOverlay(game: game, showingNewGamePicker: $showingNewGamePicker)
                            }
                        }
                    )
                
                // Number pad controls with mistakes counter
                NumberPadHeader(game: game, theme: theme)
                
                // Number Pad
                NumberPad(game: game)
                    .disabled(game.isGenerating || game.isPaused || game.isGameOver)
                
                Spacer()
            }
            .background(theme.backgroundColor)
            
            // Confetti overlay
            if game.showConfetti {
                ConfettiView()
                    .allowsHitTesting(false)
            }
        }
        .toast(isPresented: $showingErrorCheckingToast, edge: .top) {
            HStack(spacing: 8) {
                Image(systemName: game.settings.autoErrorChecking ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                Text(game.settings.autoErrorChecking ? "Auto Error Checking On" : "Auto Error Checking Off")
                    .font(.subheadline.weight(.semibold))
            }
            .foregroundColor(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
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
        #if os(macOS)
        .frame(minWidth: 700, minHeight: 850)
        #else
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .sensoryFeedback(.error, trigger: game.triggerErrorHaptic)
        .sensoryFeedback(.success, trigger: game.triggerSuccessHaptic)
        #endif
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
        .newGamePicker(isPresented: $showingNewGamePicker, game: game)
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
        .onAppear {
            loadTheme()
            if game.hasSavedGame {
                // Check if it's an expired daily challenge
                if game.isDailyChallengeExpired {
                    showingExpiredDailyAlert = true
                } else {
                    showingContinueAlert = true
                }
            } else {
                game.generatePuzzle(difficulty: .medium)
            }
        }
    }
    
    /// Loads the theme from settings.
    private func loadTheme() {
        if let themeType = Theme.ThemeType(rawValue: game.settings.themeType) {
            let colorScheme: ColorScheme
            switch game.settings.preferredColorScheme {
            case "light":
                colorScheme = .light
            case "dark":
                colorScheme = .dark
            default:
                colorScheme = systemColorScheme
            }
            theme = Theme(type: themeType, colorScheme: colorScheme)
        }
    }
}


