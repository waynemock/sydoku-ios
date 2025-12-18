//
//  StatsAdapter.swift
//  Sydoku
//
//  Created by Wayne Mock on 12/18/25.
//

import Foundation

/// Adapter to convert between SwiftData GameStatistics model and GameStats struct.
///
/// This adapter helps bridge the gap during migration, allowing the existing
/// `SudokuGame` code to continue using `GameStats` struct while persisting
/// to SwiftData's `GameStatistics` model.
struct StatsAdapter {
    
    /// Converts a SwiftData GameStatistics model to a GameStats struct.
    ///
    /// - Parameter model: The SwiftData model to convert.
    /// - Returns: A GameStats struct with the same data.
    static func toStruct(from model: GameStatistics) -> GameStats {
        var stats = GameStats()
        stats.gamesPlayed = model.gamesPlayed
        stats.gamesCompleted = model.gamesCompleted
        stats.bestTimes = model.bestTimes
        stats.totalTime = model.totalTime
        stats.currentStreak = model.currentStreak
        stats.bestStreak = model.bestStreak
        
        // Daily challenge stats
        stats.dailyChallengeStats.dailiesCompleted = model.dailiesCompleted
        stats.dailyChallengeStats.bestDailyTimes = model.bestDailyTimes
        stats.dailyChallengeStats.totalDailyTimes = model.totalDailyTimes
        stats.dailyChallengeStats.currentDailyStreak = model.currentDailyStreak
        stats.dailyChallengeStats.bestDailyStreak = model.bestDailyStreak
        stats.dailyChallengeStats.lastDailyCompletionDate = model.lastDailyCompletionDate
        stats.dailyChallengeStats.perfectDays = model.perfectDays
        
        return stats
    }
    
    /// Updates a SwiftData GameStatistics model with data from a GameStats struct.
    ///
    /// - Parameters:
    ///   - model: The SwiftData model to update.
    ///   - stats: The GameStats struct to copy data from.
    static func updateModel(_ model: GameStatistics, from stats: GameStats) {
        model.gamesPlayed = stats.gamesPlayed
        model.gamesCompleted = stats.gamesCompleted
        model.bestTimes = stats.bestTimes
        model.totalTime = stats.totalTime
        model.currentStreak = stats.currentStreak
        model.bestStreak = stats.bestStreak
        
        // Daily challenge stats
        model.dailiesCompleted = stats.dailyChallengeStats.dailiesCompleted
        model.bestDailyTimes = stats.dailyChallengeStats.bestDailyTimes
        model.totalDailyTimes = stats.dailyChallengeStats.totalDailyTimes
        model.currentDailyStreak = stats.dailyChallengeStats.currentDailyStreak
        model.bestDailyStreak = stats.dailyChallengeStats.bestDailyStreak
        model.lastDailyCompletionDate = stats.dailyChallengeStats.lastDailyCompletionDate
        model.perfectDays = stats.dailyChallengeStats.perfectDays
        model.lastUpdated = Date()
    }
}

