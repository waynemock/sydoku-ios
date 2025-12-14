import SwiftUI

/// A view representing a single cell in the Sudoku grid.
///
/// `SudokuCell` displays the cell's value, notes (pencil marks), and various visual states
/// including selection, conflicts, highlights, and hints.
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
    
    var body: some View {
        Button(action: action) {
            ZStack {
                // Background color based on cell state
                Rectangle()
                    .fill(isSelected ? Color.blue.opacity(0.5) :
                          isHintCell ? Color.green.opacity(0.4) :
                          isHighlighted ? Color.yellow.opacity(0.3) :
                          Color(red: 0.25, green: 0.25, blue: 0.27))
                
                if value != 0 {
                    // Display the cell's value
                    Text("\(value)")
                        .font(.system(size: 24, weight: isInitial ? .bold : .regular))
                        .foregroundColor(hasConflict ? .red : (isInitial ? .white : Color.cyan))
                        .scaleEffect(isLastPlaced ? 1.3 : 1.0)
                        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isLastPlaced)
                } else if !cellNotes.isEmpty {
                    // Display pencil mark notes
                    NotesGrid(notes: cellNotes)
                }
            }
        }
        .aspectRatio(1, contentMode: .fit)
    }
}

/// A view displaying pencil mark notes in a 3x3 grid within a cell.
///
/// Shows which numbers (1-9) are marked as possible candidates for the cell.
struct NotesGrid: View {
    /// The set of numbers to display as notes.
    let notes: Set<Int>
    
    var body: some View {
        VStack(spacing: 1) {
            ForEach(0..<3, id: \.self) { row in
                HStack(spacing: 1) {
                    ForEach(1...3, id: \.self) { col in
                        let num = row * 3 + col
                        Text(notes.contains(num) ? "\(num)" : "")
                            .font(.system(size: 9))
                            .foregroundColor(.white.opacity(0.6))
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                }
            }
        }
        .padding(2)
    }
}
