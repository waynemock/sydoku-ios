import SwiftUI

/// The header section containing app title, timer, and action buttons.
///
/// Displays the app name, daily challenge indicator, timer with pause button (always centered),
/// and action menus for creating new games and accessing tools/settings.
struct HeaderView: View {
    /// The game instance managing puzzle state and logic.
    @ObservedObject var game: SudokuGame
    
    /// The current theme for styling.
    var theme: Theme
    
    /// Binding to show/hide the new game picker.
    @Binding var showingNewGamePicker: Bool
    
    /// Binding to show/hide the continue alert.
    @Binding var showingContinueAlert: Bool
    
    /// Binding to show/hide the statistics sheet.
    @Binding var showingStats: Bool
    
    /// Binding to show/hide the settings sheet.
    @Binding var showingSettings: Bool
    
    /// Binding to show/hide the about sheet.
    @Binding var showingAbout: Bool
    
    /// Binding to show/hide the error checking toast.
    @Binding var showingErrorCheckingToast: Bool
    
    var body: some View {
        ZStack {
            // Centered timer (always centered regardless of sides)
            TimerButtonView(game: game, theme: theme)
            
            // Left and right content
            HStack {
                // Left side: Title and puzzle info
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text("Sydoku")
                            .foregroundColor(theme.primaryText)
                            .font(.largeTitle)
                            .fontWeight(.bold)
                    }
                    
                    // Puzzle type and difficulty
                    if !game.isGenerating && (game.hasSavedGame || !game.initialBoard.allSatisfy({ $0.allSatisfy({ $0 == 0 }) })) {
                        Text(game.isDailyChallenge ? "Daily Challenge • \(game.difficulty.name)" : game.difficulty.name)
                            .font(.subheadline)
                            .foregroundColor(theme.secondaryText)
                    }
                }
                
                Spacer()
                
                // Right side: Action buttons
                HStack(spacing: 8) {
                    // New game button
                    Button(action: {
                        // Check if we're at launch with a saved game
                        let isAtLaunch = game.initialBoard.allSatisfy({ $0.allSatisfy({ $0 == 0 }) })
                        
                        game.stopTimer()
                        
                        if isAtLaunch && game.hasSavedGame {
                            // At launch - show continue alert
                            showingContinueAlert = true
                        } else {
                            // Mid-game or no saved game - go directly to new game picker
                            showingNewGamePicker = true
                        }
                    }) {
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
                    .buttonStyle(.plain)
                    
                    // Tools menu button
                    Menu {
                        Button(action: { game.giveHint() }) {
                            Label("Show Hint", systemImage: "lightbulb")
                        }
                        .disabled(game.isGenerating || game.isComplete || game.isPaused || game.isGameOver)
                        
                        Button(action: { game.autoFillNotes() }) {
                            Label("Auto Notes", systemImage: "wand.and.stars")
                        }
                        .disabled(game.isGenerating || game.isPaused || game.isGameOver)
                        
                        Button(action: { game.clearAllNotes() }) {
                            Label("Clear Notes", systemImage: "trash")
                        }
                        .disabled(game.isGenerating || game.isPaused || game.isGameOver)

                        Divider()
                        
                        Button(action: {
                            game.settings.autoErrorChecking.toggle()
                            game.saveSettings()
                            
                            // Show toast feedback
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                showingErrorCheckingToast = true
                            }
                        }) {
                            Label("Auto Error Checking", systemImage: game.settings.autoErrorChecking ? "checkmark.circle.fill" : "circle")
                        }
                        
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
                            .font(.system(size: 32))
                            .foregroundColor(theme.primaryAccent)
                            .frame(width: 44, height: 44)
                    }
                    .menuStyle(.button)
                    .fixedSize()
                    .transaction { transaction in
                        transaction.animation = nil
                    }
                }
            }
        }
        .padding(.horizontal)
        .padding(.top)
    }
}
