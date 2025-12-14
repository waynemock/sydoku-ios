import Foundation

struct GameSettings: Codable {
    var autoErrorChecking: Bool = true
    var mistakeLimit: Int = 0 // 0 = unlimited
    var hapticFeedback: Bool = true
    var soundEffects: Bool = false
    var highlightSameNumbers: Bool = true
    var lastDailyPuzzleDate: String = ""
}

