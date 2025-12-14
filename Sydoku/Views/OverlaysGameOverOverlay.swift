import SwiftUI

/// An overlay displayed when the game ends due to too many mistakes.
///
/// Shows a game over message with the mistake count and a button
/// to start a new game.
struct GameOverOverlay: View {
    /// The Sudoku game instance.
    @ObservedObject var game: SudokuGame
    
    /// Binding to control the difficulty picker display.
    @Binding var showingDifficultyPicker: Bool
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.85)
                .edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 25) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 70))
                    .foregroundColor(.red)
                
                Text("Game Over")
                    .font(.system(size: 36, weight: .bold))
                    .foregroundColor(.white)
                
                Text("Too many mistakes!")
                    .font(.system(size: 20))
                    .foregroundColor(.white.opacity(0.8))
                
                Text(game.mistakesText)
                    .font(.system(size: 18, weight: .medium, design: .monospaced))
                    .foregroundColor(.red.opacity(0.9))
                
                Button(action: {
                    showingDifficultyPicker = true
                }) {
                    HStack {
                        Image(systemName: "arrow.clockwise")
                        Text("Try Again")
                    }
                    .font(.system(size: 22, weight: .semibold))
                    .padding(.horizontal, 35)
                    .padding(.vertical, 14)
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
            }
        }
    }
}
