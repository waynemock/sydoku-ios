//
//  PersistenceService.swift
//  Sydoku
//
//  Created by Wayne Mock on 12/18/25.
//

import Foundation
import SwiftData

/// Service for managing game data persistence with SwiftData and CloudKit sync.
///
/// This service provides a centralized interface for saving and loading game data,
/// statistics, and settings, with automatic CloudKit synchronization.
@MainActor
@Observable
class PersistenceService {
    private let modelContext: ModelContext
    
    /// Sync monitor for debugging CloudKit sync.
    var syncMonitor: CloudKitSyncMonitor
    
    /// CloudKit service for manual sync operations.
    @ObservationIgnored
    private var cloudKitService: CloudKitService
    
    /// Initializes the persistence service with a model context.
    ///
    /// - Parameter modelContext: The SwiftData model context for data operations.
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        let monitor = CloudKitSyncMonitor()
        self.syncMonitor = monitor
        self.cloudKitService = CloudKitService(syncMonitor: monitor)
        syncMonitor.logSync("PersistenceService initialized")
    }
    
    // MARK: - Manual Sync Control
    
    /// Forces an immediate save to trigger CloudKit sync.
    ///
    /// Call this after important changes to ensure data is uploaded to CloudKit promptly.
    func forceSave() {
        do {
            try modelContext.save()
            syncMonitor.logSync("Forced save completed - CloudKit sync triggered")
        } catch {
            syncMonitor.logError("Failed to force save: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Statistics
    
    /// Fetches or creates the game statistics record.
    ///
    /// Only one statistics record should exist per user. This method fetches
    /// the existing record or creates a new one if none exists.
    ///
    /// - Returns: The game statistics record.
    func fetchOrCreateStatistics() -> GameStatistics {
        let descriptor = FetchDescriptor<GameStatistics>()
        
        if let existing = try? modelContext.fetch(descriptor).first {
            syncMonitor.logFetch("Loaded existing statistics (updated: \(existing.lastUpdated))")
            return existing
        }
        
        // Create new statistics record
        let stats = GameStatistics()
        modelContext.insert(stats)
        try? modelContext.save()
        syncMonitor.logSave("Created new statistics record")
        return stats
    }
    
    /// Updates and saves statistics.
    ///
    /// - Parameter statistics: The statistics record to update.
    func saveStatistics(_ statistics: GameStatistics) {
        let timestamp = Date()
        statistics.lastUpdated = timestamp
        syncMonitor.logSave("Statistics updated (timestamp: \(timestamp))")
        forceSave()
        
        // Upload to CloudKit immediately with the SAME timestamp
        Task {
            do {
                try await cloudKitService.uploadStatistics(statistics, timestamp: timestamp)
            } catch {
                // Log error but don't fail the save
                syncMonitor.logError("CloudKit upload failed (saved locally): \(error.localizedDescription)")
            }
        }
    }
    
    /// Downloads the latest statistics from CloudKit and updates local storage.
    ///
    /// This should be called when the app comes to foreground to get the latest
    /// statistics from other devices.
    func syncStatisticsFromCloudKit() async -> GameStatistics? {
        do {
            // First attempt
            guard let cloudKitStats = try await cloudKitService.downloadStatistics() else {
                syncMonitor.logSync("No statistics in CloudKit")
                return nil
            }
            
            // Check if we need to update local storage
            let localStats = fetchOrCreateStatistics()
            
            syncMonitor.logSync("Comparing timestamps: CloudKit=\(cloudKitStats.lastUpdated) vs Local=\(localStats.lastUpdated)")
            
            // If timestamps are equal, we're already in sync - no need to do anything
            if localStats.lastUpdated == cloudKitStats.lastUpdated {
                syncMonitor.logSync("Local statistics are up to date (same timestamp)")
                return localStats
            }
            
            // If local is newer than CloudKit, there might be propagation delay
            // Wait briefly and try again (only for very recent changes)
            if localStats.lastUpdated > cloudKitStats.lastUpdated {
                let timeDiff = localStats.lastUpdated.timeIntervalSince(cloudKitStats.lastUpdated)
                if timeDiff < 10 { // Only retry if difference is less than 10 seconds (very recent change)
                    syncMonitor.logSync("Local is newer by \(String(format: "%.1f", timeDiff))s, checking CloudKit again...")
                    try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds (reduced from 2)
                    
                    // Retry download
                    if let retryStats = try await cloudKitService.downloadStatistics() {
                        if retryStats.lastUpdated > localStats.lastUpdated {
                            syncMonitor.logSync("CloudKit has newer statistics after retry, updating local...")
                            
                            // Update local statistics with CloudKit data
                            updateLocalStatistics(localStats, from: retryStats)
                            
                            try? modelContext.save()
                            syncMonitor.logSync("✅ Local statistics updated from CloudKit after retry")
                            
                            return localStats
                        }
                    }
                }
                
                syncMonitor.logSync("Local statistics are up to date (CloudKit not newer)")
                return localStats
            }
            
            // If CloudKit is newer, update local
            if cloudKitStats.lastUpdated > localStats.lastUpdated {
                syncMonitor.logSync("CloudKit has newer statistics, updating local...")
                
                // Update local statistics with CloudKit data
                updateLocalStatistics(localStats, from: cloudKitStats)
                
                try? modelContext.save()
                syncMonitor.logSync("✅ Local statistics updated from CloudKit")
                
                return localStats
            } else {
                syncMonitor.logSync("Local statistics are up to date (same timestamp)")
                return localStats
            }
        } catch {
            syncMonitor.logError("Failed to sync statistics from CloudKit: \(error.localizedDescription)")
            return nil
        }
    }
    
    /// Helper to update local statistics with CloudKit data.
    private func updateLocalStatistics(_ local: GameStatistics, from cloudKit: GameStatistics) {
        local.gamesPlayed = cloudKit.gamesPlayed
        local.gamesCompleted = cloudKit.gamesCompleted
        local.bestTimes = cloudKit.bestTimes
        local.totalTime = cloudKit.totalTime
        local.currentStreak = cloudKit.currentStreak
        local.bestStreak = cloudKit.bestStreak
        local.dailiesCompleted = cloudKit.dailiesCompleted
        local.bestDailyTimes = cloudKit.bestDailyTimes
        local.totalDailyTimes = cloudKit.totalDailyTimes
        local.currentDailyStreak = cloudKit.currentDailyStreak
        local.bestDailyStreak = cloudKit.bestDailyStreak
        local.lastDailyCompletionDate = cloudKit.lastDailyCompletionDate
        local.perfectDays = cloudKit.perfectDays
        local.lastUpdated = cloudKit.lastUpdated
    }
    
    // MARK: - Saved Game
    
    /// Fetches the current saved game, if one exists.
    ///
    /// - Returns: The saved game state, or nil if no game is saved.
    func fetchSavedGame() -> SavedGameState? {
        let descriptor = FetchDescriptor<SavedGameState>(
            sortBy: [SortDescriptor(\.lastSaved, order: .reverse)]
        )
        
        let game = try? modelContext.fetch(descriptor).first
        if let game = game {
            syncMonitor.logFetch("Loaded saved game (saved: \(game.lastSaved))")
        } else {
            syncMonitor.logFetch("No saved game found")
        }
        return game
    }
    
    /// Saves the current game state.
    ///
    /// Replaces any existing saved game with the new state.
    ///
    /// - Parameters:
    ///   - board: Current board state.
    ///   - notes: Current pencil notes.
    ///   - solution: The puzzle solution.
    ///   - initialBoard: The initial puzzle state.
    ///   - difficulty: The difficulty level.
    ///   - elapsedTime: Time elapsed in seconds.
    ///   - startDate: When the game started.
    ///   - mistakes: Number of mistakes made.
    ///   - isDailyChallenge: Whether this is a daily challenge.
    ///   - dailyChallengeDate: The date string for daily challenges.
    func saveGame(
        board: [[Int]],
        notes: [[Set<Int>]],
        solution: [[Int]],
        initialBoard: [[Int]],
        difficulty: String,
        elapsedTime: TimeInterval,
        startDate: Date,
        mistakes: Int,
        hints: [[Int]],
        isDailyChallenge: Bool,
        dailyChallengeDate: String?
    ) {
        // Delete any existing saved game
        deleteSavedGame()
        
        // Create new saved game with synchronized timestamp
        let notesData = SavedGameState.encodeNotes(notes)
        let boardData = SavedGameState.flatten(board)
        let solutionData = SavedGameState.flatten(solution)
        let initialBoardData = SavedGameState.flatten(initialBoard)
        let hintsData = SavedGameState.flatten(hints)
        let timestamp = Date()
        
        let savedGame = SavedGameState(
            boardData: boardData,
            notesData: notesData,
            solutionData: solutionData,
            initialBoardData: initialBoardData,
            difficulty: difficulty,
            elapsedTime: elapsedTime,
            startDate: startDate,
            mistakes: mistakes,
            hintsData: hintsData,
            isDailyChallenge: isDailyChallenge,
            dailyChallengeDate: dailyChallengeDate,
            lastSaved: timestamp
        )
        
        modelContext.insert(savedGame)
        syncMonitor.logSave("Game state saved (difficulty: \(difficulty), time: \(Int(elapsedTime))s, timestamp: \(timestamp))")
        forceSave()
        
        // Upload to CloudKit immediately with the SAME timestamp
        Task {
            do {
                try await cloudKitService.uploadSavedGame(
                    boardData: boardData,
                    notesData: notesData,
                    solutionData: solutionData,
                    initialBoardData: initialBoardData,
                    difficulty: difficulty,
                    elapsedTime: elapsedTime,
                    startDate: startDate,
                    mistakes: mistakes,
                    isDailyChallenge: isDailyChallenge,
                    dailyChallengeDate: dailyChallengeDate,
                    lastSaved: timestamp
                )
            } catch {
                // Log error but don't fail the save
                syncMonitor.logError("CloudKit upload failed (saved locally): \(error.localizedDescription)")
            }
        }
    }
    
    /// Deletes the saved game.
    func deleteSavedGame() {
        let descriptor = FetchDescriptor<SavedGameState>()
        if let games = try? modelContext.fetch(descriptor) {
            for game in games {
                modelContext.delete(game)
            }
            syncMonitor.logDelete("Saved game deleted")
            forceSave()
            
            // Also delete from CloudKit
            Task {
                try? await cloudKitService.deleteSavedGame()
            }
        }
    }
    
    /// Checks if a saved game exists.
    ///
    /// - Returns: True if a saved game exists, false otherwise.
    func hasSavedGame() -> Bool {
        let descriptor = FetchDescriptor<SavedGameState>()
        let count = (try? modelContext.fetchCount(descriptor)) ?? 0
        return count > 0
    }
    
    // MARK: - CloudKit Sync
    
    /// Downloads the latest saved game from CloudKit and updates local storage.
    ///
    /// This should be called when the app comes to foreground to get the latest
    /// data from other devices.
    func syncSavedGameFromCloudKit() async -> SavedGameState? {
        do {
            guard let cloudKitGame = try await cloudKitService.downloadSavedGame() else {
                syncMonitor.logSync("No saved game in CloudKit")
                return nil
            }
            
            // Check if we need to update local storage
            let localGame = fetchSavedGame()
            
            // If CloudKit is newer, update local
            if localGame == nil || cloudKitGame.lastSaved > localGame!.lastSaved {
                syncMonitor.logSync("CloudKit has newer data, updating local...")
                
                // Delete old local game
                if localGame != nil {
                    deleteSavedGame()
                }
                
                // Save CloudKit data locally
                let savedGame = SavedGameState(
                    boardData: cloudKitGame.boardData,
                    notesData: cloudKitGame.notesData,
                    solutionData: cloudKitGame.solutionData,
                    initialBoardData: cloudKitGame.initialBoardData,
                    difficulty: cloudKitGame.difficulty,
                    elapsedTime: cloudKitGame.elapsedTime,
                    startDate: cloudKitGame.startDate,
                    mistakes: cloudKitGame.mistakes,
                    hintsData: cloudKitGame.hintsData,
                    isDailyChallenge: cloudKitGame.isDailyChallenge,
                    dailyChallengeDate: cloudKitGame.dailyChallengeDate,
                    lastSaved: cloudKitGame.lastSaved
                )
                
                modelContext.insert(savedGame)
                try? modelContext.save()
                syncMonitor.logSync("✅ Local game updated from CloudKit")
                
                return savedGame
            } else {
                syncMonitor.logSync("Local game is up to date")
                return localGame
            }
        } catch {
            syncMonitor.logError("Failed to sync from CloudKit: \(error.localizedDescription)")
            return nil
        }
    }
    
    // MARK: - Settings
    
    /// Fetches or creates the user settings record.
    ///
    /// - Returns: The user settings record.
    func fetchOrCreateSettings() -> UserSettings {
        let descriptor = FetchDescriptor<UserSettings>()
        
        if let existing = try? modelContext.fetch(descriptor).first {
            syncMonitor.logFetch("Loaded existing settings (updated: \(existing.lastUpdated))")
            return existing
        }
        
        // Create new settings record
        let settings = UserSettings()
        modelContext.insert(settings)
        try? modelContext.save()
        syncMonitor.logSave("Created new settings record")
        return settings
    }
    
    /// Updates and saves settings.
    ///
    /// - Parameter settings: The settings record to update.
    func saveSettings(_ settings: UserSettings) {
        let timestamp = Date()
        settings.lastUpdated = timestamp
        syncMonitor.logSave("Settings updated (timestamp: \(timestamp))")
        forceSave()
        
        // Upload to CloudKit immediately with the SAME timestamp
        Task {
            do {
                try await cloudKitService.uploadSettings(settings, timestamp: timestamp)
            } catch {
                // Log error but don't fail the save
                syncMonitor.logError("CloudKit upload failed (saved locally): \(error.localizedDescription)")
            }
        }
    }
    
    /// Downloads the latest settings from CloudKit and updates local storage.
    ///
    /// This should be called when the app comes to foreground to get the latest
    /// settings from other devices.
    func syncSettingsFromCloudKit() async -> UserSettings? {
        do {
            // First attempt
            guard let cloudKitSettings = try await cloudKitService.downloadSettings() else {
                syncMonitor.logSync("No settings in CloudKit")
                return nil
            }
            
            // Check if we need to update local storage
            let localSettings = fetchOrCreateSettings()
            
            syncMonitor.logSync("Comparing timestamps: CloudKit=\(cloudKitSettings.lastUpdated) vs Local=\(localSettings.lastUpdated)")
            syncMonitor.logSync("CloudKit theme: \(cloudKitSettings.themeTypeRawValue), Local theme: \(localSettings.themeTypeRawValue)")
            
            // If timestamps are equal, we're already in sync - no need to do anything
            if localSettings.lastUpdated == cloudKitSettings.lastUpdated {
                syncMonitor.logSync("Local settings are up to date (same timestamp)")
                return localSettings
            }
            
            // If local is newer than CloudKit, there might be propagation delay
            // Wait briefly and try again (only for very recent changes)
            if localSettings.lastUpdated > cloudKitSettings.lastUpdated {
                let timeDiff = localSettings.lastUpdated.timeIntervalSince(cloudKitSettings.lastUpdated)
                if timeDiff < 10 { // Only retry if difference is less than 10 seconds (very recent change)
                    syncMonitor.logSync("Local is newer by \(String(format: "%.1f", timeDiff))s, checking CloudKit again...")
                    try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds (reduced from 2)
                    
                    // Retry download
                    if let retrySettings = try await cloudKitService.downloadSettings() {
                        syncMonitor.logSync("Retry - CloudKit theme: \(retrySettings.themeTypeRawValue)")
                        
                        if retrySettings.lastUpdated > localSettings.lastUpdated {
                            syncMonitor.logSync("CloudKit has newer settings after retry, updating local...")
                            
                            // Update local settings with CloudKit data
                            localSettings.autoErrorChecking = retrySettings.autoErrorChecking
                            localSettings.mistakeLimit = retrySettings.mistakeLimit
                            localSettings.hapticFeedback = retrySettings.hapticFeedback
                            localSettings.soundEffects = retrySettings.soundEffects
                            localSettings.highlightSameNumbers = retrySettings.highlightSameNumbers
                            localSettings.completedDailyChallenges = retrySettings.completedDailyChallenges
                            localSettings.themeTypeRawValue = retrySettings.themeTypeRawValue
                            localSettings.preferredColorSchemeRawValue = retrySettings.preferredColorSchemeRawValue
                            localSettings.lastUpdated = retrySettings.lastUpdated
                            
                            try? modelContext.save()
                            syncMonitor.logSync("✅ Local settings updated from CloudKit after retry (theme now: \(localSettings.themeTypeRawValue))")
                            
                            return localSettings
                        }
                    }
                }
                
                syncMonitor.logSync("Local settings are up to date (CloudKit not newer)")
                return localSettings
            }
            
            // If CloudKit is newer, update local
            if cloudKitSettings.lastUpdated > localSettings.lastUpdated {
                syncMonitor.logSync("CloudKit has newer settings, updating local...")
                
                // Update local settings with CloudKit data
                localSettings.autoErrorChecking = cloudKitSettings.autoErrorChecking
                localSettings.mistakeLimit = cloudKitSettings.mistakeLimit
                localSettings.hapticFeedback = cloudKitSettings.hapticFeedback
                localSettings.soundEffects = cloudKitSettings.soundEffects
                localSettings.highlightSameNumbers = cloudKitSettings.highlightSameNumbers
                localSettings.completedDailyChallenges = cloudKitSettings.completedDailyChallenges
                localSettings.themeTypeRawValue = cloudKitSettings.themeTypeRawValue
                localSettings.preferredColorSchemeRawValue = cloudKitSettings.preferredColorSchemeRawValue
                localSettings.lastUpdated = cloudKitSettings.lastUpdated
                
                try? modelContext.save()
                syncMonitor.logSync("✅ Local settings updated from CloudKit (theme now: \(localSettings.themeTypeRawValue))")
                
                return localSettings
            } else {
                syncMonitor.logSync("Local settings are up to date (same timestamp)")
                return localSettings
            }
        } catch {
            syncMonitor.logError("Failed to sync settings from CloudKit: \(error.localizedDescription)")
            return nil
        }
    }
}
