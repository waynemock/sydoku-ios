import SwiftUI

/// A view representing a single cell in the Sudoku grid.
///
/// `SudokuCell` displays the cell's value, notes (pencil marks), and various visual states
/// including selection, conflicts, highlights, and hints. Uses the app theme for consistent styling.
struct SudokuCell: View {
    /// The numeric value of the cell (1-9), or 0 if empty.
    let value: Int
    
    /// The set of pencil mark notes for this cell.
    let cellNotes: Set<Int>
    
    /// Whether this cell contains an initial puzzle value (not user-entered).
    let isInitial: Bool
    
    /// Whether this cell is currently selected by the user.
    let isSelected: Bool
    
    /// Whether this cell's value conflicts with Sudoku rules.
    let hasConflict: Bool
    
    /// Whether this cell should be highlighted (e.g., related to selected cell).
    let isHighlighted: Bool
    
    /// Whether this is the most recently placed value.
    let isLastPlaced: Bool
    
    /// Whether this cell is highlighted as part of a hint.
    let isHintCell: Bool
    
    /// The action to perform when the cell is tapped.
    let action: () -> Void
    
    /// Environment theme.
    @Environment(\.theme) var theme
    
    var body: some View {
        Button(action: action) {
            ZStack {
                // Background with gradient for depth
                RoundedRectangle(cornerRadius: 2)
                    .fill(backgroundColor)
                    .overlay(
                        RoundedRectangle(cornerRadius: 2)
                            .stroke(borderColor, lineWidth: isSelected ? 2 : 0)
                    )
                
                if value != 0 {
                    // Display the cell's value
                    Text("\(value)")
                        .font(.title2.weight(isInitial ? .bold : .semibold))
                        .foregroundStyle(textColor)
                        .scaleEffect(isLastPlaced ? 1.3 : 1.0)
                        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isLastPlaced)
                        .shadow(color: hasConflict ? theme.errorColor.opacity(0.3) : Color.clear, radius: 4)
                } else if !cellNotes.isEmpty {
                    // Display pencil mark notes
                    NotesGrid(notes: cellNotes, theme: theme)
                }
            }
        }
        .aspectRatio(1, contentMode: .fit)
        .buttonStyle(CellButtonStyle())
    }
    
    /// Determines the background color based on cell state.
    private var backgroundColor: Color {
        if isSelected {
            return theme.selectedCellColor
        } else if isHintCell {
            return theme.hintCellColor
        } else if isHighlighted {
            return theme.highlightedCellColor
        } else {
            return theme.cellBackgroundColor
        }
    }
    
    /// Determines the border color for selected cells.
    private var borderColor: Color {
        isSelected ? theme.primaryAccent : Color.clear
    }
    
    /// Determines the text color based on cell state.
    private var textColor: Color {
        if hasConflict {
            return theme.errorColor
        } else if isInitial {
            return theme.initialCellText
        } else {
            return theme.userCellText
        }
    }
}

/// A button style for cell buttons that adds subtle press feedback.
struct CellButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

/// A view displaying pencil mark notes in a 3x3 grid within a cell.
///
/// Shows which numbers (1-9) are marked as possible candidates for the cell.
struct NotesGrid: View {
    /// The set of numbers to display as notes.
    let notes: Set<Int>
    
    /// The theme for styling.
    let theme: Theme
    
    var body: some View {
        VStack(spacing: 1) {
            ForEach(0..<3, id: \.self) { row in
                HStack(spacing: 1) {
                    ForEach(1...3, id: \.self) { col in
                        let num = row * 3 + col
                        Text(notes.contains(num) ? "\(num)" : "")
                            .font(.caption2.weight(.medium))
                            .foregroundColor(theme.secondaryText)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                }
            }
        }
        .padding(2)
    }
}
