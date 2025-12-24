import SwiftUI

/// A view that presents a view for selecting puzzle difficulty and game mode.
struct NewGameView: View {
    /// The game instance managing puzzle state and logic.
    @ObservedObject var game: SudokuGame
    
    /// Binding to control the presentation of the difficulty picker.
    @Binding var isPresented: Bool
    
    /// Whether daily challenge mode is selected (vs random).
    @State private var isDailyMode: Bool
    
    /// The current theme for styling.
    @Environment(\.theme) var theme
    
    init(game: SudokuGame, isPresented: Binding<Bool>) {
        self.game = game
        self._isPresented = isPresented
        // Default to Daily mode unless all three daily challenges have been completed
        self._isDailyMode = State(initialValue: !game.settings.areAllDailyChallengesCompleted())
    }
    
    var body: some View {
        VStack(spacing: 16) {
            // Title
            Text("New Game")
                .font(.title2.weight(.bold))
                .foregroundColor(theme.primaryText)
            
            // Game mode selector (Daily/Random)
            ZStack(alignment: .leading) {
                // Background capsule
                Capsule()
                    .fill(theme.cellBackgroundColor)
                    .frame(width: 240, height: 52)
                
                // Sliding background capsule
                Capsule()
                    .fill(isDailyMode ? theme.primaryAccent : theme.secondaryAccent)
                    .frame(width: 116, height: 44)
                    .offset(x: isDailyMode ? 4 : 120)
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isDailyMode)
                
                // Button group
                HStack(spacing: 0) {
                    // Daily button
                    Button(action: { 
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            isDailyMode = true
                        }
                    }) {
                        Text("Daily")
                            .font(.body.weight(.bold))
                            .foregroundColor(isDailyMode ? .white : theme.primaryText)
                            .frame(width: 120, height: 52)
                    }
                    .buttonStyle(.plain)

                    // Random button
                    Button(action: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            isDailyMode = false
                        }
                    }) {
                        Text("Random")
                            .font(.body.weight(.bold))
                            .foregroundColor(!isDailyMode ? .white : theme.primaryText)
                            .frame(width: 120, height: 52)
                    }
                    .buttonStyle(.plain)
                }
            }
            
            // Info text
            Text(isDailyMode ? "Play today's daily challenges" : "Each puzzle has a unique solution")
                .font(.caption)
                .foregroundColor(theme.secondaryText)
                .multilineTextAlignment(.center)
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isDailyMode)
            
            // Show info message if there's an in-progress game
            if game.hasInProgressGame && !isDailyMode {
                Text("Starting a new game saves the current one in Game History")
                    .font(.caption)
                    .foregroundColor(theme.primaryAccent)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
            }
            
            // Difficulty buttons
            VStack(spacing: 12) {
                ForEach(Difficulty.allCases, id: \.self) { difficulty in
                    DifficultyButton(
                        difficulty: difficulty,
                        isDailyMode: isDailyMode,
                        isCompleted: game.isDailyChallengeCompleted(for: difficulty),
                        theme: theme,
                        action: {
                            startNewGame(difficulty: difficulty)
                        },
                        game: game
                    )
                }
            }
            
            // Cancel button (only show if there's an active game)
            if game.hasInProgressGame || game.hasBoardBeenGenerated {
                Button(action: {
                    game.startTimer()
                    isPresented = false
                }) {
                    Text("Cancel")
                        .font(.body.weight(.medium))
                        .foregroundColor(theme.secondaryText)
                        .padding(.vertical, 12)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(EdgeInsets(top: 16, leading: 32, bottom: 16, trailing: 32))
        .frame(width: 320)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(theme.backgroundColor)
                .shadow(color: .black.opacity(0.3), radius: 20, x: 0, y: 10)
        )
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: game.hasInProgressGame && !isDailyMode)
    }
    
    /// Starts a new game with the specified difficulty.
    private func startNewGame(difficulty: Difficulty) {
        if isDailyMode {
            game.generateDailyChallenge(difficulty: difficulty)
        } else {
            game.generatePuzzle(difficulty: difficulty)
        }
        isPresented = false
    }
}

/// A button for selecting a difficulty level, with optional status indicator for daily challenges.
struct DifficultyButton: View {
    let difficulty: Difficulty
    let isDailyMode: Bool
    let isCompleted: Bool
    let theme: Theme
    let action: () -> Void
    
    @Environment(\.modelContext) private var modelContext
    @ObservedObject var game: SudokuGame
    
    /// Fetches today's daily challenge for this difficulty
    private var todaysDailyChallenge: Game? {
        guard isDailyMode else { return nil }
        
        let dateString = DailyChallenge.getDateString(for: Date())
        let persistenceService = PersistenceService(modelContext: modelContext)
        return persistenceService.fetchDailyChallenge(difficulty: difficulty.rawValue, dateString: dateString)
    }
    
    /// Checks if this daily challenge is the currently active game
    private var isCurrentlyPlaying: Bool {
        guard let dailyGame = todaysDailyChallenge,
              let currentGameID = game.currentGameID else {
            return false
        }
        return dailyGame.gameID == currentGameID
    }
    
    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(difficulty.name)
                        .font(.body.weight(.semibold))
                        .foregroundColor(theme.primaryText)
                    Text("\(difficulty.numberOfClues) clues")
                        .font(.caption)
                        .foregroundColor(theme.secondaryText)
                }
                
                Spacer()
                
                // Show status chip for daily challenges
                if isDailyMode {
                    if let dailyGame = todaysDailyChallenge {
                        if dailyGame.isCompleted {
                            // Completed chip
                            Text("Completed")
                                .font(.caption.weight(.semibold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(
                                    RoundedRectangle(cornerRadius: 6)
                                        .fill(theme.color(for: difficulty))
                                )
                        } else if isCurrentlyPlaying {
                            // Keep Playing chip (for the current game)
                            Text("Keep Playing")
                                .font(.caption.weight(.semibold))
                                .foregroundColor(theme.color(for: difficulty))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(
                                    RoundedRectangle(cornerRadius: 6)
                                        .fill(theme.color(for: difficulty).opacity(0.15))
                                )
                        } else {
                            // In Progress chip (for a saved but not currently active game)
                            Text("In Progress")
                                .font(.caption.weight(.semibold))
                                .foregroundColor(theme.color(for: difficulty))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(
                                    RoundedRectangle(cornerRadius: 6)
                                        .fill(theme.color(for: difficulty).opacity(0.15))
                                )
                        }
                    } else {
                        // Start Playing chip
                        Text("Start Playing")
                            .font(.caption.weight(.semibold))
                            .foregroundColor(theme.color(for: difficulty))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(theme.color(for: difficulty).opacity(0.15))
                            )
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(theme.color(for: difficulty).opacity(0.3))
            )
        }
        .buttonStyle(.plain)
    }
}

/// A view modifier that presents a confirmation dialog for selecting puzzle difficulty.
struct NewGamePicker: ViewModifier {
    /// The game instance managing puzzle state and logic.
    let game: SudokuGame
    
    /// Binding to control the presentation of the difficulty picker.
    @Binding var isPresented: Bool
    
    /// The theme to use for styling.
    let theme: Theme
    
    func body(content: Content) -> some View {
        content
            .overlay {
                if isPresented {
                    ZStack {
                        // Dimmed background
                        Color.black.opacity(0.4)
                            .ignoresSafeArea()
                            .onTapGesture {
                                // Resume timer if dismissing with an active game
                                if game.hasInProgressGame || game.hasBoardBeenGenerated {
                                    game.startTimer()
                                }
                                isPresented = false
                            }
                        
                        // Alert content
                        NewGameView(game: game, isPresented: $isPresented)
                            .environment(\.theme, theme)
                            .transition(.scale.combined(with: .opacity))
                    }
                    .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isPresented)
                }
            }
    }
}

extension View {
    /// Presents a confirmation dialog for selecting puzzle difficulty.
    ///
    /// - Parameters:
    ///   - isPresented: A binding to control the presentation of the dialog.
    ///   - game: The game instance to use for generating puzzles.
    ///   - theme: The theme to use for styling.
    /// - Returns: A view with the difficulty picker modifier applied.
    func newGamePicker(isPresented: Binding<Bool>, game: SudokuGame, theme: Theme) -> some View {
        modifier(NewGamePicker(game: game, isPresented: isPresented, theme: theme))
    }
}
