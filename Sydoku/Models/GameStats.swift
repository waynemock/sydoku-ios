import Foundation

struct GameStats: Codable {
    var gamesPlayed: [String: Int] = [:]
    var gamesCompleted: [String: Int] = [:]
    var bestTimes: [String: TimeInterval] = [:]
    var totalTime: TimeInterval = 0
    var currentStreak: Int = 0
    var bestStreak: Int = 0
    
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
    
    mutating func recordStart(difficulty: String) {
        gamesPlayed[difficulty, default: 0] += 1
    }
    
    mutating func breakStreak() {
        currentStreak = 0
    }
    
    func averageTime(for difficulty: String) -> TimeInterval? {
        let completed = gamesCompleted[difficulty, default: 0]
        guard completed > 0 else { return nil }
        return totalTime / TimeInterval(completed)
    }
}
