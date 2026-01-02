import Foundation

/// Utilities for generating and managing daily Sudoku challenges.
///
/// `DailyChallenge` provides methods to generate consistent puzzle seeds based on dates,
/// ensuring that all users receive the same daily challenge puzzle.
struct DailyChallenge {
    /// Generates a deterministic seed value from a given date and difficulty level.
    ///
    /// The seed is calculated using the date components (year, month, day) and difficulty
    /// to ensure that the same date and difficulty always produce the same seed value,
    /// enabling consistent daily challenges across all users while providing unique
    /// puzzles for each difficulty level.
    ///
    /// - Parameters:
    ///   - date: The date to generate a seed for.
    ///   - difficulty: The difficulty level of the puzzle.
    /// - Returns: An integer seed combining the date (YYYYMMDD) and difficulty multiplier.
    static func getSeed(for date: Date, difficulty: Difficulty) -> Int {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        let dateSeed = components.year! * 10000 + components.month! * 100 + components.day!
        
        // Multiply by a prime number based on difficulty to ensure unique seeds
        let difficultyMultiplier: Int
        switch difficulty {
        case .easy:
            difficultyMultiplier = 1
        case .medium:
            difficultyMultiplier = 7919  // Prime number
        case .hard:
            difficultyMultiplier = 15737 // Prime number
        }
        
        return dateSeed * difficultyMultiplier
    }
    
    /// Formats a date as a string in ISO 8601 format (yyyy-MM-dd).
    ///
    /// This standardized format is useful for storing or displaying daily challenge dates.
    ///
    /// - Parameter date: The date to format.
    /// - Returns: A string representation of the date (e.g., "2025-12-14").
    static func getDateString(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
}
