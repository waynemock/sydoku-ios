import Foundation

// MARK: - Hint Level

/// Defines the different levels of hints available to assist players in solving Sudoku puzzles.
///
/// Hint levels are ordered from least revealing to most revealing, allowing players
/// to choose how much assistance they need.
enum HintLevel: Int {
    /// Shows the region (row, column, or 3x3 box) where a move should be made.
    case showRegion = 1
    
    /// Reveals which number should be placed without showing the exact cell.
    case showNumber = 2
    
    /// Highlights the specific cell where the next move should be made.
    case highlightCell = 3
    
    /// Reveals the complete answer for the next cell.
    case revealAnswer = 4
}
