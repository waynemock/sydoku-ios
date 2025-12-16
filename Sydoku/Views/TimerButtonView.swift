import SwiftUI

/// A timer button component isolated to prevent menu flashing.
///
/// This view is separate to ensure that timer updates don't cause
/// the parent view hierarchy to redraw, which would cause open menus to flash.
struct TimerButtonView: View {
    @ObservedObject var game: SudokuGame
    let theme: Theme
    
    var body: some View {
        if game.elapsedTime > 0 {
            Button(action: { game.togglePause() }) {
                HStack(spacing: 6) {
                    Image(systemName: game.isPaused ? "play.fill" : "pause.fill")
                        .foregroundColor(theme.primaryAccent)
                    Text(game.formattedTime)
                        .font(.system(.body, design: .monospaced, weight: .medium))
                        .foregroundColor(theme.primaryAccent)
                }
                .padding(.horizontal, 12)
                .frame(height: 44)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(theme.primaryAccent.opacity(0.2))
                )
            }
            .disabled(game.isGenerating || game.isComplete || game.isGameOver)
            .buttonStyle(ScaleButtonStyle())
        }
    }
}
