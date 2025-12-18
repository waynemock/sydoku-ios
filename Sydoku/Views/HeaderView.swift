import SwiftUI

/// The header section containing app title, timer, and action buttons.
///
/// Displays the app name, daily challenge indicator, timer with pause button (always centered on iPad, below board on iPhone),
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
    
    /// Environment horizontal size class to detect iPhone vs iPad.
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    
    var body: some View {
        ZStack {
            // Centered timer (only on iPad)
            if horizontalSizeClass == .regular {
                TimerButtonView(game: game, theme: theme)
            }
            
            // Left and right content
            HStack {
                // Left side: Title and puzzle info
                VStack(alignment: .leading, spacing: 0) {
                    HStack(spacing: 8) {
                        Text("Sydoku")
                            .foregroundColor(theme.primaryText)
                            .font(.custom("Papyrus", size: 34))
                            .fontWeight(.bold)
                    }
                    
                    // Puzzle type and difficulty
                    if !game.isGenerating && (game.hasSavedGame || !game.initialBoard.allSatisfy({ $0.allSatisfy({ $0 == 0 }) })) {
                        Text(game.isDailyChallenge ? "Daily Challenge • \(game.difficulty.name)" : game.difficulty.name)
                            .font(.subheadline)
                            .foregroundColor(theme.secondaryText)
                            .offset(y: -4)
                    }
                }
                
                Spacer()
                
                // Right side: Action buttons
                HStack(spacing: 12) {
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
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 40))
                            .foregroundColor(theme.primaryAccent)
                            .frame(width: 44, height: 44)
                    }
                    .disabled(game.isGenerating)
                    .buttonStyle(.plain)
                    
                    // Tools menu button
                    MenuButtonView(
                        game: game,
                        theme: theme,
                        showingStats: $showingStats,
                        showingSettings: $showingSettings,
                        showingAbout: $showingAbout,
                        showingErrorCheckingToast: $showingErrorCheckingToast
                    )
                }
            }
        }
        .padding(.horizontal)
        .padding(.top)
    }
}
