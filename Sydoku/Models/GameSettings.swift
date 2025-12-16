import Foundation
import SwiftUI

/// User preferences and settings for the Sudoku game.
///
/// `GameSettings` stores configurable gameplay options and preferences that persist
/// across game sessions. Settings are encoded/decoded for storage in UserDefaults.
struct GameSettings: Codable {
    /// Preferred color scheme option.
    enum ColorSchemePreference: String, Codable, CaseIterable {
        case system
        case light
        case dark
        
        /// Converts the preference to a SwiftUI ColorScheme.
        /// Returns nil for system preference to allow automatic adaptation.
        func toColorScheme(system: ColorScheme) -> ColorScheme {
            switch self {
            case .system:
                return system
            case .light:
                return .light
            case .dark:
                return .dark
            }
        }
        
        /// Display name for the preference.
        var displayName: String {
            switch self {
            case .system: return "System"
            case .light: return "Light"
            case .dark: return "Dark"
            }
        }
    }
    
    /// Whether to automatically check for errors when placing numbers.
    ///
    /// When enabled, incorrect placements are immediately detected and count toward
    /// the mistake limit. When disabled, errors are only revealed when the puzzle is completed.
    var autoErrorChecking: Bool = false
    
    /// The maximum number of mistakes allowed before game over.
    ///
    /// - `0`: Unlimited mistakes (no game over condition)
    /// - `3`, `5`, `10`: Limited mistakes that trigger game over when exceeded
    var mistakeLimit: Int = 0 // 0 = unlimited
    
    /// Whether to provide haptic feedback for game events.
    ///
    /// When enabled, the device vibrates for significant events like errors
    /// or successful puzzle completion.
    var hapticFeedback: Bool = true
    
    /// Whether to play sound effects for game events.
    ///
    /// Currently unused but reserved for future sound effect implementation.
    var soundEffects: Bool = false
    
    /// Whether to highlight all cells containing the same number as the selected cell.
    ///
    /// When enabled and a cell with a number is selected, all other cells with
    /// the same number are highlighted to help identify patterns.
    var highlightSameNumbers: Bool = true
    
    /// The date string (yyyy-MM-dd) of the last completed daily challenge for each difficulty.
    ///
    /// Used to track whether today's daily challenge has already been completed for each difficulty level
    /// and prevent duplicate completions. Keys are difficulty raw values ("easy", "medium", "hard").
    var completedDailyChallenges: [String: String] = [:]
    
    /// The selected theme type for the app.
    var themeType: Theme.ThemeType = .sunset
    
    /// The preferred color scheme: system, light, or dark.
    var preferredColorScheme: ColorSchemePreference = .dark
    
    /// Checks if today's daily challenge has been completed for a specific difficulty.
    ///
    /// - Parameter difficulty: The difficulty level to check.
    /// - Returns: `true` if today's challenge for this difficulty has been completed.
    func isDailyChallengeCompleted(for difficulty: Difficulty) -> Bool {
        let today = DailyChallenge.getDateString(for: Date())
        return completedDailyChallenges[difficulty.rawValue] == today
    }
    
    /// Marks today's daily challenge as completed for a specific difficulty.
    ///
    /// - Parameter difficulty: The difficulty level that was completed.
    mutating func markDailyChallengeCompleted(for difficulty: Difficulty) {
        let today = DailyChallenge.getDateString(for: Date())
        completedDailyChallenges[difficulty.rawValue] = today
    }
    
    /// Checks if all three daily challenges have been completed today.
    ///
    /// - Returns: `true` if easy, medium, and hard daily challenges have all been completed today.
    func areAllDailyChallengesCompleted() -> Bool {
        return isDailyChallengeCompleted(for: .easy) &&
               isDailyChallengeCompleted(for: .medium) &&
               isDailyChallengeCompleted(for: .hard)
    }
}

