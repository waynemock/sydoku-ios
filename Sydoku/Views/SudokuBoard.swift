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
    
    /// The current theme for styling.
    @Environment(\.theme) var theme
    
    /// The current color scheme.
    @Environment(\.colorScheme) var colorScheme

    var isDarkMode: Bool {
        colorScheme == .dark || theme.colorScheme == .dark
    }

    var body: some View {
        GeometryReader { geometry in
            let boardSize = min(geometry.size.width, geometry.size.height)
            let cellSize = boardSize / 9
            
            ZStack {
                // Glow background layer (dark mode only)
                if isDarkMode {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(theme.cellBackgroundColor)
                        .frame(width: boardSize, height: boardSize)
                        .shadow(color: theme.primaryAccent.opacity(0.4), radius: 12, x: 0, y: 0)
                        .shadow(color: theme.primaryAccent.opacity(0.2), radius: 24, x: 0, y: 0)
                        .shadow(color: theme.primaryAccent.opacity(0.1), radius: 40, x: 0, y: 0)
                }

                // Solid background to block glow bleed-through
                RoundedRectangle(cornerRadius: 8)
                    .fill(theme.cellBackgroundColor)
                    .frame(width: boardSize, height: boardSize)

                // The actual board
                boardGrid(cellSize: cellSize)
                    .frame(width: boardSize, height: boardSize)
                    .opacity(game.isGenerating ? 0.5 : 1.0)
                    .overlay {
                        RoundedRectangle(cornerRadius: 1)
                            .stroke(.black, lineWidth: 6)
                            .cornerRadius(3)
                            .offset()
                            .frame(width: boardSize + 9, height: boardSize + 9)
                    }
                    .overlay {
                        RoundedRectangle(cornerRadius: 1)
                            .stroke(theme.primaryAccent.opacity(isDarkMode ? 1 : 1), lineWidth: 2)
                            .offset(x: 0, y: 0)
                            .frame(width: boardSize + 3, height: boardSize + 3)
                    }

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
                        let isTopLeft = row == 0 && col == 0
                        let isTopRight = row == 0 && col == SudokuGame.size - 1
                        let isBottomLeft = row == SudokuGame.size - 1 && col == 0
                        let isBottomRight = row == SudokuGame.size - 1 && col == SudokuGame.size - 1
                        
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
                        .clipShape(
                            .rect(
                                topLeadingRadius: isTopLeft ? 0 : 0,
                                bottomLeadingRadius: isBottomLeft ? 8 : 0,
                                bottomTrailingRadius: isBottomRight ? 8 : 0,
                                topTrailingRadius: isTopRight ? 8 : 0
                            )
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

#Preview("Active Game - Blossom Theme - Dark") {
    @Previewable @State var showingNewGamePicker = false
    let game = SudokuGame()
    
    SudokuBoard(game: game, showingNewGamePicker: $showingNewGamePicker)
        .environment(\.theme, Theme(type: .blossom, colorScheme: .dark))
        .preferredColorScheme(.dark)
        .onAppear {
            // Start a new easy game for preview
            game.generatePuzzle(difficulty: .easy)
            // Select a cell to show selection state
            game.selectedCell = (4, 4)
            game.highlightedNumber = game.board[4][4]
        }
}

#Preview("Active Game - Blossom Theme - Light") {
    @Previewable @State var showingNewGamePicker = false
    let game = SudokuGame()

    SudokuBoard(game: game, showingNewGamePicker: $showingNewGamePicker)
        .environment(\.theme, Theme(type: .blossom, colorScheme: .light))
        .preferredColorScheme(.dark)
        .onAppear {
            // Start a new easy game for preview
            game.generatePuzzle(difficulty: .easy)
            // Select a cell to show selection state
            game.selectedCell = (4, 4)
            game.highlightedNumber = game.board[4][4]
        }
}
