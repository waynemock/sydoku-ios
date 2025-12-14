import SwiftUI

/// A number input pad for entering values into the Sudoku grid.
///
/// The number pad displays buttons 1-9 with usage counts, plus a delete button
/// to clear cells. Numbers that have been used 9 times are disabled.
struct NumberPad: View {
    /// The Sudoku game instance that manages the puzzle state.
    @ObservedObject var game: SudokuGame
    
    var body: some View {
        VStack(spacing: 12) {
            // First row: numbers 1-5
            HStack(spacing: 12) {
                ForEach(1...5, id: \.self) { num in
                    NumberButton(
                        number: num,
                        count: game.getNumberCount(num),
                        isHighlighted: game.highlightedNumber == num,
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
                    Image(systemName: "delete.left")
                        .font(.system(size: 28))
                        .frame(maxWidth: .infinity)
                        .frame(height: 60)
                        .background(Color.red)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
            }
        }
        .padding()
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
    
    /// The action to perform when the button is tapped.
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 2) {
                Text("\(number)")
                    .font(.system(size: 28, weight: .semibold))
                if count > 0 {
                    // Show usage count
                    Text("\(count)/9")
                        .font(.system(size: 10))
                        .opacity(0.7)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 60)
            .background(count == 9 ? Color.gray : (isHighlighted ? Color.blue.opacity(0.8) : Color.blue))
            .foregroundColor(.white)
            .cornerRadius(10)
        }
        .disabled(count == 9) // Disable when all instances are used
    }
}
