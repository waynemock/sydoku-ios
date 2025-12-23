import SwiftUI

/// A view that displays the 9x9 Sudoku game board.
///
/// `SudokuBoard` renders the complete grid of cells with proper borders
/// to delineate the 3x3 boxes. Each cell displays its value, notes,
/// and visual states (selected, highlighted, conflicts, etc.).
/// It also handles geometry calculations and overlays (pause, game over).
struct SudokuBoard: View {
    /// The Sudoku game instance managing the board state.
    @ObservedObject var game: SudokuGame
    
    /// Binding to control the new game picker sheet.
    @Binding var showingNewGamePicker: Bool
    
    var body: some View {
        GeometryReader { geometry in
            let boardSize = min(geometry.size.width, geometry.size.height)
            let cellSize = boardSize / 9
            
            ZStack {
                // The actual board
                boardGrid(cellSize: cellSize)
                    .frame(width: boardSize, height: boardSize)
                    .opacity(game.isGenerating ? 0.5 : 1.0)
                
                // Overlays in separate layer to avoid clipping
                if game.isPaused {
                    PauseOverlay(game: game)
                        .frame(width: boardSize, height: boardSize)
                        .clipped()
                }
                if game.isMistakeLimitReached {
                    GameOverOverlay(game: game, showingNewGamePicker: $showingNewGamePicker)
                        .frame(width: boardSize, height: boardSize)
                        .clipped()
                }
            }
            .frame(width: boardSize, height: boardSize)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .padding()
        .aspectRatio(1, contentMode: .fit)
    }
    
    /// The 9x9 grid of cells.
    @ViewBuilder
    private func boardGrid(cellSize: CGFloat) -> some View {
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
                                // Save UI state changes
                                game.saveUIState()
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
