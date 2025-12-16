import Foundation

/// Tracks statistics specific to daily challenges.
///
/// `DailyChallengeStats` maintains separate metrics for daily challenge performance,
/// including streaks, perfect days, and completion times per difficulty.
struct DailyChallengeStats: Codable {
    /// Number of daily challenges completed for each difficulty level.
    var dailiesCompleted: [String: Int] = [:]
    
    /// Best completion times for daily challenges per difficulty.
    var bestDailyTimes: [String: TimeInterval] = [:]
    
    /// Total completion times for daily challenges per difficulty.
    var totalDailyTimes: [String: TimeInterval] = [:]
    
    /// Current daily streak (consecutive days with at least one daily completed).
    var currentDailyStreak: Int = 0
    
    /// Best daily streak ever achieved.
    var bestDailyStreak: Int = 0
    
    /// Date of the last daily challenge completion (to track streaks).
    var lastDailyCompletionDate: String = ""
    
    /// Number of "perfect days" (all 3 difficulties completed on the same day).
    var perfectDays: Int = 0
    
    /// Records a daily challenge completion.
    ///
    /// - Parameters:
    ///   - difficulty: The difficulty level completed.
    ///   - time: The completion time.
    ///   - date: The date string (yyyy-MM-dd) of completion.
    ///   - allCompleted: Whether all 3 difficulties are now completed for this day.
    mutating func recordDailyWin(difficulty: String, time: TimeInterval, date: String, allCompleted: Bool) {
        // Update completion count
        dailiesCompleted[difficulty, default: 0] += 1
        
        // Update total time for averaging
        totalDailyTimes[difficulty, default: 0] += time
        
        // Update best time
        if let bestTime = bestDailyTimes[difficulty] {
            bestDailyTimes[difficulty] = min(bestTime, time)
        } else {
            bestDailyTimes[difficulty] = time
        }
        
        // Update streak
        updateStreak(date: date)
        
        // Check for perfect day
        if allCompleted {
            perfectDays += 1
        }
    }
    
    /// Updates the daily streak based on completion date.
    ///
    /// - Parameter date: The date string of the completion.
    private mutating func updateStreak(date: String) {
        if lastDailyCompletionDate.isEmpty {
            // First daily challenge ever
            currentDailyStreak = 1
        } else if date == lastDailyCompletionDate {
            // Same day, don't increment streak
            return
        } else if isConsecutiveDay(from: lastDailyCompletionDate, to: date) {
            // Consecutive day
            currentDailyStreak += 1
        } else {
            // Streak broken
            currentDailyStreak = 1
        }
        
        bestDailyStreak = max(bestDailyStreak, currentDailyStreak)
        lastDailyCompletionDate = date
    }
    
    /// Checks if two date strings represent consecutive days.
    ///
    /// - Parameters:
    ///   - from: The earlier date string (yyyy-MM-dd).
    ///   - to: The later date string (yyyy-MM-dd).
    /// - Returns: `true` if the dates are consecutive days.
    private func isConsecutiveDay(from: String, to: String) -> Bool {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        
        guard let fromDate = formatter.date(from: from),
              let toDate = formatter.date(from: to) else {
            return false
        }
        
        let calendar = Calendar.current
        guard let nextDay = calendar.date(byAdding: .day, value: 1, to: fromDate) else {
            return false
        }
        
        return calendar.isDate(nextDay, inSameDayAs: toDate)
    }
    
    /// Calculates average completion time for daily challenges at a specific difficulty.
    ///
    /// - Parameter difficulty: The difficulty level.
    /// - Returns: The average time, or `nil` if no dailies completed at this difficulty.
    func averageDailyTime(for difficulty: String) -> TimeInterval? {
        let completed = dailiesCompleted[difficulty, default: 0]
        guard completed > 0 else { return nil }
        let total = totalDailyTimes[difficulty, default: 0]
        return total / TimeInterval(completed)
    }
}

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
    
    /// Daily challenge-specific statistics.
    var dailyChallengeStats = DailyChallengeStats()
    
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
