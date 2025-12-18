import SwiftUI

/// Displays the mistakes counter with visual feedback.
struct MistakesCounter: View {
    /// The game instance to observe.
    @ObservedObject var game: SudokuGame
    
    /// The current theme for styling.
    var theme: Theme
    
    var body: some View {
        Text(game.mistakesText)
            .font(.body.weight(.semibold))
            .foregroundColor(game.mistakes >= game.settings.mistakeLimit && game.settings.mistakeLimit > 0 ? theme.errorColor : theme.primaryAccent)
            .padding(.horizontal, 12)
            .frame(height: 44)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(theme.primaryAccent.opacity(0.2))
            )
    }
}
