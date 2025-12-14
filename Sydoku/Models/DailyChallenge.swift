import Foundation

/// Utilities for generating and managing daily Sudoku challenges.
///
/// `DailyChallenge` provides methods to generate consistent puzzle seeds based on dates,
/// ensuring that all users receive the same daily challenge puzzle.
struct DailyChallenge {
    /// Generates a deterministic seed value from a given date.
    ///
    /// The seed is calculated using the date components (year, month, day) to ensure
    /// that the same date always produces the same seed value, enabling consistent
    /// daily challenges across all users.
    ///
    /// - Parameter date: The date to generate a seed for.
    /// - Returns: An integer seed in the format YYYYMMDD (e.g., 20251214 for December 14, 2025).
    static func getSeed(for date: Date) -> Int {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        return components.year! * 10000 + components.month! * 100 + components.day!
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
