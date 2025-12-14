import Foundation

/// Tracks and manages game statistics for Sudoku puzzles.
///
/// `GameStats` maintains performance metrics including games played, completion times,
/// win streaks, and best times across different difficulty levels.
struct GameStats: Codable {
    /// Number of games started for each difficulty level, keyed by difficulty name.
    var gamesPlayed: [String: Int] = [:]
    
    /// Number of games successfully completed for each difficulty level, keyed by difficulty name.
    var gamesCompleted: [String: Int] = [:]
    
    /// Best completion times for each difficulty level, keyed by difficulty name.
    var bestTimes: [String: TimeInterval] = [:]
    
    /// Total time spent playing across all games.
    var totalTime: TimeInterval = 0
    
    /// The current win streak (consecutive completed games).
    var currentStreak: Int = 0
    
    /// The highest win streak ever achieved.
    var bestStreak: Int = 0
    
    /// Records a successful game completion.
    ///
    /// Updates completion count, total time, streaks, and best time for the given difficulty.
    ///
    /// - Parameters:
    ///   - difficulty: The difficulty level of the completed game.
    ///   - time: The time taken to complete the game.
    mutating func recordWin(difficulty: String, time: TimeInterval) {
        gamesCompleted[difficulty, default: 0] += 1
        totalTime += time
        currentStreak += 1
        bestStreak = max(bestStreak, currentStreak)
        
        if let bestTime = bestTimes[difficulty] {
            bestTimes[difficulty] = min(bestTime, time)
        } else {
            bestTimes[difficulty] = time
        }
    }
    
    /// Records the start of a new game.
    ///
    /// - Parameter difficulty: The difficulty level of the game being started.
    mutating func recordStart(difficulty: String) {
        gamesPlayed[difficulty, default: 0] += 1
    }
    
    /// Resets the current win streak to zero.
    ///
    /// Call this method when a player starts a new game without completing the previous one,
    /// or when they request a new puzzle before finishing.
    mutating func breakStreak() {
        currentStreak = 0
    }
    
    /// Calculates the average completion time for a specific difficulty level.
    ///
    /// - Parameter difficulty: The difficulty level to calculate the average for.
    /// - Returns: The average time, or `nil` if no games have been completed at this difficulty.
    func averageTime(for difficulty: String) -> TimeInterval? {
        let completed = gamesCompleted[difficulty, default: 0]
        guard completed > 0 else { return nil }
        return totalTime / TimeInterval(completed)
    }
}
