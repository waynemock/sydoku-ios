//
//  CloudKitService.swift
//  Sydoku
//
//  Created by Wayne Mock on 12/19/25.
//

import Foundation
internal import CloudKit

/// Service for manual CloudKit sync operations.
///
/// This service provides explicit control over CloudKit sync, bypassing SwiftData's
/// unreliable automatic sync. It manually uploads and downloads records to ensure
/// reliable cross-device synchronization.
class CloudKitService {
    /// The CloudKit container.
    private let container = CKContainer.default()
    
    /// The private database for user data.
    private var database: CKDatabase {
        container.privateCloudDatabase
    }
    
    /// Sync monitor for logging.
    private let syncMonitor: CloudKitSyncMonitor
    
    /// Record types
    private enum RecordType {
        static let game = "Game"
        static let statistics = "Statistics"
        static let settings = "Settings"
    }
    
    /// Record IDs for singleton records
    private enum RecordID {
        static let statistics = "user-statistics"
        static let settings = "user-settings"
    }
    
    init(syncMonitor: CloudKitSyncMonitor) {
        self.syncMonitor = syncMonitor
    }
    
    // MARK: - Logging Helpers
    
    /// Logs to sync monitor on main actor.
    private func logSync(_ message: String) {
        Task { @MainActor in
            syncMonitor.logSync(message)
        }
    }
    
    /// Logs an error to sync monitor on main actor.
    private func logError(_ message: String) {
        Task { @MainActor in
            syncMonitor.logError(message)
        }
    }
    
    // MARK: - Game Management
    
    /// Uploads a game (in-progress or completed) to CloudKit.
    func uploadGame(_ game: Game, timestamp: Date) async throws {
        // Always use the gameID as the record name (no special handling for in-progress vs completed)
        let recordName = game.gameID
        let logType = game.isCompleted ? "completed game" : "in-progress game"
        
        logSync("Uploading \(logType) to CloudKit (gameID: \(recordName))...")
        
        let recordID = CKRecord.ID(recordName: recordName)
        
        // Try to fetch existing record first, create new if it doesn't exist
        let record: CKRecord
        do {
            record = try await database.record(for: recordID)
            logSync("Updating existing \(logType) record")
        } catch let error as CKError where error.code == .unknownItem {
            // Record doesn't exist yet, create new one
            record = CKRecord(recordType: RecordType.game, recordID: recordID)
            logSync("Creating new \(logType) record")
        } catch {
            logError("Failed to fetch \(logType) record: \(error.localizedDescription)")
            throw error
        }
        
        // Update record fields - use the provided timestamp to stay in sync with local
        record["initialBoardData"] = game.initialBoardData as CKRecordValue
        record["solutionData"] = game.solutionData as CKRecordValue
        record["boardData"] = game.boardData as CKRecordValue
        record["notesData"] = game.notesData as CKRecordValue
        record["difficulty"] = game.difficulty as CKRecordValue
        record["elapsedTime"] = game.elapsedTime as CKRecordValue
        record["startDate"] = game.startDate as CKRecordValue
        record["mistakes"] = game.mistakes as CKRecordValue
        record["hintsData"] = game.hintsData as CKRecordValue
        record["isDailyChallenge"] = (game.isDailyChallenge ? 1 : 0) as CKRecordValue
        record["dailyChallengeDate"] = (game.dailyChallengeDate ?? "") as CKRecordValue
        record["isCompleted"] = (game.isCompleted ? 1 : 0) as CKRecordValue
        record["completionDate"] = (game.completionDate as Date?) as CKRecordValue?
        record["lastSaved"] = timestamp as CKRecordValue
        record["gameID"] = game.gameID as CKRecordValue
        
        // UI state (stored for both, but only meaningful for in-progress games)
        record["selectedCellRow"] = (game.selectedCellRow ?? -1) as CKRecordValue  // Use -1 for nil
        record["selectedCellCol"] = (game.selectedCellCol ?? -1) as CKRecordValue
        record["highlightedNumber"] = (game.highlightedNumber ?? 0) as CKRecordValue  // Use 0 for nil
        record["isPencilMode"] = (game.isPencilMode ? 1 : 0) as CKRecordValue
        record["wasPaused"] = (game.wasPaused ? 1 : 0) as CKRecordValue
        record["undoStackData"] = game.undoStackData as CKRecordValue
        record["redoStackData"] = game.redoStackData as CKRecordValue
        
        do {
            _ = try await database.save(record)
            logSync("✅ \(logType.capitalized) uploaded successfully (gameID: \(recordName), timestamp: \(timestamp))")
        } catch {
            logError("Failed to upload \(logType): \(error.localizedDescription)")
            throw error
        }
    }
    
    /// Downloads all in-progress games from CloudKit (not completed).
    func downloadInProgressGames() async throws -> [CloudKitGame] {
        logSync("Downloading in-progress games from CloudKit...")
        
        // Query for games where isCompleted == 0
        let predicate = NSPredicate(format: "isCompleted == 0")
        let query = CKQuery(recordType: RecordType.game, predicate: predicate)
        query.sortDescriptors = [NSSortDescriptor(key: "lastSaved", ascending: false)]
        
        do {
            let (matchResults, _) = try await database.records(matching: query)
            
            var games: [CloudKitGame] = []
            
            for (_, result) in matchResults {
                switch result {
                case .success(let record):
                    if let game = parseGameRecord(record, isCompleted: false) {
                        games.append(game)
                    }
                case .failure(let error):
                    logError("Failed to fetch game record: \(error.localizedDescription)")
                }
            }
            
            logSync("✅ Downloaded \(games.count) in-progress games from CloudKit")
            return games
        } catch {
            logError("Failed to download in-progress games: \(error.localizedDescription)")
            throw error
        }
    }
    
    /// Downloads a specific game by its ID from CloudKit.
    func downloadGameByID(_ gameID: String) async throws -> CloudKitGame? {
        logSync("Downloading game by ID: \(gameID)...")
        
        let recordID = CKRecord.ID(recordName: gameID)
        
        do {
            let record = try await database.record(for: recordID)
            let isCompletedInt = record["isCompleted"] as? Int ?? 0
            
            if let game = parseGameRecord(record, isCompleted: isCompletedInt == 1) {
                logSync("✅ Downloaded game (gameID: \(gameID), isCompleted: \(game.isCompleted))")
                return game
            } else {
                logError("Failed to parse game record for ID: \(gameID)")
                return nil
            }
        } catch let error as CKError where error.code == .unknownItem {
            logSync("Game not found in CloudKit (gameID: \(gameID))")
            return nil
        } catch {
            logError("Failed to download game: \(error.localizedDescription)")
            throw error
        }
    }
    
    /// Downloads all games (both in-progress and completed) from CloudKit.
    func downloadAllGames() async throws -> [CloudKitGame] {
        logSync("Downloading all games from CloudKit...")
        
        // Query for all game records
        let predicate = NSPredicate(value: true) // Get all games
        let query = CKQuery(recordType: RecordType.game, predicate: predicate)
        query.sortDescriptors = [NSSortDescriptor(key: "lastSaved", ascending: false)]
        
        do {
            let (matchResults, _) = try await database.records(matching: query)
            
            var games: [CloudKitGame] = []
            
            for (_, result) in matchResults {
                switch result {
                case .success(let record):
                    let isCompletedInt = record["isCompleted"] as? Int ?? 0
                    if let game = parseGameRecord(record, isCompleted: isCompletedInt == 1) {
                        games.append(game)
                    }
                case .failure(let error):
                    logError("Failed to fetch game record: \(error.localizedDescription)")
                }
            }
            
            logSync("✅ Downloaded \(games.count) games from CloudKit (\(games.filter { !$0.isCompleted }.count) in-progress, \(games.filter { $0.isCompleted }.count) completed)")
            return games
        } catch {
            logError("Failed to download games: \(error.localizedDescription)")
            throw error
        }
    }
    
    /// Downloads all completed games from CloudKit.
    func downloadCompletedGames() async throws -> [CloudKitGame] {
        logSync("Downloading completed games from CloudKit...")
        
        // Query for all completed games
        let predicate = NSPredicate(format: "isCompleted == 1")
        let query = CKQuery(recordType: RecordType.game, predicate: predicate)
        // Use lastSaved instead of completionDate for sorting to avoid schema issues
        // (completionDate might not exist in CloudKit schema yet)
        query.sortDescriptors = [NSSortDescriptor(key: "lastSaved", ascending: false)]
        
        do {
            let (matchResults, _) = try await database.records(matching: query)
            
            var games: [CloudKitGame] = []
            
            for (_, result) in matchResults {
                switch result {
                case .success(let record):
                    if let game = parseGameRecord(record, isCompleted: true) {
                        games.append(game)
                    }
                case .failure(let error):
                    logError("Failed to fetch game record: \(error.localizedDescription)")
                }
            }
            
            logSync("✅ Downloaded \(games.count) completed games from CloudKit")
            return games
        } catch {
            logError("Failed to download completed games: \(error.localizedDescription)")
            throw error
        }
    }
    
    /// Helper to parse a game record from CloudKit.
    private func parseGameRecord(_ record: CKRecord, isCompleted: Bool) -> CloudKitGame? {
        guard let initialBoardData = record["initialBoardData"] as? [Int],
              let solutionData = record["solutionData"] as? [Int],
              let boardData = record["boardData"] as? [Int],
              let notesData = record["notesData"] as? Data,
              let difficulty = record["difficulty"] as? String,
              let elapsedTime = record["elapsedTime"] as? Double,
              let startDate = record["startDate"] as? Date,
              let mistakes = record["mistakes"] as? Int,
              let hintsData = record["hintsData"] as? [Int],
              let isDailyChallengeInt = record["isDailyChallenge"] as? Int,
              let lastSaved = record["lastSaved"] as? Date,
              let gameID = record["gameID"] as? String else {
            logError("Failed to parse game record")
            return nil
        }
        
        let dailyChallengeDate = record["dailyChallengeDate"] as? String
        let isDailyChallenge = isDailyChallengeInt == 1
        let completionDate = record["completionDate"] as? Date
        
        // UI state fields (only for in-progress games)
        var selectedCellRow: Int? = nil
        var selectedCellCol: Int? = nil
        var highlightedNumber: Int? = nil
        var isPencilMode = false
        var wasPaused = false
        var undoStackData = Data()
        var redoStackData = Data()
        
        if !isCompleted {
            selectedCellRow = record["selectedCellRow"] as? Int
            selectedCellCol = record["selectedCellCol"] as? Int
            highlightedNumber = record["highlightedNumber"] as? Int
            isPencilMode = (record["isPencilMode"] as? Int ?? 0) == 1
            wasPaused = (record["wasPaused"] as? Int ?? 0) == 1
            undoStackData = (record["undoStackData"] as? Data) ?? Data()
            redoStackData = (record["redoStackData"] as? Data) ?? Data()
        }
        
        return CloudKitGame(
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
            dailyChallengeDate: (dailyChallengeDate?.isEmpty == false) ? dailyChallengeDate : nil,
            isCompleted: isCompleted,
            completionDate: completionDate,
            lastSaved: lastSaved,
            gameID: gameID,
            selectedCellRow: (selectedCellRow == -1) ? nil : selectedCellRow,
            selectedCellCol: (selectedCellCol == -1) ? nil : selectedCellCol,
            highlightedNumber: (highlightedNumber == 0) ? nil : highlightedNumber,
            isPencilMode: isPencilMode,
            wasPaused: wasPaused,
            undoStackData: undoStackData,
            redoStackData: redoStackData
        )
    }
    
    /// Deletes a completed game from CloudKit by its gameID.
    func deleteGame(gameID: String) async throws {
        logSync("Deleting game \(gameID) from CloudKit...")
        
        let recordID = CKRecord.ID(recordName: gameID)
        
        do {
            _ = try await database.deleteRecord(withID: recordID)
            logSync("✅ Game \(gameID) deleted from CloudKit")
        } catch let error as CKError where error.code == .unknownItem {
            // Already deleted, that's fine
            logSync("Game \(gameID) already deleted")
        } catch {
            logError("Failed to delete game \(gameID): \(error.localizedDescription)")
            throw error
        }
    }
    
    // MARK: - Statistics
    
    /// Uploads statistics to CloudKit.
    func uploadStatistics(_ stats: GameStatistics, timestamp: Date) async throws {
        logSync("Uploading statistics to CloudKit...")
        
        let recordID = CKRecord.ID(recordName: RecordID.statistics)
        
        // Try to fetch existing record first, create new if it doesn't exist
        let record: CKRecord
        do {
            record = try await database.record(for: recordID)
            logSync("Updating existing statistics record")
        } catch let error as CKError where error.code == .unknownItem {
            // Record doesn't exist yet, create new one
            record = CKRecord(recordType: RecordType.statistics, recordID: recordID)
            logSync("Creating new statistics record")
        } catch {
            logError("Failed to fetch statistics record: \(error.localizedDescription)")
            throw error
        }
        
        // Convert dictionaries to JSON for CloudKit storage
        let encoder = JSONEncoder()
        
        let gamesPlayedData = try encoder.encode(stats.gamesPlayed)
        let gamesCompletedData = try encoder.encode(stats.gamesCompleted)
        let bestTimesData = try encoder.encode(stats.bestTimes)
        let dailiesCompletedData = try encoder.encode(stats.dailiesCompleted)
        let bestDailyTimesData = try encoder.encode(stats.bestDailyTimes)
        let totalDailyTimesData = try encoder.encode(stats.totalDailyTimes)
        
        // Update record fields - use the provided timestamp to stay in sync with local
        record["gamesPlayedJSON"] = gamesPlayedData as CKRecordValue
        record["gamesCompletedJSON"] = gamesCompletedData as CKRecordValue
        record["bestTimesJSON"] = bestTimesData as CKRecordValue
        record["totalTime"] = stats.totalTime as CKRecordValue
        record["currentStreak"] = stats.currentStreak as CKRecordValue
        record["bestStreak"] = stats.bestStreak as CKRecordValue
        record["dailiesCompletedJSON"] = dailiesCompletedData as CKRecordValue
        record["bestDailyTimesJSON"] = bestDailyTimesData as CKRecordValue
        record["totalDailyTimesJSON"] = totalDailyTimesData as CKRecordValue
        record["currentDailyStreak"] = stats.currentDailyStreak as CKRecordValue
        record["bestDailyStreak"] = stats.bestDailyStreak as CKRecordValue
        record["lastDailyCompletionDate"] = stats.lastDailyCompletionDate as CKRecordValue
        record["perfectDays"] = stats.perfectDays as CKRecordValue
        record["lastUpdated"] = timestamp as CKRecordValue
        
        do {
            _ = try await database.save(record)
            logSync("✅ Statistics uploaded successfully (timestamp: \(timestamp))")
        } catch {
            logError("Failed to upload statistics: \(error.localizedDescription)")
            throw error
        }
    }
    
    /// Downloads statistics from CloudKit.
    func downloadStatistics() async throws -> GameStatistics? {
        logSync("Downloading statistics from CloudKit...")
        
        let recordID = CKRecord.ID(recordName: RecordID.statistics)
        
        do {
            let record = try await database.record(for: recordID)
            let decoder = JSONDecoder()
            
            guard let gamesPlayedData = record["gamesPlayedJSON"] as? Data,
                  let gamesCompletedData = record["gamesCompletedJSON"] as? Data,
                  let bestTimesData = record["bestTimesJSON"] as? Data,
                  let totalTime = record["totalTime"] as? Double,
                  let currentStreak = record["currentStreak"] as? Int,
                  let bestStreak = record["bestStreak"] as? Int,
                  let dailiesCompletedData = record["dailiesCompletedJSON"] as? Data,
                  let bestDailyTimesData = record["bestDailyTimesJSON"] as? Data,
                  let totalDailyTimesData = record["totalDailyTimesJSON"] as? Data,
                  let currentDailyStreak = record["currentDailyStreak"] as? Int,
                  let bestDailyStreak = record["bestDailyStreak"] as? Int,
                  let lastDailyCompletionDate = record["lastDailyCompletionDate"] as? String,
                  let perfectDays = record["perfectDays"] as? Int,
                  let lastUpdated = record["lastUpdated"] as? Date else {
                logError("Failed to parse statistics record")
                return nil
            }
            
            let stats = GameStatistics(
                gamesPlayed: try decoder.decode([String: Int].self, from: gamesPlayedData),
                gamesCompleted: try decoder.decode([String: Int].self, from: gamesCompletedData),
                bestTimes: try decoder.decode([String: TimeInterval].self, from: bestTimesData),
                totalTime: totalTime,
                currentStreak: currentStreak,
                bestStreak: bestStreak,
                dailiesCompleted: try decoder.decode([String: Int].self, from: dailiesCompletedData),
                bestDailyTimes: try decoder.decode([String: TimeInterval].self, from: bestDailyTimesData),
                totalDailyTimes: try decoder.decode([String: TimeInterval].self, from: totalDailyTimesData),
                currentDailyStreak: currentDailyStreak,
                bestDailyStreak: bestDailyStreak,
                lastDailyCompletionDate: lastDailyCompletionDate,
                perfectDays: perfectDays,
                lastUpdated: lastUpdated
            )
            
            logSync("✅ Statistics downloaded (updated: \(lastUpdated))")
            return stats
        } catch let error as CKError where error.code == .unknownItem {
            logSync("No statistics found in CloudKit")
            return nil
        } catch {
            logError("Failed to download statistics: \(error.localizedDescription)")
            throw error
        }
    }
    
    // MARK: - Settings
    
    /// Uploads settings to CloudKit.
    func uploadSettings(_ settings: UserSettings, timestamp: Date) async throws {
        logSync("Uploading settings to CloudKit...")
        
        let recordID = CKRecord.ID(recordName: RecordID.settings)
        
        // Try to fetch existing record first, create new if it doesn't exist
        let record: CKRecord
        do {
            // Fetch with proper async/await
            record = try await database.record(for: recordID)
            logSync("Updating existing settings record")
        } catch let error as CKError where error.code == .unknownItem {
            // Record doesn't exist yet, create new one
            record = CKRecord(recordType: RecordType.settings, recordID: recordID)
            logSync("Creating new settings record")
        } catch {
            logError("Failed to fetch settings record: \(error.localizedDescription)")
            throw error
        }
        
        // Convert dictionary to JSON for CloudKit storage
        let encoder = JSONEncoder()
        let completedDailyChallengesData = try encoder.encode(settings.completedDailyChallenges)
        
        // Update record fields - use the provided timestamp to stay in sync with local
        record["autoErrorChecking"] = (settings.autoErrorChecking ? 1 : 0) as CKRecordValue
        record["mistakeLimit"] = settings.mistakeLimit as CKRecordValue
        record["hapticFeedback"] = (settings.hapticFeedback ? 1 : 0) as CKRecordValue
        record["soundEffects"] = (settings.soundEffects ? 1 : 0) as CKRecordValue
        record["highlightSameNumbers"] = (settings.highlightSameNumbers ? 1 : 0) as CKRecordValue
        record["completedDailyChallengesJSON"] = completedDailyChallengesData as CKRecordValue
        record["themeTypeRawValue"] = settings.themeTypeRawValue as CKRecordValue
        record["preferredColorSchemeRawValue"] = settings.preferredColorSchemeRawValue as CKRecordValue
        record["lastUpdated"] = timestamp as CKRecordValue
        
        do {
            _ = try await database.save(record)
            logSync("✅ Settings uploaded successfully (timestamp: \(timestamp), theme: \(settings.themeTypeRawValue))")
        } catch {
            logError("Failed to upload settings: \(error.localizedDescription)")
            throw error
        }
    }
    
    /// Downloads settings from CloudKit.
    func downloadSettings() async throws -> UserSettings? {
        logSync("Downloading settings from CloudKit...")
        
        let recordID = CKRecord.ID(recordName: RecordID.settings)
        
        do {
            let record = try await database.record(for: recordID)
            let decoder = JSONDecoder()
            
            guard let autoErrorCheckingInt = record["autoErrorChecking"] as? Int,
                  let mistakeLimit = record["mistakeLimit"] as? Int,
                  let hapticFeedbackInt = record["hapticFeedback"] as? Int,
                  let soundEffectsInt = record["soundEffects"] as? Int,
                  let highlightSameNumbersInt = record["highlightSameNumbers"] as? Int,
                  let completedDailyChallengesData = record["completedDailyChallengesJSON"] as? Data,
                  let themeTypeRawValue = record["themeTypeRawValue"] as? String,
                  let preferredColorSchemeRawValue = record["preferredColorSchemeRawValue"] as? String,
                  let lastUpdated = record["lastUpdated"] as? Date else {
                logError("Failed to parse settings record")
                return nil
            }
            
            let settings = UserSettings(
                autoErrorChecking: autoErrorCheckingInt == 1,
                mistakeLimit: mistakeLimit,
                hapticFeedback: hapticFeedbackInt == 1,
                soundEffects: soundEffectsInt == 1,
                highlightSameNumbers: highlightSameNumbersInt == 1,
                completedDailyChallenges: try decoder.decode([String: String].self, from: completedDailyChallengesData),
                themeTypeRawValue: themeTypeRawValue,
                preferredColorSchemeRawValue: preferredColorSchemeRawValue,
                lastUpdated: lastUpdated
            )
            
            logSync("✅ Settings downloaded (updated: \(lastUpdated), theme: \(themeTypeRawValue))")
            return settings
        } catch let error as CKError where error.code == .unknownItem {
            logSync("No settings found in CloudKit")
            return nil
        } catch {
            logError("Failed to download settings: \(error.localizedDescription)")
            throw error
        }
    }
}

// MARK: - Data Models

/// CloudKit representation of a game (in-progress or completed).
struct CloudKitGame {
    let initialBoardData: [Int]
    let solutionData: [Int]
    let boardData: [Int]
    let notesData: Data
    let difficulty: String
    let elapsedTime: TimeInterval
    let startDate: Date
    let mistakes: Int
    let hintsData: [Int]
    let isDailyChallenge: Bool
    let dailyChallengeDate: String?
    let isCompleted: Bool
    let completionDate: Date?
    let lastSaved: Date
    let gameID: String
    
    // UI state for seamless resume (in-progress games only)
    let selectedCellRow: Int?
    let selectedCellCol: Int?
    let highlightedNumber: Int?
    let isPencilMode: Bool
    let wasPaused: Bool
    let undoStackData: Data
    let redoStackData: Data
}
