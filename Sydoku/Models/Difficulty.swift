import Foundation

enum Difficulty: String, Codable, CaseIterable {
    case easy, medium, hard
    
    var cellsToRemove: Int {
        switch self {
        case .easy: return 35
        case .medium: return 45
        case .hard: return 52
        }
    }
    
    var name: String {
        switch self {
        case .easy: return "Easy"
        case .medium: return "Medium"
        case .hard: return "Hard"
        }
    }
}
