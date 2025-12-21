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
    
    // MARK: - In-Progress Game
    
    /// Fetches the current in-progress game, if one exists.
    ///
    /// - Returns: The in-progress game, or nil if no game is in progress.
    func fetchInProgressGame() -> Game? {
        let descriptor = FetchDescriptor<Game>(
            predicate: #Predicate { !$0.isCompleted },
            sortBy: [SortDescriptor(\.lastSaved, order: .reverse)]
        )
        
        let game = try? modelContext.fetch(descriptor).first
        if let game = game {
            syncMonitor.logFetch("Loaded in-progress game (saved: \(game.lastSaved))")
        } else {
            syncMonitor.logFetch("No in-progress game found")
        }
        return game
    }
    
    /// Saves the current in-progress game state.
    ///
    /// Replaces any existing in-progress game with the new state.
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
    ///   - hints: Grid indicating which cells had hints (9x9 grid).
    ///   - isDailyChallenge: Whether this is a daily challenge.
    ///   - dailyChallengeDate: The date string for daily challenges.
    ///   - selectedCell: The currently selected cell (row, col), or nil if none selected.
    ///   - highlightedNumber: The currently highlighted number (1-9), or nil if none highlighted.
    ///   - isPencilMode: Whether pencil mode is currently active.
    ///   - isPaused: Whether the game is currently paused.
    func saveInProgressGame(
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
        dailyChallengeDate: String?,
        selectedCell: (row: Int, col: Int)?,
        highlightedNumber: Int?,
        isPencilMode: Bool,
        isPaused: Bool
    ) {
        // Delete any existing in-progress game
        deleteInProgressGame()
        
        // Create new in-progress game with synchronized timestamp
        let notesData = Game.encodeNotes(notes)
        let boardData = Game.flatten(board)
        let solutionData = Game.flatten(solution)
        let initialBoardData = Game.flatten(initialBoard)
        let hintsData = Game.flatten(hints)
        let timestamp = Date()
        
        let game = Game(
            initialBoardData: initialBoardData,
            solutionData: solutionData,
            boardData: boardData,
            notesData: notesData,
            difficulty: difficulty,
            elapsedTime: elapsedTime,
            startDate: startDate,
            mistakes: mistakes,
            hintsData: hintsData,
            isDailyChallenge: isDailyChallenge,
            dailyChallengeDate: dailyChallengeDate,
            isCompleted: false,
            completionDate: nil,
            lastSaved: timestamp,
            gameID: Game.inProgressGameID,
            selectedCellRow: selectedCell?.row,
            selectedCellCol: selectedCell?.col,
            highlightedNumber: highlightedNumber,
            isPencilMode: isPencilMode,
            wasPaused: isPaused
        )
        
        modelContext.insert(game)
        syncMonitor.logSave("In-progress game saved (difficulty: \(difficulty), time: \(Int(elapsedTime))s, timestamp: \(timestamp))")
        forceSave()
        
        // Upload to CloudKit immediately with the SAME timestamp
        Task {
            do {
                try await cloudKitService.uploadGame(game, timestamp: timestamp)
            } catch {
                // Log error but don't fail the save
                syncMonitor.logError("CloudKit upload failed (saved locally): \(error.localizedDescription)")
            }
        }
    }
    
    /// Deletes the saved game.
    /// Deletes the in-progress game.
    func deleteInProgressGame() {
        let descriptor = FetchDescriptor<Game>(
            predicate: #Predicate { !$0.isCompleted }
        )
        if let games = try? modelContext.fetch(descriptor) {
            for game in games {
                modelContext.delete(game)
            }
            syncMonitor.logDelete("In-progress game deleted")
            forceSave()
            
            // Also delete from CloudKit
            Task {
                try? await cloudKitService.deleteInProgressGame()
            }
        }
    }
    
    /// Checks if an in-progress game exists.
    ///
    /// - Returns: True if an in-progress game exists, false otherwise.
    func hasInProgressGame() -> Bool {
        let descriptor = FetchDescriptor<Game>(
            predicate: #Predicate { !$0.isCompleted }
        )
        let count = (try? modelContext.fetchCount(descriptor)) ?? 0
        return count > 0
    }
    
    // MARK: - CloudKit Sync
    
    /// Downloads the latest in-progress game from CloudKit and updates local storage.
    ///
    /// This should be called when the app comes to foreground to get the latest
    /// data from other devices.
    func syncInProgressGameFromCloudKit() async -> Game? {
        do {
            guard let cloudKitGame = try await cloudKitService.downloadInProgressGame() else {
                syncMonitor.logSync("No in-progress game in CloudKit")
                return nil
            }
            
            // Check if we need to update local storage
            let localGame = fetchInProgressGame()
            
            // If CloudKit is newer, update local
            if localGame == nil || cloudKitGame.lastSaved > localGame!.lastSaved {
                syncMonitor.logSync("CloudKit has newer data, updating local...")
                
                if let existingGame = localGame {
                    // Update existing game
                    existingGame.initialBoardData = cloudKitGame.initialBoardData
                    existingGame.solutionData = cloudKitGame.solutionData
                    existingGame.boardData = cloudKitGame.boardData
                    existingGame.notesData = cloudKitGame.notesData
                    existingGame.difficulty = cloudKitGame.difficulty
                    existingGame.elapsedTime = cloudKitGame.elapsedTime
                    existingGame.startDate = cloudKitGame.startDate
                    existingGame.mistakes = cloudKitGame.mistakes
                    existingGame.hintsData = cloudKitGame.hintsData
                    existingGame.isDailyChallenge = cloudKitGame.isDailyChallenge
                    existingGame.dailyChallengeDate = cloudKitGame.dailyChallengeDate
                    existingGame.lastSaved = cloudKitGame.lastSaved
                    // UI state
                    existingGame.selectedCellRow = cloudKitGame.selectedCellRow
                    existingGame.selectedCellCol = cloudKitGame.selectedCellCol
                    existingGame.highlightedNumber = cloudKitGame.highlightedNumber
                    existingGame.isPencilMode = cloudKitGame.isPencilMode
                    existingGame.wasPaused = cloudKitGame.wasPaused
                    
                    try? modelContext.save()
                    syncMonitor.logSync("✅ Local game updated from CloudKit")
                    
                    return existingGame
                } else {
                    // Create new game with fixed ID
                    let game = Game(
                        initialBoardData: cloudKitGame.initialBoardData,
                        solutionData: cloudKitGame.solutionData,
                        boardData: cloudKitGame.boardData,
                        notesData: cloudKitGame.notesData,
                        difficulty: cloudKitGame.difficulty,
                        elapsedTime: cloudKitGame.elapsedTime,
                        startDate: cloudKitGame.startDate,
                        mistakes: cloudKitGame.mistakes,
                        hintsData: cloudKitGame.hintsData,
                        isDailyChallenge: cloudKitGame.isDailyChallenge,
                        dailyChallengeDate: cloudKitGame.dailyChallengeDate,
                        isCompleted: false,
                        completionDate: nil,
                        lastSaved: cloudKitGame.lastSaved,
                        gameID: Game.inProgressGameID,  // ✅ Use fixed ID
                        selectedCellRow: cloudKitGame.selectedCellRow,
                        selectedCellCol: cloudKitGame.selectedCellCol,
                        highlightedNumber: cloudKitGame.highlightedNumber,
                        isPencilMode: cloudKitGame.isPencilMode,
                        wasPaused: cloudKitGame.wasPaused
                    )
                    
                    modelContext.insert(game)
                    try? modelContext.save()
                    syncMonitor.logSync("✅ Local game created from CloudKit")
                    
                    return game
                }
            } else {
                syncMonitor.logSync("Local game is up to date")
                return localGame
            }
        } catch {
            syncMonitor.logError("Failed to sync from CloudKit: \(error.localizedDescription)")
            return nil
        }
    }
    
    // MARK: - Completed Games
    
    /// Saves a completed game to the history.
    ///
    /// - Parameters:
    ///   - initialBoard: The initial puzzle board.
    ///   - solution: The solution board.
    ///   - finalBoard: The final board state when completed.
    ///   - difficulty: The difficulty level.
    ///   - completionTime: Time taken to complete in seconds.
    ///   - startDate: When the game was started.
    ///   - completionDate: When the game was completed.
    ///   - mistakes: Number of mistakes made.
    ///   - hints: Grid indicating which cells had hints (9x9 grid).
    ///   - isDailyChallenge: Whether this was a daily challenge.
    ///   - dailyChallengeDate: The date string for daily challenges.
    func saveCompletedGame(
        initialBoard: [[Int]],
        solution: [[Int]],
        finalBoard: [[Int]],
        difficulty: String,
        completionTime: TimeInterval,
        startDate: Date,
        completionDate: Date,
        mistakes: Int,
        hints: [[Int]],
        isDailyChallenge: Bool,
        dailyChallengeDate: String?
    ) {
        let initialBoardData = Game.flatten(initialBoard)
        let solutionData = Game.flatten(solution)
        let finalBoardData = Game.flatten(finalBoard)
        let hintsData = Game.flatten(hints)
        
        let timestamp = Date()
        
        let completedGame = Game(
            initialBoardData: initialBoardData,
            solutionData: solutionData,
            boardData: finalBoardData,
            notesData: Data(), // No notes for completed games
            difficulty: difficulty,
            elapsedTime: completionTime,
            startDate: startDate,
            mistakes: mistakes,
            hintsData: hintsData,
            isDailyChallenge: isDailyChallenge,
            dailyChallengeDate: dailyChallengeDate,
            isCompleted: true,
            completionDate: completionDate,
            lastSaved: timestamp
        )
        
        modelContext.insert(completedGame)
        syncMonitor.logSave("Completed game saved (difficulty: \(difficulty), time: \(Int(completionTime))s, hints: \(completedGame.hintsUsed))")
        forceSave()
        
        // Upload to CloudKit immediately with the SAME timestamp
        Task {
            do {
                try await cloudKitService.uploadGame(completedGame, timestamp: timestamp)
            } catch {
                // Log error but don't fail the save
                syncMonitor.logError("CloudKit upload failed (saved locally): \(error.localizedDescription)")
            }
        }
    }
    
    /// Fetches all completed games, sorted by completion date (most recent first).
    ///
    /// - Returns: Array of completed games.
    func fetchCompletedGames() -> [Game] {
        let descriptor = FetchDescriptor<Game>(
            predicate: #Predicate { $0.isCompleted },
            sortBy: [SortDescriptor(\.completionDate, order: .reverse)]
        )
        
        return (try? modelContext.fetch(descriptor)) ?? []
    }
    
    /// Fetches completed games with optional filters.
    ///
    /// - Parameters:
    ///   - difficulty: Optional difficulty filter.
    ///   - isDailyChallenge: Optional daily challenge filter.
    ///   - limit: Maximum number of games to return.
    /// - Returns: Array of completed games.
    func fetchCompletedGames(
        difficulty: String? = nil,
        isDailyChallenge: Bool? = nil,
        limit: Int? = nil
    ) -> [Game] {
        var predicates: [Predicate<Game>] = [#Predicate { $0.isCompleted }]
        
        if let difficulty = difficulty {
            predicates.append(#Predicate { $0.difficulty == difficulty })
        }
        
        if let isDailyChallenge = isDailyChallenge {
            predicates.append(#Predicate { $0.isDailyChallenge == isDailyChallenge })
        }
        
        // Combine predicates with AND logic
        let combinedPredicate: Predicate<Game>
        if predicates.count == 1 {
            combinedPredicate = predicates[0]
        } else {
            combinedPredicate = predicates.reduce(predicates[0]) { result, predicate in
                #Predicate<Game> { game in
                    result.evaluate(game) && predicate.evaluate(game)
                }
            }
        }
        
        var descriptor = FetchDescriptor<Game>(
            predicate: combinedPredicate,
            sortBy: [SortDescriptor(\.completionDate, order: .reverse)]
        )
        
        if let limit = limit {
            descriptor.fetchLimit = limit
        }
        
        return (try? modelContext.fetch(descriptor)) ?? []
    }
    
    /// Deletes a completed game from history.
    ///
    /// - Parameter game: The completed game to delete.
    func deleteCompletedGame(_ game: Game) {
        modelContext.delete(game)
        syncMonitor.logDelete("Completed game deleted (gameID: \(game.gameID))")
        forceSave()
        
        // Also delete from CloudKit
        Task {
            try? await cloudKitService.deleteGame(gameID: game.gameID)
        }
    }
    
    /// Deletes all completed games from history.
    func deleteAllCompletedGames() {
        let descriptor = FetchDescriptor<Game>(
            predicate: #Predicate { $0.isCompleted }
        )
        if let games = try? modelContext.fetch(descriptor) {
            for game in games {
                modelContext.delete(game)
                
                // Also delete from CloudKit
                Task {
                    try? await cloudKitService.deleteGame(gameID: game.gameID)
                }
            }
            syncMonitor.logDelete("All completed games deleted (\(games.count) games)")
            forceSave()
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
