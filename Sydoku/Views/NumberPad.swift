import SwiftUI

/// A number input pad for entering values into the Sudoku grid.
///
/// The number pad displays buttons 1-9 with usage counts, plus a delete button
/// to clear cells. Numbers that have been used 9 times are disabled. Uses glass
/// styling for a modern appearance.
struct NumberPad: View {
    /// The Sudoku game instance that manages the puzzle state.
    @ObservedObject var game: SudokuGame
    
    /// Environment theme.
    @Environment(\.theme) var theme
    
    var body: some View {
        VStack(spacing: 12) {
            // First row: numbers 1-5
            HStack(spacing: 12) {
                ForEach(1...5, id: \.self) { num in
                    NumberButton(
                        number: num,
                        count: game.getNumberCount(num),
                        isHighlighted: game.highlightedNumber == num,
                        theme: theme,
                        action: {
                            game.setNumber(num)
                            game.highlightedNumber = num
                        }
                    )
                }
            }
            
            // Second row: numbers 6-9 and delete button
            HStack(spacing: 12) {
                ForEach(6...9, id: \.self) { num in
                    NumberButton(
                        number: num,
                        count: game.getNumberCount(num),
                        isHighlighted: game.highlightedNumber == num,
                        theme: theme,
                        action: {
                            game.setNumber(num)
                            game.highlightedNumber = num
                        }
                    )
                }
                
                // Delete button
                Button(action: {
                    game.clearCell()
                    game.highlightedNumber = nil
                }) {
                    Image(systemName: "delete.backward.fill")
                        .font(.title2.weight(.semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 60)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(
                                    LinearGradient(
                                        colors: [theme.primaryAccent.opacity(0.5), theme.primaryAccent.opacity(0.4)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                        )
                        .shadow(color: theme.primaryAccent.opacity(0.15), radius: 5, y: 3)
                }
                .buttonStyle(ScaleButtonStyle())
            }
        }
        .padding()
        .frame(maxWidth: 600)  // Limit to portrait-like width
    }
}

/// A button representing a single number (1-9) in the number pad.
///
/// Displays the number and its usage count, and becomes disabled when
/// all 9 instances of the number have been placed on the grid.
struct NumberButton: View {
    /// The number this button represents (1-9).
    let number: Int
    
    /// How many times this number has been placed on the grid.
    let count: Int
    
    /// Whether this number is currently highlighted in the grid.
    let isHighlighted: Bool
    
    /// The theme for styling.
    let theme: Theme
    
    /// The action to perform when the button is tapped.
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 2) {
                Text("\(number)")
                    .font(.appTitle2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                if count > 0 {
                    // Show usage count
                    Text("\(count)/9")
                        .font(.appCaption2)
                        .fontWeight(.medium)
                        .foregroundColor(.white.opacity(0.8))
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 60)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(buttonGradient)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isHighlighted ? Color.white.opacity(0.5) : Color.clear, lineWidth: 2)
                    )
            )
            .shadow(color: shadowColor, radius: 5, y: 3)
        }
        .disabled(count == 9)
        .buttonStyle(ScaleButtonStyle())
    }
    
    /// Determines the button gradient based on state.
    private var buttonGradient: LinearGradient {
        if count == 9 {
            return LinearGradient(
                colors: [Color.gray.opacity(0.6), Color.gray.opacity(0.4)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        } else if isHighlighted {
            return LinearGradient(
                colors: [theme.secondaryAccent, theme.secondaryAccent.opacity(0.8)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        } else {
            return LinearGradient(
                colors: [theme.primaryAccent, theme.primaryAccent.opacity(0.8)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
    
    /// Determines the shadow color based on state.
    private var shadowColor: Color {
        if count == 9 {
            return Color.clear
        } else if isHighlighted {
            return theme.secondaryAccent.opacity(0.4)
        } else {
            return theme.primaryAccent.opacity(0.3)
        }
    }
}
