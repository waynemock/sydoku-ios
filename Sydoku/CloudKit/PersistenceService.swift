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
    
    /// Fetches a game by its unique ID (checks both in-progress and completed games).
    ///
    /// - Parameter gameID: The unique identifier of the game.
    /// - Returns: The game if found, or nil if it doesn't exist locally.
    func fetchGame(byID gameID: String) -> Game? {
        let descriptor = FetchDescriptor<Game>(
            predicate: #Predicate { $0.gameID == gameID }
        )
        
        return try? modelContext.fetch(descriptor).first
    }
    
    /// Saves the current in-progress game state.
    ///
    /// Uses upsert logic: updates existing game or creates new one.
    /// The gameID should be provided to track the same game across multiple saves.
    ///
    /// - Parameters:
    ///   - gameID: The unique identifier for this game (pass existing ID to update, or nil to create new).
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
    /// - Returns: The gameID of the saved game (useful for tracking new games).
    @discardableResult
    func saveInProgressGame(
        gameID: String? = nil,
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
        isPaused: Bool,
        undoStack: [GameState] = [],
        redoStack: [GameState] = []
    ) -> String {
        // Validate that the board is not empty before saving
        // This prevents saving invalid game states
        let hasAnyValues = board.flatMap { $0 }.contains { $0 != 0 }
        if !hasAnyValues {
            syncMonitor.logError("❌ Prevented saving empty board")
            // Return existing gameID or generate new one, but don't save
            return gameID ?? UUID().uuidString
        }
        
        let notesData = Game.encodeNotes(notes)
        let boardData = Game.flatten(board)
        let solutionData = Game.flatten(solution)
        let initialBoardData = Game.flatten(initialBoard)
        let hintsData = Game.flatten(hints)
        let undoStackData = Game.encodeGameStateStack(undoStack)
        let redoStackData = Game.encodeGameStateStack(redoStack)
        let timestamp = Date()
        
        // If gameID provided, try to find and update existing game (upsert)
        if let gameID = gameID {
            let descriptor = FetchDescriptor<Game>(
                predicate: #Predicate<Game> { game in
                    game.gameID == gameID
                }
            )
            
            if let existingGame = try? modelContext.fetch(descriptor).first {
                // Update existing game
                existingGame.boardData = boardData
                existingGame.notesData = notesData
                existingGame.elapsedTime = elapsedTime
                existingGame.mistakes = mistakes
                existingGame.hintsData = hintsData
                existingGame.lastSaved = timestamp
                existingGame.selectedCellRow = selectedCell?.row
                existingGame.selectedCellCol = selectedCell?.col
                existingGame.highlightedNumber = highlightedNumber
                existingGame.isPencilMode = isPencilMode
                existingGame.wasPaused = isPaused
                existingGame.undoStackData = undoStackData
                existingGame.redoStackData = redoStackData
                
                syncMonitor.logSave("In-progress game updated (gameID: \(gameID), time: \(Int(elapsedTime))s)")
                forceSave()
                
                // Upload to CloudKit
                Task {
                    do {
                        try await cloudKitService.uploadGame(existingGame, timestamp: timestamp)
                    } catch {
                        syncMonitor.logError("CloudKit upload failed (saved locally): \(error.localizedDescription)")
                    }
                }
                
                return gameID
            }
        }
        
        // Create new game (either no gameID provided, or gameID not found)
        let newGameID = gameID ?? UUID().uuidString
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
            gameID: newGameID,
            selectedCellRow: selectedCell?.row,
            selectedCellCol: selectedCell?.col,
            highlightedNumber: highlightedNumber,
            isPencilMode: isPencilMode,
            wasPaused: isPaused,
            undoStackData: undoStackData,
            redoStackData: redoStackData
        )
        
        modelContext.insert(game)
        syncMonitor.logSave("In-progress game created (gameID: \(newGameID), difficulty: \(difficulty), time: \(Int(elapsedTime))s)")
        forceSave()
        
        // Upload to CloudKit
        Task {
            do {
                try await cloudKitService.uploadGame(game, timestamp: timestamp)
            } catch {
                syncMonitor.logError("CloudKit upload failed (saved locally): \(error.localizedDescription)")
            }
        }
        
        return newGameID
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
    
    /// Syncs a specific game by ID from CloudKit.
    ///
    /// This is more efficient than downloading all in-progress games when we already
    /// know which game we're looking for. It checks if the game is still in-progress
    /// or was completed on another device.
    ///
    /// - Parameter gameID: The unique identifier of the game to sync.
    /// - Returns: A tuple containing the game and a boolean indicating if it was completed on another device.
    func syncGameFromCloudKit(gameID: String) async -> (game: Game?, wasCompletedOnAnotherDevice: Bool) {
        do {
            guard let cloudKitGame = try await cloudKitService.downloadGameByID(gameID) else {
                syncMonitor.logSync("Game not found in CloudKit (gameID: \(gameID))")
                return (nil, false)
            }
            
            // Check if the game was completed on another device
            if cloudKitGame.isCompleted {
                syncMonitor.logSync("⚠️ Game was completed on another device (gameID: \(gameID))")
                
                // Check if we have this game locally
                if let localGame = fetchGame(byID: gameID) {
                    // Update local game to completed state
                    localGame.boardData = cloudKitGame.boardData
                    localGame.elapsedTime = cloudKitGame.elapsedTime
                    localGame.mistakes = cloudKitGame.mistakes
                    localGame.hintsData = cloudKitGame.hintsData
                    localGame.isCompleted = true
                    localGame.completionDate = cloudKitGame.completionDate
                    localGame.lastSaved = cloudKitGame.lastSaved
                    localGame.notesData = Data()
                    localGame.selectedCellRow = nil
                    localGame.selectedCellCol = nil
                    localGame.highlightedNumber = nil
                    localGame.isPencilMode = false
                    localGame.wasPaused = false
                    localGame.undoStackData = Data()
                    localGame.redoStackData = Data()
                    
                    try? modelContext.save()
                    syncMonitor.logSync("✅ Local game updated to completed state")
                    
                    return (localGame, true)
                } else {
                    // Game doesn't exist locally, create it as completed
                    let game = Game(
                        initialBoardData: cloudKitGame.initialBoardData,
                        solutionData: cloudKitGame.solutionData,
                        boardData: cloudKitGame.boardData,
                        notesData: Data(),
                        difficulty: cloudKitGame.difficulty,
                        elapsedTime: cloudKitGame.elapsedTime,
                        startDate: cloudKitGame.startDate,
                        mistakes: cloudKitGame.mistakes,
                        hintsData: cloudKitGame.hintsData,
                        isDailyChallenge: cloudKitGame.isDailyChallenge,
                        dailyChallengeDate: cloudKitGame.dailyChallengeDate,
                        isCompleted: true,
                        completionDate: cloudKitGame.completionDate ?? Date(),
                        lastSaved: cloudKitGame.lastSaved,
                        gameID: cloudKitGame.gameID,
                        selectedCellRow: nil,
                        selectedCellCol: nil,
                        highlightedNumber: nil,
                        isPencilMode: false,
                        wasPaused: false,
                        undoStackData: Data(),
                        redoStackData: Data()
                    )
                    
                    modelContext.insert(game)
                    try? modelContext.save()
                    syncMonitor.logSync("✅ Completed game added to local storage")
                    
                    return (game, true)
                }
            } else {
                // Game is still in progress - update or create local copy
                if let localGame = fetchGame(byID: gameID) {
                    // Compare timestamps to see which is newer
                    if cloudKitGame.lastSaved > localGame.lastSaved {
                        syncMonitor.logSync("CloudKit has newer data for same game, updating local...")
                        
                        // Update local game with CloudKit data
                        localGame.boardData = cloudKitGame.boardData
                        localGame.notesData = cloudKitGame.notesData
                        localGame.elapsedTime = cloudKitGame.elapsedTime
                        localGame.mistakes = cloudKitGame.mistakes
                        localGame.hintsData = cloudKitGame.hintsData
                        localGame.selectedCellRow = cloudKitGame.selectedCellRow
                        localGame.selectedCellCol = cloudKitGame.selectedCellCol
                        localGame.highlightedNumber = cloudKitGame.highlightedNumber
                        localGame.isPencilMode = cloudKitGame.isPencilMode
                        localGame.wasPaused = cloudKitGame.wasPaused
                        localGame.undoStackData = cloudKitGame.undoStackData
                        localGame.redoStackData = cloudKitGame.redoStackData
                        localGame.lastSaved = cloudKitGame.lastSaved
                        
                        try? modelContext.save()
                        syncMonitor.logSync("✅ Local game updated from CloudKit")
                    } else {
                        syncMonitor.logSync("Local game is up to date (gameID: \(gameID))")
                    }
                    
                    return (localGame, false)
                } else {
                    // Game doesn't exist locally, create it
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
                        gameID: cloudKitGame.gameID,
                        selectedCellRow: cloudKitGame.selectedCellRow,
                        selectedCellCol: cloudKitGame.selectedCellCol,
                        highlightedNumber: cloudKitGame.highlightedNumber,
                        isPencilMode: cloudKitGame.isPencilMode,
                        wasPaused: cloudKitGame.wasPaused,
                        undoStackData: cloudKitGame.undoStackData,
                        redoStackData: cloudKitGame.redoStackData
                    )
                    
                    modelContext.insert(game)
                    try? modelContext.save()
                    syncMonitor.logSync("✅ In-progress game added from CloudKit")
                    
                    return (game, false)
                }
            }
        } catch {
            syncMonitor.logError("Failed to sync game by ID: \(error.localizedDescription)")
            // Return local game if available
            if let localGame = fetchGame(byID: gameID) {
                return (localGame, false)
            }
            return (nil, false)
        }
    }
    
    /// Downloads the latest in-progress game from CloudKit and updates local storage.
    ///
    /// This should be called when the app comes to foreground to get the latest
    /// data from other devices. It queries CloudKit for all in-progress games and
    /// picks the most recently saved one.
    ///
    /// - Returns: The synced game if one exists in CloudKit, or nil if no game exists.
    func syncInProgressGameFromCloudKit() async -> Game? {
        do {
            // Download all in-progress games from CloudKit (sorted by lastSaved desc)
            let inProgressGames = try await cloudKitService.downloadInProgressGames()
            
            // Get the most recent in-progress game
            guard let cloudKitGame = inProgressGames.first else {
                syncMonitor.logSync("No in-progress games in CloudKit")
                
                // Check if local game was completed on another device
                if let localGame = fetchInProgressGame() {
                    // Try to fetch the local game by ID to see if it was completed
                    if let completedVersion = try? await cloudKitService.downloadGameByID(localGame.gameID),
                       completedVersion.isCompleted {
                        syncMonitor.logSync("⚠️ Local in-progress game was completed on another device (gameID: \(localGame.gameID))")
                        
                        // Update local game to completed
                        localGame.boardData = completedVersion.boardData
                        localGame.elapsedTime = completedVersion.elapsedTime
                        localGame.mistakes = completedVersion.mistakes
                        localGame.hintsData = completedVersion.hintsData
                        localGame.isCompleted = true
                        localGame.completionDate = completedVersion.completionDate
                        localGame.lastSaved = completedVersion.lastSaved
                        localGame.notesData = Data()
                        localGame.selectedCellRow = nil
                        localGame.selectedCellCol = nil
                        localGame.highlightedNumber = nil
                        localGame.isPencilMode = false
                        localGame.wasPaused = false
                        
                        try? modelContext.save()
                        syncMonitor.logSync("✅ Local game marked as completed from CloudKit")
                        
                        // Return nil so the app shows new game dialog
                        return nil
                    } else {
                        syncMonitor.logSync("⚠️ Local in-progress game not found in CloudKit")
                        
                        // Check if the local game is valid (has any non-zero values)
                        let board = Game.unflatten(localGame.boardData)
                        let hasAnyValues = board.flatMap { $0 }.contains { $0 != 0 }
                        
                        if !hasAnyValues {
                            syncMonitor.logSync("⚠️ Local game is empty - deleting orphaned game")
                            modelContext.delete(localGame)
                            try? modelContext.save()
                            return nil
                        }
                        
                        syncMonitor.logSync("Local game has data - keeping local copy (offline mode)")
                    }
                }
                
                return nil
            }
            
            // Get local game
            let localGame = fetchInProgressGame()
            
            // If no local game, create from CloudKit
            if localGame == nil {
                syncMonitor.logSync("Creating local game from CloudKit (gameID: \(cloudKitGame.gameID))")
                
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
                    gameID: cloudKitGame.gameID,
                    selectedCellRow: cloudKitGame.selectedCellRow,
                    selectedCellCol: cloudKitGame.selectedCellCol,
                    highlightedNumber: cloudKitGame.highlightedNumber,
                    isPencilMode: cloudKitGame.isPencilMode,
                    wasPaused: cloudKitGame.wasPaused,
                    undoStackData: cloudKitGame.undoStackData,
                    redoStackData: cloudKitGame.redoStackData
                )
                
                modelContext.insert(game)
                try? modelContext.save()
                syncMonitor.logSync("✅ Local game created from CloudKit")
                
                return game
            }
            
            // Same game - check if CloudKit is newer
            if let unwrappedLocalGame = localGame, unwrappedLocalGame.gameID == cloudKitGame.gameID {
                if cloudKitGame.lastSaved > unwrappedLocalGame.lastSaved {
                    syncMonitor.logSync("CloudKit has newer data for same game, updating local...")
                    
                    unwrappedLocalGame.boardData = cloudKitGame.boardData
                    unwrappedLocalGame.notesData = cloudKitGame.notesData
                    unwrappedLocalGame.elapsedTime = cloudKitGame.elapsedTime
                    unwrappedLocalGame.mistakes = cloudKitGame.mistakes
                    unwrappedLocalGame.hintsData = cloudKitGame.hintsData
                    unwrappedLocalGame.lastSaved = cloudKitGame.lastSaved
                    unwrappedLocalGame.selectedCellRow = cloudKitGame.selectedCellRow
                    unwrappedLocalGame.selectedCellCol = cloudKitGame.selectedCellCol
                    unwrappedLocalGame.highlightedNumber = cloudKitGame.highlightedNumber
                    unwrappedLocalGame.isPencilMode = cloudKitGame.isPencilMode
                    unwrappedLocalGame.wasPaused = cloudKitGame.wasPaused
                    unwrappedLocalGame.undoStackData = cloudKitGame.undoStackData
                    unwrappedLocalGame.redoStackData = cloudKitGame.redoStackData
                    
                    try? modelContext.save()
                    syncMonitor.logSync("✅ Local game updated from CloudKit")
                } else {
                    syncMonitor.logSync("Local game is up to date (gameID: \(unwrappedLocalGame.gameID))")
                }
                return unwrappedLocalGame
            }
            
            // Different game - CloudKit has a newer game from another device
            if let unwrappedLocalGame = localGame {
                syncMonitor.logSync("CloudKit has different game (CloudKit: \(cloudKitGame.gameID) vs Local: \(unwrappedLocalGame.gameID))")
                syncMonitor.logSync("Both games kept as in-progress - CloudKit game becomes current")
            }
            
            // Create new game from CloudKit
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
                gameID: cloudKitGame.gameID,
                selectedCellRow: cloudKitGame.selectedCellRow,
                selectedCellCol: cloudKitGame.selectedCellCol,
                highlightedNumber: cloudKitGame.highlightedNumber,
                isPencilMode: cloudKitGame.isPencilMode,
                wasPaused: cloudKitGame.wasPaused,
                undoStackData: cloudKitGame.undoStackData,
                redoStackData: cloudKitGame.redoStackData
            )
            
            modelContext.insert(game)
            try? modelContext.save()
            syncMonitor.logSync("✅ Local game replaced with CloudKit game")
            
            return game
        } catch {
            syncMonitor.logError("Failed to sync from CloudKit: \(error.localizedDescription)")
            
            // On error, return local game if available
            return fetchInProgressGame()
        }
    }
    
    // MARK: - Completed Games
    
    /// Downloads completed games from CloudKit and merges them with local storage.
    ///
    /// This should be called when the app comes to foreground to get completed games
    /// from other devices.
    func syncCompletedGamesFromCloudKit() async {
        do {
            let cloudKitGames = try await cloudKitService.downloadCompletedGames()
            
            if cloudKitGames.isEmpty {
                syncMonitor.logSync("No completed games in CloudKit")
                return
            }
            
            syncMonitor.logSync("Downloaded \(cloudKitGames.count) completed games from CloudKit")
            
            // Get all local completed game IDs for quick lookup
            let localGames = fetchCompletedGames()
            let localGameIDs = Set(localGames.map { $0.gameID })
            
            var newGamesCount = 0
            
            // Add games that don't exist locally
            for cloudGame in cloudKitGames {
                if !localGameIDs.contains(cloudGame.gameID) {
                    // This is a new game from another device
                    let game = Game(
                        initialBoardData: cloudGame.initialBoardData,
                        solutionData: cloudGame.solutionData,
                        boardData: cloudGame.boardData,
                        notesData: cloudGame.notesData,
                        difficulty: cloudGame.difficulty,
                        elapsedTime: cloudGame.elapsedTime,
                        startDate: cloudGame.startDate,
                        mistakes: cloudGame.mistakes,
                        hintsData: cloudGame.hintsData,
                        isDailyChallenge: cloudGame.isDailyChallenge,
                        dailyChallengeDate: cloudGame.dailyChallengeDate,
                        isCompleted: true,
                        completionDate: cloudGame.completionDate,
                        lastSaved: cloudGame.lastSaved,
                        gameID: cloudGame.gameID
                    )
                    
                    modelContext.insert(game)
                    newGamesCount += 1
                }
            }
            
            if newGamesCount > 0 {
                try? modelContext.save()
                syncMonitor.logSync("✅ Added \(newGamesCount) new completed games from CloudKit")
            } else {
                syncMonitor.logSync("All completed games are already synced")
            }
        } catch {
            syncMonitor.logError("Failed to sync completed games from CloudKit: \(error.localizedDescription)")
        }
    }
    
    /// Marks an in-progress game as completed.
    ///
    /// Updates the existing game record rather than creating a new one,
    /// allowing other devices to see the completion status.
    ///
    /// - Parameters:
    ///   - gameID: The unique identifier of the game being completed.
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
        gameID: String,
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
        let finalBoardData = Game.flatten(finalBoard)
        let hintsData = Game.flatten(hints)
        let timestamp = Date()
        
        // Try to find and update the existing game
        let descriptor = FetchDescriptor<Game>(
            predicate: #Predicate<Game> { game in
                game.gameID == gameID
            }
        )
        
        if let existingGame = try? modelContext.fetch(descriptor).first {
            // Update existing game to mark as completed
            existingGame.boardData = finalBoardData
            existingGame.notesData = Data() // Clear notes for completed game
            existingGame.elapsedTime = completionTime
            existingGame.mistakes = mistakes
            existingGame.hintsData = hintsData
            existingGame.isCompleted = true
            existingGame.completionDate = completionDate
            existingGame.lastSaved = timestamp
            // Clear UI state for completed games
            existingGame.selectedCellRow = nil
            existingGame.selectedCellCol = nil
            existingGame.highlightedNumber = nil
            existingGame.isPencilMode = false
            existingGame.wasPaused = false
            
            syncMonitor.logSave("Game marked as completed (gameID: \(gameID), time: \(Int(completionTime))s, hints: \(existingGame.hintsUsed))")
            forceSave()
            
            // Upload to CloudKit
            Task {
                do {
                    try await cloudKitService.uploadGame(existingGame, timestamp: timestamp)
                } catch {
                    syncMonitor.logError("CloudKit upload failed (saved locally): \(error.localizedDescription)")
                }
            }
        } else {
            // Fallback: create new completed game if no in-progress game found
            // (This handles edge cases where the game wasn't saved in-progress)
            let initialBoardData = Game.flatten(initialBoard)
            let solutionData = Game.flatten(solution)
            
            let completedGame = Game(
                initialBoardData: initialBoardData,
                solutionData: solutionData,
                boardData: finalBoardData,
                notesData: Data(),
                difficulty: difficulty,
                elapsedTime: completionTime,
                startDate: startDate,
                mistakes: mistakes,
                hintsData: hintsData,
                isDailyChallenge: isDailyChallenge,
                dailyChallengeDate: dailyChallengeDate,
                isCompleted: true,
                completionDate: completionDate,
                lastSaved: timestamp,
                gameID: gameID
            )
            
            modelContext.insert(completedGame)
            syncMonitor.logSave("Completed game created (gameID: \(gameID), time: \(Int(completionTime))s, hints: \(completedGame.hintsUsed))")
            forceSave()
            
            // Upload to CloudKit
            Task {
                do {
                    try await cloudKitService.uploadGame(completedGame, timestamp: timestamp)
                } catch {
                    syncMonitor.logError("CloudKit upload failed (saved locally): \(error.localizedDescription)")
                }
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
    
    /// Deletes a game from history.
    ///
    /// - Parameter game: The completed game to delete.
    func deleteGame(_ game: Game) {
        modelContext.delete(game)
        syncMonitor.logDelete("Completed game deleted (gameID: \(game.gameID))")
        forceSave()
        
        // Also delete from CloudKit
        Task {
            try? await cloudKitService.deleteGame(gameID: game.gameID)
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
