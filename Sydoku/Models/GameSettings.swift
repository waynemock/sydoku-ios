import Foundation

/// User preferences and settings for the Sudoku game.
///
/// `GameSettings` stores configurable gameplay options and preferences that persist
/// across game sessions. Settings are encoded/decoded for storage in UserDefaults.
struct GameSettings: Codable {
    /// Whether to automatically check for errors when placing numbers.
    ///
    /// When enabled, incorrect placements are immediately detected and count toward
    /// the mistake limit. When disabled, errors are only revealed when the puzzle is completed.
    var autoErrorChecking: Bool = true
    
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
    
    /// The date string (yyyy-MM-dd) of the last completed daily challenge.
    ///
    /// Used to track whether today's daily challenge has already been completed
    /// and prevent duplicate completions.
    var lastDailyPuzzleDate: String = ""
    
    /// The selected theme type for the app.
    var themeType: String = "Classic"
    
    /// The preferred color scheme: "light", "dark", or "system".
    var preferredColorScheme: String = "dark"
}

