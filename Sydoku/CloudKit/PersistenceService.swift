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
    var syncMonitor = CloudKitSyncMonitor()
    
    /// Initializes the persistence service with a model context.
    ///
    /// - Parameter modelContext: The SwiftData model context for data operations.
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
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
        statistics.lastUpdated = Date()
        syncMonitor.logSave("Statistics updated")
        forceSave()
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
        isDailyChallenge: Bool,
        dailyChallengeDate: String?
    ) {
        // Delete any existing saved game
        deleteSavedGame()
        
        // Create new saved game
        let notesData = SavedGameState.encodeNotes(notes)
        let savedGame = SavedGameState(
            boardData: SavedGameState.flatten(board),
            notesData: notesData,
            solutionData: SavedGameState.flatten(solution),
            initialBoardData: SavedGameState.flatten(initialBoard),
            difficulty: difficulty,
            elapsedTime: elapsedTime,
            startDate: startDate,
            mistakes: mistakes,
            isDailyChallenge: isDailyChallenge,
            dailyChallengeDate: dailyChallengeDate
        )
        
        modelContext.insert(savedGame)
        syncMonitor.logSave("Game state saved (difficulty: \(difficulty), time: \(Int(elapsedTime))s)")
        forceSave()
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
        settings.lastUpdated = Date()
        syncMonitor.logSave("Settings updated")
        forceSave()
    }
}
