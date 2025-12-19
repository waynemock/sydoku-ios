//
//  CloudKitSyncMonitor.swift
//  Sydoku
//
//  Created by Wayne Mock on 12/19/25.
//

import SwiftUI
import SwiftData

/// Monitors CloudKit sync status and provides debugging information.
///
/// This helper class can be used to debug sync issues and understand
/// when data is being synced to CloudKit.
@MainActor
@Observable
class CloudKitSyncMonitor {
    /// Whether sync is currently in progress.
    var isSyncing = false
    
    /// Last known sync time.
    var lastSyncTime: Date?
    
    /// Recent sync events for debugging.
    var syncEvents: [SyncEvent] = []
    
    /// Maximum number of events to keep in memory.
    private let maxEvents = 50
    
    struct SyncEvent: Identifiable {
        let id = UUID()
        let timestamp: Date
        let message: String
        let type: EventType
        
        enum EventType {
            case save
            case fetch
            case delete
            case error
            case sync
        }
    }
    
    /// Logs a sync event.
    func logEvent(_ message: String, type: SyncEvent.EventType = .sync) {
        let event = SyncEvent(timestamp: Date(), message: message, type: type)
        syncEvents.insert(event, at: 0)
        
        // Keep only the most recent events
        if syncEvents.count > maxEvents {
            syncEvents.removeLast()
        }
        
        LogInfo(self, message)
    }
    
    /// Logs a save operation.
    func logSave(_ description: String) {
        logEvent("💾 Save: \(description)", type: .save)
        lastSyncTime = Date()
    }
    
    /// Logs a fetch operation.
    func logFetch(_ description: String) {
        logEvent("📥 Fetch: \(description)", type: .fetch)
        lastSyncTime = Date()
    }
    
    /// Logs a delete operation.
    func logDelete(_ description: String) {
        logEvent("🗑️ Delete: \(description)", type: .delete)
        lastSyncTime = Date()
    }
    
    /// Logs an error.
    func logError(_ description: String) {
        logEvent("❌ Error: \(description)", type: .error)
    }
    
    /// Logs a sync event.
    func logSync(_ description: String) {
        logEvent("☁️ Sync: \(description)", type: .sync)
        lastSyncTime = Date()
        isSyncing = true
        
        // Reset syncing flag after a delay
        Task {
            try? await Task.sleep(for: .seconds(2))
            isSyncing = false
        }
    }
}
