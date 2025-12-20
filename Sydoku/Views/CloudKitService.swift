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
@MainActor
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
        static let savedGame = "SavedGame"
        static let statistics = "Statistics"
        static let settings = "Settings"
    }
    
    /// Record IDs (using fixed IDs so we update the same record)
    private enum RecordID {
        static let savedGame = "current-saved-game"
        static let statistics = "user-statistics"
        static let settings = "user-settings"
    }
    
    init(syncMonitor: CloudKitSyncMonitor) {
        self.syncMonitor = syncMonitor
    }
    
    // MARK: - Saved Game
    
    /// Uploads the current saved game to CloudKit.
    func uploadSavedGame(
        boardData: [Int],
        notesData: Data,
        solutionData: [Int],
        initialBoardData: [Int],
        difficulty: String,
        elapsedTime: TimeInterval,
        startDate: Date,
        mistakes: Int,
        isDailyChallenge: Bool,
        dailyChallengeDate: String?,
        lastSaved: Date
    ) async throws {
        syncMonitor.logSync("Uploading saved game to CloudKit...")
        
        let recordID = CKRecord.ID(recordName: RecordID.savedGame)
        
        // Try to fetch existing record first, create new if it doesn't exist
        let record: CKRecord
        do {
            record = try await database.record(for: recordID)
            syncMonitor.logSync("Updating existing saved game record")
        } catch let error as CKError where error.code == .unknownItem {
            // Record doesn't exist yet, create new one
            record = CKRecord(recordType: RecordType.savedGame, recordID: recordID)
            syncMonitor.logSync("Creating new saved game record")
        } catch {
            syncMonitor.logError("Failed to fetch saved game record: \(error.localizedDescription)")
            throw error
        }
        
        // Update record fields - use the provided timestamp to stay in sync with local
        record["boardData"] = boardData as CKRecordValue
        record["notesData"] = notesData as CKRecordValue
        record["solutionData"] = solutionData as CKRecordValue
        record["initialBoardData"] = initialBoardData as CKRecordValue
        record["difficulty"] = difficulty as CKRecordValue
        record["elapsedTime"] = elapsedTime as CKRecordValue
        record["startDate"] = startDate as CKRecordValue
        record["mistakes"] = mistakes as CKRecordValue
        let isDailyChallengeValue = isDailyChallenge ? 1 : 0
        record["isDailyChallenge"] = isDailyChallengeValue as CKRecordValue
        record["dailyChallengeDate"] = (dailyChallengeDate ?? "") as CKRecordValue
        record["lastSaved"] = lastSaved as CKRecordValue
        
        do {
            let savedRecord = try await database.save(record)
            syncMonitor.logSync("✅ Saved game uploaded successfully (timestamp: \(lastSaved))")
        } catch {
            syncMonitor.logError("Failed to upload saved game: \(error.localizedDescription)")
            throw error
        }
    }
    
    /// Downloads the current saved game from CloudKit.
    func downloadSavedGame() async throws -> CloudKitSavedGame? {
        syncMonitor.logSync("Downloading saved game from CloudKit...")
        
        let recordID = CKRecord.ID(recordName: RecordID.savedGame)
        
        do {
            let record = try await database.record(for: recordID)
            
            guard let boardData = record["boardData"] as? [Int],
                  let notesData = record["notesData"] as? Data,
                  let solutionData = record["solutionData"] as? [Int],
                  let initialBoardData = record["initialBoardData"] as? [Int],
                  let difficulty = record["difficulty"] as? String,
                  let elapsedTime = record["elapsedTime"] as? Double,
                  let startDate = record["startDate"] as? Date,
                  let mistakes = record["mistakes"] as? Int,
                  let isDailyChallengeInt = record["isDailyChallenge"] as? Int,
                  let lastSaved = record["lastSaved"] as? Date else {
                syncMonitor.logError("Failed to parse saved game record")
                return nil
            }
            
            let dailyChallengeDate = record["dailyChallengeDate"] as? String
            let isDailyChallenge = isDailyChallengeInt == 1
            
            syncMonitor.logSync("✅ Saved game downloaded (saved: \(lastSaved))")
            
            return CloudKitSavedGame(
                boardData: boardData,
                notesData: notesData,
                solutionData: solutionData,
                initialBoardData: initialBoardData,
                difficulty: difficulty,
                elapsedTime: elapsedTime,
                startDate: startDate,
                mistakes: mistakes,
                isDailyChallenge: isDailyChallenge,
                dailyChallengeDate: (dailyChallengeDate?.isEmpty == false) ? dailyChallengeDate : nil,
                lastSaved: lastSaved
            )
        } catch let error as CKError where error.code == .unknownItem {
            // No saved game exists yet
            syncMonitor.logSync("No saved game found in CloudKit")
            return nil
        } catch {
            syncMonitor.logError("Failed to download saved game: \(error.localizedDescription)")
            throw error
        }
    }
    
    /// Deletes the saved game from CloudKit.
    func deleteSavedGame() async throws {
        syncMonitor.logSync("Deleting saved game from CloudKit...")
        
        let recordID = CKRecord.ID(recordName: RecordID.savedGame)
        
        do {
            _ = try await database.deleteRecord(withID: recordID)
            syncMonitor.logSync("✅ Saved game deleted from CloudKit")
        } catch let error as CKError where error.code == .unknownItem {
            // Already deleted, that's fine
            syncMonitor.logSync("Saved game already deleted")
        } catch {
            syncMonitor.logError("Failed to delete saved game: \(error.localizedDescription)")
            throw error
        }
    }
    
    // MARK: - Statistics
    
    /// Uploads statistics to CloudKit.
    func uploadStatistics(_ stats: GameStatistics, timestamp: Date) async throws {
        syncMonitor.logSync("Uploading statistics to CloudKit...")
        
        let recordID = CKRecord.ID(recordName: RecordID.statistics)
        
        // Try to fetch existing record first, create new if it doesn't exist
        let record: CKRecord
        do {
            record = try await database.record(for: recordID)
            syncMonitor.logSync("Updating existing statistics record")
        } catch let error as CKError where error.code == .unknownItem {
            // Record doesn't exist yet, create new one
            record = CKRecord(recordType: RecordType.statistics, recordID: recordID)
            syncMonitor.logSync("Creating new statistics record")
        } catch {
            syncMonitor.logError("Failed to fetch statistics record: \(error.localizedDescription)")
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
            syncMonitor.logSync("✅ Statistics uploaded successfully (timestamp: \(timestamp))")
        } catch {
            syncMonitor.logError("Failed to upload statistics: \(error.localizedDescription)")
            throw error
        }
    }
    
    /// Downloads statistics from CloudKit.
    func downloadStatistics() async throws -> GameStatistics? {
        syncMonitor.logSync("Downloading statistics from CloudKit...")
        
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
                syncMonitor.logError("Failed to parse statistics record")
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
            
            syncMonitor.logSync("✅ Statistics downloaded (updated: \(lastUpdated))")
            return stats
        } catch let error as CKError where error.code == .unknownItem {
            syncMonitor.logSync("No statistics found in CloudKit")
            return nil
        } catch {
            syncMonitor.logError("Failed to download statistics: \(error.localizedDescription)")
            throw error
        }
    }
    
    // MARK: - Settings
    
    /// Uploads settings to CloudKit.
    func uploadSettings(_ settings: UserSettings, timestamp: Date) async throws {
        syncMonitor.logSync("Uploading settings to CloudKit...")
        
        let recordID = CKRecord.ID(recordName: RecordID.settings)
        
        // Try to fetch existing record first, create new if it doesn't exist
        let record: CKRecord
        do {
            // Fetch with proper async/await
            record = try await database.record(for: recordID)
            syncMonitor.logSync("Updating existing settings record")
        } catch let error as CKError where error.code == .unknownItem {
            // Record doesn't exist yet, create new one
            record = CKRecord(recordType: RecordType.settings, recordID: recordID)
            syncMonitor.logSync("Creating new settings record")
        } catch {
            syncMonitor.logError("Failed to fetch settings record: \(error.localizedDescription)")
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
            let savedRecord = try await database.save(record)
            syncMonitor.logSync("✅ Settings uploaded successfully (timestamp: \(timestamp), theme: \(settings.themeTypeRawValue))")
        } catch {
            syncMonitor.logError("Failed to upload settings: \(error.localizedDescription)")
            throw error
        }
    }
    
    /// Downloads settings from CloudKit.
    func downloadSettings() async throws -> UserSettings? {
        syncMonitor.logSync("Downloading settings from CloudKit...")
        
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
                syncMonitor.logError("Failed to parse settings record")
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
            
            syncMonitor.logSync("✅ Settings downloaded (updated: \(lastUpdated), theme: \(themeTypeRawValue))")
            return settings
        } catch let error as CKError where error.code == .unknownItem {
            syncMonitor.logSync("No settings found in CloudKit")
            return nil
        } catch {
            syncMonitor.logError("Failed to download settings: \(error.localizedDescription)")
            throw error
        }
    }
}

// MARK: - Data Models

/// CloudKit representation of a saved game.
struct CloudKitSavedGame {
    let boardData: [Int]
    let notesData: Data
    let solutionData: [Int]
    let initialBoardData: [Int]
    let difficulty: String
    let elapsedTime: TimeInterval
    let startDate: Date
    let mistakes: Int
    let isDailyChallenge: Bool
    let dailyChallengeDate: String?
    let lastSaved: Date
}
