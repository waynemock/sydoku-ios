import Foundation

struct SavedGame: Codable {
    var board: [[Int]]
    var notes: [[Set<Int>]]
    var solution: [[Int]]
    var initialBoard: [[Int]]
    var difficulty: String
    var elapsedTime: TimeInterval
    var startDate: Date
    var mistakes: Int
}
