import SwiftUI

/// A view that displays the 9x9 Sudoku game board.
///
/// `SudokuBoard` renders the complete grid of cells with proper borders
/// to delineate the 3x3 boxes. Each cell displays its value, notes,
/// and visual states (selected, highlighted, conflicts, etc.).
struct SudokuBoard: View {
    /// The Sudoku game instance managing the board state.
    @ObservedObject var game: SudokuGame
    
    var body: some View {
        VStack(spacing: 0) {
            ForEach(0..<9, id: \.self) { row in
                HStack(spacing: 0) {
                    ForEach(0..<9, id: \.self) { col in
                        SudokuCell(
                            value: game.board[row][col],
                            cellNotes: game.notes[row][col],
                            isInitial: game.initialBoard[row][col] != 0,
                            isSelected: game.selectedCell?.row == row && game.selectedCell?.col == col,
                            hasConflict: game.getConflicts(row: row, col: col),
                            isHighlighted: game.settings.highlightSameNumbers && game.highlightedNumber != nil && game.board[row][col] == game.highlightedNumber,
                            isLastPlaced: game.lastPlacedCell?.row == row && game.lastPlacedCell?.col == col,
                            isHintCell: game.hintCell?.row == row && game.hintCell?.col == col,
                            action: {
                                game.selectedCell = (row, col)
                            }
                        )
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
