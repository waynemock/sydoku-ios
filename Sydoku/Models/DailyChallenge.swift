import Foundation

struct DailyChallenge {
    static func getSeed(for date: Date) -> Int {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        return components.year! * 10000 + components.month! * 100 + components.day!
    }
    
    static func getDateString(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
}
