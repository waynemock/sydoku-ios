import SwiftUI

/// The main view of the Sudoku application.
///
/// `ContentView` coordinates the game interface, displaying the Sudoku board,
/// controls, number pad, and various overlays (pause, game over, confetti).
/// It also manages sheets for statistics and settings. Uses a theme system for
/// customizable visual styling.
struct ContentView: View {
    /// The game instance managing puzzle state and logic.
    @StateObject private var game = SudokuGame()
    
    /// Whether the difficulty picker dialog is showing.
    @State private var showingDifficultyPicker = false
    
    /// Whether the statistics sheet is showing.
    @State private var showingStats = false
    
    /// Whether the settings sheet is showing.
    @State private var showingSettings = false
    
    /// Whether the continue game alert is showing.
    @State private var showingContinueAlert = false
    
    /// Whether the about overlay is showing.
    @State private var showingAbout = false
    
    /// The current theme for the app.
    @State private var theme = Theme()
    
    /// The environment color scheme.
    @Environment(\.colorScheme) var systemColorScheme
    
    var body: some View {
        ZStack {
            VStack {
                // Header with title and controls
                headerView
                
                // Game controls (pencil mode, hints, etc.)
                gameControlsView
                
                // Hint messages and status
                statusView
                
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
                                GameOverOverlay(game: game, showingDifficultyPicker: $showingDifficultyPicker)
                            }
                        }
                    )
                
                // Number pad controls (Notes, Auto Notes, Undo, Redo)
                undoRedoButtonsView
                
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
        .sensoryFeedback(.error, trigger: game.triggerErrorHaptic)
        .sensoryFeedback(.success, trigger: game.triggerSuccessHaptic)
        #if os(macOS)
        .frame(minWidth: 700, minHeight: 850)
        #else
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        #endif
        .alert(isPresented: $showingContinueAlert) {
            Alert(
                title: Text("Saved Game Found"),
                message: Text("Would you like to continue your saved game or start a new one?"),
                primaryButton: .default(Text("Continue")) {
                    game.loadSavedGame()
                },
                secondaryButton: .default(Text("New Game")) {
                    showingDifficultyPicker = true
                }
            )
        }
        .confirmationDialog("Select Difficulty", isPresented: $showingDifficultyPicker, titleVisibility: .visible) {
            Button("Easy (46 clues)") {
                game.generatePuzzle(difficulty: .easy)
            }
            Button("Medium (36 clues)") {
                game.generatePuzzle(difficulty: .medium)
            }
            Button("Hard (29 clues)") {
                game.generatePuzzle(difficulty: .hard)
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Each puzzle has a unique solution")
        }
        .onAppear {
            loadTheme()
            if game.hasSavedGame {
                showingContinueAlert = true
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
    
    // MARK: - Header View
    
    /// The header section containing app title, timer, and action buttons.
    ///
    /// Displays the app name, daily challenge indicator, timer with pause button,
    /// and buttons for settings, statistics, undo, and redo. Uses themed colors.
    private var headerView: some View {
        HStack {
            // Left side: Title and daily indicator
            HStack(spacing: 8) {
                Text("Sydoku")
                    .foregroundColor(theme.primaryText)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                if game.isDailyChallenge {
                    Image(systemName: "calendar")
                        .foregroundColor(theme.warningColor)
                        .font(.title2)
                }
            }
            
            Spacer()
            
            // Center: Timer display with pause button
            Button(action: { game.togglePause() }) {
                HStack(spacing: 6) {
                    Image(systemName: game.isPaused ? "play.fill" : "pause.fill")
                        .foregroundColor(theme.primaryAccent)
                    Text(game.formattedTime)
                        .font(.system(.body, design: .monospaced, weight: .medium))
                        .foregroundColor(theme.primaryAccent)
                }
                .padding(.horizontal, 12)
                .frame(height: 44)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(theme.primaryAccent.opacity(0.2))
                )
            }
            .disabled(game.isGenerating || game.isComplete || game.isGameOver)
            .buttonStyle(ScaleButtonStyle())
            
            Spacer()
            
            // Right side: Action buttons
            HStack(spacing: 8) {
                // New game menu button
                Menu {
                    Button(action: {
                        game.generateDailyChallenge()
                    }) {
                        Label(game.dailyChallengeCompleted ? "Daily (Completed ✓)" : "Daily Challenge", systemImage: "calendar")
                    }
                    Button(action: {
                        if game.hasSavedGame {
                            showingContinueAlert = true
                        } else {
                            showingDifficultyPicker = true
                        }
                    }) {
                        Label("New Puzzle", systemImage: "plus.circle")
                    }
                } label: {
                    Image(systemName: "plus")
                        .font(.title3.weight(.semibold))
                        .foregroundColor(.white)
                        .frame(width: 44, height: 44)
                        .background(
                            Circle()
                                .fill(theme.successColor)
                        )
                }
                .disabled(game.isGenerating)
                
                // Tools menu button
                Menu {
                    Button(action: { game.giveHint() }) {
                        Label("Progressive Hint", systemImage: "lightbulb")
                    }
                    .disabled(game.isGenerating || game.isComplete || game.isPaused || game.isGameOver)
                    
                    Button(action: { game.resetHints() }) {
                        Label("Reset Hints", systemImage: "arrow.counterclockwise")
                    }
                    .disabled(game.isGenerating || game.isComplete || game.isPaused || game.isGameOver)
                    
                    Divider()
                    
                    Button(action: { game.autoFillNotes() }) {
                        Label("Auto Notes", systemImage: "wand.and.stars")
                    }
                    .disabled(game.isGenerating || game.isPaused || game.isGameOver)

                    Divider()
                    
                    Button(action: { showingStats = true }) {
                        Label("Statistics", systemImage: "chart.bar.fill")
                    }
                    
                    Button(action: { showingSettings = true }) {
                        Label("Settings", systemImage: "gearshape.fill")
                    }
                    
                    Divider()
                    
                    Button(action: { showingAbout = true }) {
                        Label("About Sydoku", systemImage: "info.circle")
                    }
                    
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .font(.title3.weight(.semibold))
                        .foregroundColor(.white)
                        .frame(width: 44, height: 44)
                        .background(
                            Circle()
                                .fill(theme.secondaryAccent)
                        )
                }
                
            }
        }
        .padding(.horizontal)
        .padding(.top)
    }
    
    // MARK: - Game Controls View
    
    /// The game controls section with hints and new game buttons.
    ///
    /// Provides mistake counter, hint menu, and options to start a new game 
    /// or daily challenge. Uses themed colors.
    private var gameControlsView: some View {
        HStack {
            // Mistake counter
            if game.settings.mistakeLimit > 0 || game.mistakes > 0 {
                Text(game.mistakesText)
                    .font(.body.weight(.semibold))
                    .foregroundColor(game.mistakes >= game.settings.mistakeLimit && game.settings.mistakeLimit > 0 ? theme.errorColor : theme.warningColor)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(theme.warningColor.opacity(0.2))
                    )
            }
        }
        .padding(.horizontal)
        .padding(.bottom, 8)
    }
    
    // MARK: - Status View
    
    /// The status section displaying hint messages and mistake counter.
    ///
    /// Shows active hint information (region, number, or cell) and the current
    /// number of mistakes with optional limit. Uses themed colors.
    private var statusView: some View {
        Group {
            if let region = game.hintRegion {
                Text("💡 Try focusing on \(region)")
                    .font(.headline)
                    .foregroundColor(theme.warningColor)
                    .padding(.vertical, 8)
            } else if let number = game.hintNumber {
                Text("💡 Look for where \(number) can go")
                    .font(.headline)
                    .foregroundColor(theme.warningColor)
                    .padding(.vertical, 8)
            } else if game.hintCell != nil {
                Text("💡 The highlighted cell is a good next move")
                    .font(.headline)
                    .foregroundColor(theme.successColor)
                    .padding(.vertical, 8)
            } else if game.isGenerating {
                HStack {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                        .tint(theme.primaryAccent)
                    Text("Generating puzzle...")
                        .font(.headline)
                        .foregroundColor(theme.primaryText)
                }
                .padding()
            } else if game.isComplete {
                VStack(spacing: 4) {
                    if game.isDailyChallenge {
                        Text("🎉 Daily Challenge Complete! 🎉")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundStyle(
                                .linearGradient(
                                    colors: [theme.warningColor, theme.secondaryAccent],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                    } else {
                        Text("🎉 Congratulations! 🎉")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundStyle(
                                .linearGradient(
                                    colors: [theme.successColor, theme.secondaryAccent],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                    }
                    Text("Completed in \(game.formattedTime)")
                        .font(.headline)
                        .foregroundColor(theme.primaryAccent)
                }
                .padding()
                .transition(.scale.combined(with: .opacity))
            } else if game.hasError {
                Text("⚠️ There are errors in your solution")
                    .font(.headline)
                    .foregroundColor(theme.errorColor)
                    .padding(.vertical, 8)
            }
        }
    }
    
    // MARK: - Number Pad Controls View
    
    /// Control buttons positioned above the number pad.
    ///
    /// Shows Pen/Notes mode toggle and Auto Notes button on the left, and Undo/Redo buttons on the right
    /// for easy access while using the number pad.
    private var undoRedoButtonsView: some View {
        HStack {
            Spacer()
            
            // Left of Pen/Notes: Undo button
            Button(action: { game.undo() }) {
                Image(systemName: "arrow.uturn.backward")
                    .font(.title3.weight(.semibold))
                    .foregroundColor(.white)
                    .frame(width: 44, height: 44)
                    .background(
                        Circle()
                            .fill(game.canUndo ? theme.primaryAccent : theme.secondaryText.opacity(0.5))
                    )
            }
            .disabled(!game.canUndo || game.isGenerating || game.isPaused || game.isGameOver)
            .buttonStyle(ScaleButtonStyle())
            
            // Center: Input mode controls (Pen/Notes)
            ZStack(alignment: .leading) {
                // Background capsule
                Capsule()
                    .fill(theme.cellBackgroundColor)
                    .frame(width: 176, height: 52)
                
                // Sliding background capsule
                Capsule()
                    .fill(game.isPencilMode ? theme.secondaryAccent : theme.primaryAccent)
                    .frame(width: 84, height: 44)
                    .offset(x: game.isPencilMode ? 88 : 4)
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: game.isPencilMode)
                
                // Button group
                HStack(spacing: 0) {
                    // Pen button (regular mode)
                    Button(action: { 
                        game.isPencilMode = false
                    }) {
                        Text("Pen")
                            .font(.body.weight(.bold))
                            .foregroundColor(!game.isPencilMode ? .white : theme.secondaryText)
                            .frame(width: 88, height: 52)
                    }
                    .buttonStyle(.plain)
                    .disabled(game.isPaused || game.isGameOver)
                    
                    // Notes button (pencil mode)
                    Button(action: { 
                        game.isPencilMode = true
                    }) {
                        Text("Notes")
                            .font(.body.weight(.bold))
                            .foregroundColor(game.isPencilMode ? .white : theme.secondaryText)
                            .frame(width: 88, height: 52)
                    }
                    .buttonStyle(.plain)
                    .disabled(game.isPaused || game.isGameOver)
                }
            }
            
            // Right of Pen/Notes: Redo button
            Button(action: { game.redo() }) {
                Image(systemName: "arrow.uturn.forward")
                    .font(.title3.weight(.semibold))
                    .foregroundColor(.white)
                    .frame(width: 44, height: 44)
                    .background(
                        Circle()
                            .fill(game.canRedo ? theme.primaryAccent : theme.secondaryText.opacity(0.5))
                    )
            }
            .disabled(!game.canRedo || game.isGenerating || game.isPaused || game.isGameOver)
            .buttonStyle(ScaleButtonStyle())
            
            Spacer()
        }
        .padding(.horizontal)
        .padding(.bottom, 8)
    }
}

// MARK: - Action Button Component

/// A reusable action button with consistent styling.
struct ActionButton: View {
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.title3.weight(.semibold))
                .foregroundColor(.white)
                .frame(width: 44, height: 44)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(color)
                )
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

