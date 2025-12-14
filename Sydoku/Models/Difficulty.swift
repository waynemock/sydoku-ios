import Foundation

/// Represents the difficulty level of a Sudoku puzzle.
///
/// Each difficulty level determines how many cells are removed from a completed puzzle,
/// which directly affects how challenging the puzzle is to solve.
enum Difficulty: String, Codable, CaseIterable {
    /// Easy difficulty - suitable for beginners.
    case easy
    
    /// Medium difficulty - for intermediate players.
    case medium
    
    /// Hard difficulty - challenging for experienced players.
    case hard
    
    /// The number of cells to remove from a completed puzzle for this difficulty level.
    ///
    /// - Easy: 35 cells removed
    /// - Medium: 45 cells removed
    /// - Hard: 52 cells removed
    var cellsToRemove: Int {
        switch self {
        case .easy: return 35
        case .medium: return 45
        case .hard: return 52
        }
    }
    
    /// A human-readable display name for the difficulty level.
    var name: String {
        switch self {
        case .easy: return "Easy"
        case .medium: return "Medium"
        case .hard: return "Hard"
        }
    }
}
