import SwiftUI

/// Control buttons positioned above the number pad.
///
/// Shows mistakes counter (left), Pen/Notes mode toggle (center), and Undo/Redo buttons
/// for easy access while using the number pad. Center buttons remain centered regardless of mistakes display.
struct NumberPadHeader: View {
    /// The game instance to observe and control.
    @ObservedObject var game: SudokuGame
    
    /// The current theme for styling.
    var theme: Theme
    
    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                // Centered buttons (always centered)
                HStack(spacing: 8) {
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
                    .disabled(!game.canUndo || game.isGenerating || game.isPaused || game.isGameOver)
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
                            }) {
                                Text("Pen")
                                    .font(.body.weight(.bold))
                                    .foregroundColor(!game.isPencilMode ? .white : theme.secondaryText)
                                    .frame(width: 88, height: 52)
                            }
                            .buttonStyle(.plain)
                            .disabled(game.isPaused || game.isGameOver)
                            
                            // Notes button (pencil mode)
                            Button(action: { 
                                game.isPencilMode = true
                            }) {
                                Text("Notes")
                                    .font(.body.weight(.bold))
                                    .foregroundColor(game.isPencilMode ? .white : theme.secondaryText)
                                    .frame(width: 88, height: 52)
                            }
                            .buttonStyle(.plain)
                            .disabled(game.isPaused || game.isGameOver)
                        }
                    }
                    
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
                    .disabled(!game.canRedo || game.isGenerating || game.isPaused || game.isGameOver)
                    .buttonStyle(ScaleButtonStyle())
                }
                
                // Mistakes counter overlaid on the left (iPad only)
                if UIDevice.current.userInterfaceIdiom == .pad && game.settings.autoErrorChecking && (game.settings.mistakeLimit > 0 || game.mistakes > 0) {
                    HStack {
                        Text(game.mistakesText)
                            .font(.body.weight(.semibold))
                            .foregroundColor(game.mistakes >= game.settings.mistakeLimit && game.settings.mistakeLimit > 0 ? theme.errorColor : theme.warningColor)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(theme.warningColor.opacity(0.2))
                            )
                        
                        Spacer()
                    }
                }
            }
            
            // Mistakes counter below controls (iPhone only)
            if UIDevice.current.userInterfaceIdiom != .pad && game.settings.autoErrorChecking && (game.settings.mistakeLimit > 0 || game.mistakes > 0) {
                Text(game.mistakesText)
                    .font(.body.weight(.semibold))
                    .foregroundColor(game.mistakes >= game.settings.mistakeLimit && game.settings.mistakeLimit > 0 ? theme.errorColor : theme.warningColor)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(theme.warningColor.opacity(0.2))
                    )
            }
        }
        .padding(.horizontal)
    }
}
