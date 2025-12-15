import SwiftUI

/// An overlay displayed when the game ends due to too many mistakes.
///
/// Shows a game over message with the mistake count and a button
/// to start a new game. Uses Liquid Glass design for modern appearance.
struct GameOverOverlay: View {
    /// The Sudoku game instance.
    @ObservedObject var game: SudokuGame
    
    /// Binding to control the difficulty picker display.
    @Binding var showingDifficultyPicker: Bool
    
    /// Environment theme.
    @Environment(\.theme) var theme
    
    /// Animation state for the overlay appearance.
    @State private var isAnimating = false
    
    /// Animation state for the error icon.
    @State private var iconScale: CGFloat = 0.5
    
    var body: some View {
        ZStack {
            // Blurred background
            Color.black.opacity(0.8)
                .ignoresSafeArea()
            
            // Glass card container
            VStack(spacing: 25) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 70))
                    .foregroundStyle(
                        .linearGradient(
                            colors: [theme.errorColor, theme.errorColor.opacity(0.7)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .shadow(color: theme.errorColor.opacity(0.5), radius: 20)
                    .scaleEffect(iconScale)
                    .rotationEffect(.degrees(isAnimating ? 0 : -180))
                
                Text("Game Over")
                    .font(.largeTitle.weight(.bold))
                    .foregroundColor(theme.primaryText)
                
                Text("Too many mistakes!")
                    .font(.title3)
                    .foregroundColor(theme.secondaryText)
                
                Text(game.mistakesText)
                    .font(.system(.body, design: .monospaced, weight: .medium))
                    .foregroundColor(theme.errorColor)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(theme.errorColor.opacity(0.2))
                    )
                
                Button(action: {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                        showingDifficultyPicker = true
                    }
                }) {
                    HStack(spacing: 12) {
                        Image(systemName: "arrow.clockwise")
                        Text("Try Again")
                    }
                    .font(.title3.weight(.semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 35)
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
            .padding(40)
            .background(
                RoundedRectangle(cornerRadius: 30)
                    .fill(.ultraThinMaterial)
                    .shadow(color: Color.black.opacity(0.3), radius: 30, y: 10)
            )
            .scaleEffect(isAnimating ? 1.0 : 0.8)
            .opacity(isAnimating ? 1.0 : 0.0)
        }
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                isAnimating = true
                iconScale = 1.0
            }
        }
    }
}
