import SwiftUI

/// The status section displaying game status messages.
///
/// Shows puzzle generation progress, completion messages, and error states.
struct StatusView: View {
    /// The game instance to observe for status changes.
    @ObservedObject var game: SudokuGame
    
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    
    /// The current theme for styling.
    var theme: Theme
    
    var body: some View {
        VStack {
            if game.isGenerating {
                HStack {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                        .tint(theme.primaryAccent)
                    Text("Generating puzzle...")
                        .font(.headline)
                        .foregroundColor(theme.primaryText)
                }
                .padding(.top, horizontalSizeClass == .compact ? 8 : -26)
                .padding(.bottom, horizontalSizeClass == .compact ? -8 : 0)
                .transition(.scale.combined(with: .opacity))
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
                .padding(.top, horizontalSizeClass == .compact ? 8 : -52)
                .transition(.scale.combined(with: .opacity))
            } else if game.hasError {
                Text("⚠️ There are errors in your solution ⚠️")
                    .font(.headline)
                    .foregroundColor(theme.errorColor)
                    .padding(.top, horizontalSizeClass == .compact ? 8 : -26)
                    .padding(.bottom, horizontalSizeClass == .compact ? -8 : 0)
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .padding(.horizontal)
    }
}
