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
    
    /// Initializes the persistence service with a model context.
    ///
    /// - Parameter modelContext: The SwiftData model context for data operations.
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
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
            return existing
        }
        
        // Create new statistics record
        let stats = GameStatistics()
        modelContext.insert(stats)
        try? modelContext.save()
        return stats
    }
    
    /// Updates and saves statistics.
    ///
    /// - Parameter statistics: The statistics record to update.
    func saveStatistics(_ statistics: GameStatistics) {
        statistics.lastUpdated = Date()
        try? modelContext.save()
    }
    
    // MARK: - Saved Game
    
    /// Fetches the current saved game, if one exists.
    ///
    /// - Returns: The saved game state, or nil if no game is saved.
    func fetchSavedGame() -> SavedGameState? {
        let descriptor = FetchDescriptor<SavedGameState>(
            sortBy: [SortDescriptor(\.lastSaved, order: .reverse)]
        )
        
        return try? modelContext.fetch(descriptor).first
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
        try? modelContext.save()
    }
    
    /// Deletes the saved game.
    func deleteSavedGame() {
        let descriptor = FetchDescriptor<SavedGameState>()
        if let games = try? modelContext.fetch(descriptor) {
            for game in games {
                modelContext.delete(game)
            }
            try? modelContext.save()
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
            return existing
        }
        
        // Create new settings record
        let settings = UserSettings()
        modelContext.insert(settings)
        try? modelContext.save()
        return settings
    }
    
    /// Updates and saves settings.
    ///
    /// - Parameter settings: The settings record to update.
    func saveSettings(_ settings: UserSettings) {
        settings.lastUpdated = Date()
        try? modelContext.save()
    }
}
