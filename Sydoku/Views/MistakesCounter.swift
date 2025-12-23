import SwiftUI

/// Displays the mistakes counter with visual feedback.
struct MistakesCounter: View {
    /// The game instance to observe.
    @ObservedObject var game: SudokuGame
    
    /// The current theme for styling.
    var theme: Theme
    
    /// Whether to show the mistakes counter.
    private var showMistakes: Bool {
        game.settings.autoErrorChecking && (game.settings.mistakeLimit > 0 || game.mistakes > 0)
    }
    
    var body: some View {
        if showMistakes {
            Text(game.mistakesText)
                .font(.appBody)
                .fontWeight(.semibold)
                .foregroundColor(game.mistakes >= game.settings.mistakeLimit && game.settings.mistakeLimit > 0 ? theme.errorColor : theme.primaryAccent)
                .padding(.horizontal, 12)
                .frame(minHeight: 36)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(theme.primaryAccent.opacity(0.2))
                )
        }
    }
}
