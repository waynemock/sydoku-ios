import SwiftUI

struct ContentView: View {
    @StateObject private var game = SudokuGame()
    @State private var showingDifficultyPicker = false
    @State private var showingStats = false
    @State private var showingSettings = false
    @State private var showingContinueAlert = false
    
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
                
                // Number Pad
                NumberPad(game: game)
                    .disabled(game.isGenerating || game.isPaused || game.isGameOver)
                
                Spacer()
            }
            .background(Color(red: 0.15, green: 0.15, blue: 0.17))
            
            // Confetti overlay
            if game.showConfetti {
                ConfettiView()
                    .allowsHitTesting(false)
            }
        }
        .sheet(isPresented: $showingStats) {
            StatisticsView(game: game)
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView(game: game)
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
            if game.hasSavedGame {
                showingContinueAlert = true
            } else {
                game.generatePuzzle(difficulty: .medium)
            }
        }
    }
    
    // MARK: - Header View 
    private var headerView: some View {
        HStack {
            Text("Sydoku")
                .foregroundColor(Color.white)
                .font(.largeTitle)
                .fontWeight(.bold)
            
            if game.isDailyChallenge {
                Image(systemName: "calendar")
                    .foregroundColor(Color.white)
                    .font(.title2)
                    .foregroundColor(.orange)
            }
            
            Spacer()
            
            // Timer display with pause button
            Button(action: { game.togglePause() }) {
                HStack(spacing: 6) {
                    Image(systemName: game.isPaused ? "play.fill" : "pause.fill")
                        .foregroundColor(.blue)
                    Text(game.formattedTime)
                        .font(.system(size: 20, weight: .medium, design: .monospaced))
                        .foregroundColor(.blue)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.blue.opacity(0.1))
                .cornerRadius(8)
            }
            .disabled(game.isGenerating || game.isComplete || game.isGameOver)
            
            Button(action: { showingSettings = true }) {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 20))
                    .frame(width: 44, height: 44)
                    .background(Color.gray)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
            
            Button(action: { showingStats = true }) {
                Image(systemName: "chart.bar.fill")
                    .font(.system(size: 20))
                    .frame(width: 44, height: 44)
                    .background(Color.purple)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
            
            Button(action: { game.undo() }) {
                Image(systemName: "arrow.uturn.backward")
                    .font(.system(size: 20))
                    .frame(width: 44, height: 44)
                    .background(game.canUndo ? Color.blue : Color.gray)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
            .disabled(!game.canUndo || game.isGenerating || game.isPaused || game.isGameOver)
            
            Button(action: { game.redo() }) {
                Image(systemName: "arrow.uturn.forward")
                    .font(.system(size: 20))
                    .frame(width: 44, height: 44)
                    .background(game.canRedo ? Color.blue : Color.gray)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
            .disabled(!game.canRedo || game.isGenerating || game.isPaused || game.isGameOver)
        }
        .padding(.horizontal)
        .padding(.top)
    }
    
    // MARK: - Game Controls View
    private var gameControlsView: some View {
        HStack {
            Button(action: { game.isPencilMode.toggle() }) {
                HStack {
                    Image(systemName: game.isPencilMode ? "pencil.circle.fill" : "pencil.circle")
                    Text(game.isPencilMode ? "Notes On" : "Notes Off")
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(game.isPencilMode ? Color.purple : Color.gray)
                .foregroundColor(.white)
                .cornerRadius(8)
            }
            .disabled(game.isPaused || game.isGameOver)
            
            Button(action: { game.autoFillNotes() }) {
                HStack {
                    Image(systemName: "wand.and.stars")
                    Text("Auto Notes")
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.purple.opacity(0.8))
                .foregroundColor(.white)
                .cornerRadius(8)
            }
            .disabled(game.isGenerating || game.isPaused || game.isGameOver)
            
            Spacer()
            
            // Mistake counter
            if game.settings.mistakeLimit > 0 || game.mistakes > 0 {
                Text(game.mistakesText)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(game.mistakes >= game.settings.mistakeLimit && game.settings.mistakeLimit > 0 ? .red : .orange)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(8)
            }
            
            Menu {
                Button(action: {
                    game.giveHint()
                }) {
                    Label("Progressive Hint", systemImage: "lightbulb")
                }
                Button(action: {
                    game.resetHints()
                }) {
                    Label("Reset Hints", systemImage: "arrow.counterclockwise")
                }
            } label: {
                HStack {
                    Image(systemName: "lightbulb.fill")
                    Text("Hint")
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.orange)
                .foregroundColor(.white)
                .cornerRadius(8)
            }
            .disabled(game.isGenerating || game.isComplete || game.isPaused || game.isGameOver)
            
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
                Text(game.hasSavedGame ? "Continue/New" : "New Game")
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
            .disabled(game.isGenerating)
        }
        .padding(.horizontal)
        .padding(.bottom, 8)
    }
    
    // MARK: - Status View
    private var statusView: some View {
        Group {
            if let region = game.hintRegion {
                Text("💡 Try focusing on \(region)")
                    .font(.headline)
                    .foregroundColor(.orange)
                    .padding(.vertical, 8)
            } else if let number = game.hintNumber {
                Text("💡 Look for where \(number) can go")
                    .font(.headline)
                    .foregroundColor(.orange)
                    .padding(.vertical, 8)
            } else if game.hintCell != nil {
                Text("💡 The highlighted cell is a good next move")
                    .font(.headline)
                    .foregroundColor(.green)
                    .padding(.vertical, 8)
            } else if game.isGenerating {
                HStack {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                    Text("Generating puzzle...")
                        .font(.headline)
                }
                .padding()
            } else if game.isComplete {
                VStack(spacing: 4) {
                    if game.isDailyChallenge {
                        Text("🎉 Daily Challenge Complete! 🎉")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.orange)
                    } else {
                        Text("🎉 Congratulations! 🎉")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.green)
                    }
                    Text("Completed in \(game.formattedTime)")
                        .font(.headline)
                        .foregroundColor(.blue)
                }
                .padding()
                .transition(.scale.combined(with: .opacity))
            } else if game.hasError {
                Text("⚠️ There are errors in your solution")
                    .font(.headline)
                    .foregroundColor(.red)
                    .padding(.vertical, 8)
            }
        }
    }
}
