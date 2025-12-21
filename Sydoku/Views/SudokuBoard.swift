import SwiftUI

/// A view that displays the 9x9 Sudoku game board.
///
/// `SudokuBoard` renders the complete grid of cells with proper borders
/// to delineate the 3x3 boxes. Each cell displays its value, notes,
/// and visual states (selected, highlighted, conflicts, etc.).
struct SudokuBoard: View {
    /// The Sudoku game instance managing the board state.
    @ObservedObject var game: SudokuGame
    
    /// The fixed size for each cell to prevent dynamic sizing issues.
    let cellSize: CGFloat
    
    var body: some View {
        VStack(spacing: 0) {
            ForEach(0..<SudokuGame.size, id: \.self) { row in
                HStack(spacing: 0) {
                    ForEach(0..<SudokuGame.size, id: \.self) { col in
                        SudokuCell(
                            value: game.board[row][col],
                            cellNotes: game.notes[row][col],
                            isInitial: game.initialBoard[row][col] != 0,
                            isSelected: game.selectedCell?.row == row && game.selectedCell?.col == col,
                            hasConflict: game.getConflicts(row: row, col: col),
                            isHighlighted: game.settings.highlightSameNumbers && game.highlightedNumber != nil && game.board[row][col] == game.highlightedNumber,
                            isLastPlaced: game.lastPlacedCell?.row == row && game.lastPlacedCell?.col == col,
                            isHintCell: game.hasHint(row: row, col: col),
                            cellSize: cellSize,
                            action: {
                                game.selectedCell = (row, col)
                                // Highlight the number if the cell has one
                                let cellValue = game.board[row][col]
                                if cellValue != 0 {
                                    game.highlightedNumber = cellValue
                                } else {
                                    game.highlightedNumber = nil
                                }
                            }
                        )
                        .frame(width: cellSize, height: cellSize)
                        .clipped()
                        .border(
                            width: BorderWidths(
                                leading: col % 3 == 0 ? 2 : 0.5,
                                top: row % 3 == 0 ? 2 : 0.5,
                                trailing: (col + 1) % 3 == 0 ? 2 : 0.5,
                                bottom: (row + 1) % 3 == 0 ? 2 : 0.5
                            ),
                            color: .black
                        )
                    }
                }
            }
        }
    }
}
