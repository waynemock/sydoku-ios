import Foundation

/// A complete saved game state that can be persisted and restored.
///
/// `SavedGame` captures all information necessary to save a game in progress
/// and restore it later. This includes the puzzle state, user progress, timing
/// information, and game configuration. The structure is `Codable` to enable
/// serialization to UserDefaults or other storage mechanisms.
struct SavedGame: Codable {
    /// The current state of the 9x9 game board.
    ///
    /// Contains user-entered numbers (1-9) and empty cells (0).
    var board: [[Int]]
    
    /// The pencil mark notes for each cell.
    ///
    /// A 9x9 grid where each cell contains a set of candidate numbers
    /// that the player has marked as possible values.
    var notes: [[Set<Int>]]
    
    /// The complete solution to the puzzle.
    ///
    /// Used for validation, hint generation, and checking completion.
    var solution: [[Int]]
    
    /// The initial puzzle state with given numbers.
    ///
    /// Represents the starting configuration before any user moves.
    /// Used to distinguish between given numbers (immutable) and user entries.
    var initialBoard: [[Int]]
    
    /// The difficulty level of the saved game.
    ///
    /// Stored as a string (e.g., "easy", "medium", "hard") to identify
    /// the puzzle's difficulty for statistics tracking.
    var difficulty: String
    
    /// The elapsed time in seconds when the game was saved.
    ///
    /// Allows the timer to resume from the correct value when the game is restored.
    var elapsedTime: TimeInterval
    
    /// The date and time when the game was originally started.
    ///
    /// Used for tracking and displaying when the game began.
    var startDate: Date
    
    /// The number of mistakes made in this game so far.
    ///
    /// Preserved to maintain accurate mistake tracking across save/load cycles,
    /// especially important when a mistake limit is configured.
    var mistakes: Int
    
    /// Whether this is a daily challenge game.
    ///
    /// Indicates if the saved game is from a daily challenge puzzle,
    /// which affects UI display and completion tracking.
    var isDailyChallenge: Bool
    
    /// The date string for the daily challenge (if applicable).
    ///
    /// Format: "yyyy-MM-dd". Used to determine if the saved daily challenge
    /// is still valid or has expired.
    var dailyChallengeDate: String?
}
