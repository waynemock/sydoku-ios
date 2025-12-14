import Foundation

/// A snapshot of the game state at a specific point in time.
///
/// `GameState` captures the essential game data needed for undo/redo functionality.
/// Each state represents a complete snapshot of the board configuration, notes, and
/// mistake count, allowing players to step backward and forward through their moves.
struct GameState {
    /// The state of the 9x9 game board at this point in time.
    ///
    /// Each cell contains a number (1-9) or 0 if empty.
    var board: [[Int]]
    
    /// The pencil mark notes for each cell at this point in time.
    ///
    /// A 9x9 grid where each cell contains a set of candidate numbers
    /// that the player has marked as possibilities.
    var notes: [[Set<Int>]]
    
    /// The number of mistakes made up to this point in the game.
    ///
    /// This count is preserved across undo/redo operations to maintain
    /// accurate mistake tracking.
    var mistakes: Int
}
