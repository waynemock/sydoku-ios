import SwiftUI

/// An overlay displayed when the game is paused.
///
/// Shows a semi-transparent overlay with a pause icon, elapsed time,
/// and a button to resume the game. Uses Liquid Glass design for modern appearance.
struct PauseOverlay: View {
    /// The Sudoku game instance.
    @ObservedObject var game: SudokuGame
    
    /// Environment theme.
    @Environment(\.theme) var theme
    
    /// Animation state for the overlay appearance.
    @State private var isAnimating = false
    
    var body: some View {
        ZStack {
            // Blurred background
            Color.black.opacity(0.7)
                .blur(radius: isAnimating ? 0 : 20)
            
            // Glass card container
            VStack(spacing: 20) {
                Image(systemName: "pause.circle.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(
                        .linearGradient(
                            colors: [theme.primaryAccent, theme.secondaryAccent],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .shadow(color: theme.primaryAccent.opacity(0.5), radius: 20)
                
                Text("Game Paused")
                    .font(.title.weight(.bold))
                    .foregroundColor(theme.primaryText)
                
                Text(game.formattedTime)
                    .font(.system(.title3, design: .monospaced, weight: .medium))
                    .foregroundColor(theme.secondaryText)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(theme.primaryAccent.opacity(0.2))
                    )
                
                Button(action: {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                        game.resumeTimer()
                    }
                }) {
                    HStack(spacing: 10) {
                        Image(systemName: "play.fill")
                        Text("Resume")
                    }
                    .font(.title3.weight(.semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(
                                LinearGradient(
                                    colors: [theme.successColor, theme.successColor.opacity(0.8)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    )
                    .shadow(color: theme.successColor.opacity(0.4), radius: 10, y: 5)
                }
                .buttonStyle(ScaleButtonStyle())
            }
            .padding(32)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(.ultraThinMaterial)
                    .shadow(color: Color.black.opacity(0.3), radius: 30, y: 10)
            )
            .scaleEffect(isAnimating ? 1.0 : 0.8)
            .opacity(isAnimating ? 1.0 : 0.0)
        }
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                isAnimating = true
            }
        }
    }
}
/// A button style that scales down when pressed.
struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

