import SwiftUI

/// Input mode controls (Pen/Notes) with Undo/Redo buttons.
///
/// Shows the Pen/Notes mode toggle (center) and Undo/Redo buttons
/// for easy access while using the number pad.
struct InputControls: View {
    /// The game instance to observe and control.
    @ObservedObject var game: SudokuGame
    
    /// The current theme for styling.
    var theme: Theme

    var isDisabled: Bool {
        game.isGenerating || game.isPaused || game.isMistakeLimitReached || game.isComplete
    }

    var body: some View {
        HStack(spacing: 8) {
            Spacer()
            
            // Undo button
            Button(action: { game.undo() }) {
                Image(systemName: "arrow.uturn.backward")
                    .font(.title3.weight(.semibold))
                    .foregroundColor(game.canUndo ? .white : .white.opacity(0.5))
                    .frame(width: 44, height: 44)
                    .background(
                        Circle()
                            .fill(game.canUndo ? theme.primaryAccent : theme.secondaryText.opacity(0.25))
                    )
            }
            .disabled(!game.canUndo || isDisabled)
            .buttonStyle(ScaleButtonStyle())
            
            // Center: Input mode controls (Pen/Notes)
            ZStack(alignment: .leading) {
                // Background capsule
                Capsule()
                    .fill(theme.cellBackgroundColor)
                    .frame(width: 176, height: 52)
                
                // Sliding background capsule
                Capsule()
                    .fill(game.isPencilMode ? theme.secondaryAccent : theme.primaryAccent)
                    .frame(width: 84, height: 44)
                    .offset(x: game.isPencilMode ? 88 : 4)
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: game.isPencilMode)
                
                // Button group
                HStack(spacing: 0) {
                    // Pen button (regular mode)
                    Button(action: { 
                        game.isPencilMode = false
                        game.saveUIState()
                    }) {
                        Text("Pen")
                            .font(.appBody)
                            .fontWeight(.bold)
                            .foregroundColor(!game.isPencilMode ? .white : theme.secondaryText)
                            .frame(width: 88, height: 52)
                    }
                    .buttonStyle(.plain)
                    .disabled(isDisabled)

                    // Notes button (pencil mode)
                    Button(action: { 
                        game.isPencilMode = true
                        game.saveUIState()
                    }) {
                        Text("Notes")
                            .font(.appBody)
                            .fontWeight(.bold)
                            .foregroundColor(game.isPencilMode ? .white : theme.secondaryText)
                            .frame(width: 88, height: 52)
                    }
                    .buttonStyle(.plain)
                    .disabled(isDisabled)
                }
            }
            .overlay(
                Capsule()
                    .stroke(theme.primaryAccent, lineWidth: 2)
                    .frame(width: 176, height: 52)
            )
            
            // Redo button
            Button(action: { game.redo() }) {
                Image(systemName: "arrow.uturn.forward")
                    .font(.title3.weight(.semibold))
                    .foregroundColor(game.canRedo ? .white : .white.opacity(0.5))
                    .frame(width: 44, height: 44)
                    .background(
                        Circle()
                            .fill(game.canRedo ? theme.primaryAccent : theme.secondaryText.opacity(0.25))
                    )
            }
            .disabled(!game.canRedo || isDisabled)
            .buttonStyle(ScaleButtonStyle())
            
            Spacer()
        }
        .padding(.horizontal)
    }
}
