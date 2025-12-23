//
//  GameStatistics.swift
//  Sydoku
//
//  Created by Wayne Mock on 12/18/25.
//

import Foundation
import SwiftData

/// A SwiftData model representing game statistics synced via CloudKit.
///
/// This model tracks overall performance across all Sudoku games,
/// including game counts, times, and streaks. It mirrors the `GameStats` structure
/// but uses SwiftData for persistence and CloudKit sync.
@Model
final class GameStatistics {
    /// Number of games started for each difficulty level.
    var gamesPlayed: [String: Int] = [:]
    
    /// Number of games completed for each difficulty level.
    var gamesCompleted: [String: Int] = [:]
    
    /// Best completion times for each difficulty level.
    var bestTimes: [String: TimeInterval] = [:]
    
    /// Total time spent playing across all games.
    var totalTime: TimeInterval = 0
    
    /// Current win streak (consecutive completed games).
    var currentStreak: Int = 0
    
    /// Best win streak ever achieved.
    var bestStreak: Int = 0
    
    // Daily Challenge Stats
    /// Number of daily challenges completed per difficulty.
    var dailiesCompleted: [String: Int] = [:]
    
    /// Best times for daily challenges per difficulty.
    var bestDailyTimes: [String: TimeInterval] = [:]
    
    /// Total times for daily challenges per difficulty.
    var totalDailyTimes: [String: TimeInterval] = [:]
    
    /// Current daily streak (consecutive days).
    var currentDailyStreak: Int = 0
    
    /// Best daily streak ever achieved.
    var bestDailyStreak: Int = 0
    
    /// Last daily challenge completion date string (yyyy-MM-dd).
    var lastDailyCompletionDate: String = ""
    
    /// Number of perfect days (all 3 difficulties completed).
    var perfectDays: Int = 0
    
    /// Last update timestamp for sync purposes.
    var lastUpdated: Date = Date()
    
    /// Creates a new game statistics record.
    init(
        gamesPlayed: [String: Int] = [:],
        gamesCompleted: [String: Int] = [:],
        bestTimes: [String: TimeInterval] = [:],
        totalTime: TimeInterval = 0,
        currentStreak: Int = 0,
        bestStreak: Int = 0,
        dailiesCompleted: [String: Int] = [:],
        bestDailyTimes: [String: TimeInterval] = [:],
        totalDailyTimes: [String: TimeInterval] = [:],
        currentDailyStreak: Int = 0,
        bestDailyStreak: Int = 0,
        lastDailyCompletionDate: String = "",
        perfectDays: Int = 0,
        lastUpdated: Date = Date()
    ) {
        self.gamesPlayed = gamesPlayed
        self.gamesCompleted = gamesCompleted
        self.bestTimes = bestTimes
        self.totalTime = totalTime
        self.currentStreak = currentStreak
        self.bestStreak = bestStreak
        self.dailiesCompleted = dailiesCompleted
        self.bestDailyTimes = bestDailyTimes
        self.totalDailyTimes = totalDailyTimes
        self.currentDailyStreak = currentDailyStreak
        self.bestDailyStreak = bestDailyStreak
        self.lastDailyCompletionDate = lastDailyCompletionDate
        self.perfectDays = perfectDays
        self.lastUpdated = lastUpdated
    }
}
