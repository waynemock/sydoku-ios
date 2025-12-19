//
//  CloudKitDebugView.swift
//  Sydoku
//
//  Created by Wayne Mock on 12/19/25.
//

import SwiftUI
import SwiftData
internal import CloudKit

/// A debug view to monitor CloudKit sync status and events.
///
/// This view is useful for troubleshooting sync issues between devices.
/// It shows recent sync events and the current CloudKit account status.
struct CloudKitDebugView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.theme) var theme
    @EnvironmentObject private var cloudKitStatus: CloudKitStatus
    @Environment(\.modelContext) private var modelContext
    
    @State private var persistenceService: PersistenceService?
    @State private var statistics: GameStatistics?
    @State private var savedGame: SavedGameState?
    @State private var settings: UserSettings?
    
    var body: some View {
        NavigationStack {
            List {
                // CloudKit Status Section
                Section("CloudKit Status") {
                    HStack {
                        Text("Account Status")
                        Spacer()
                        statusBadge
                    }
                    
                    if let monitor = persistenceService?.syncMonitor {
                        HStack {
                            Text("Last Sync")
                            Spacer()
                            if let lastSync = monitor.lastSyncTime {
                                Text(lastSync, style: .relative)
                                    .foregroundColor(theme.secondaryText)
                            } else {
                                Text("Never")
                                    .foregroundColor(theme.secondaryText)
                            }
                        }
                        
                        HStack {
                            Text("Syncing")
                            Spacer()
                            if monitor.isSyncing {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle())
                            } else {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                            }
                        }
                    }
                }
                
                // Data Status Section
                Section("Local Data Status") {
                    HStack {
                        Text("Statistics")
                        Spacer()
                        if let stats = statistics {
                            VStack(alignment: .trailing) {
                                Text("✓ Loaded")
                                    .foregroundColor(.green)
                                Text("Modified: \(stats.lastUpdated, style: .relative)")
                                    .font(.caption)
                                    .foregroundColor(theme.secondaryText)
                            }
                        } else {
                            Text("Not loaded")
                                .foregroundColor(.orange)
                        }
                    }
                    
                    HStack {
                        Text("Saved Game")
                        Spacer()
                        if let game = savedGame {
                            VStack(alignment: .trailing) {
                                Text("✓ In Progress")
                                    .foregroundColor(.green)
                                Text("Modified: \(game.lastSaved, style: .relative)")
                                    .font(.caption)
                                    .foregroundColor(theme.secondaryText)
                                Text("Absolute: \(game.lastSaved, format: .dateTime)")
                                    .font(.caption2)
                                    .foregroundColor(theme.secondaryText.opacity(0.7))
                                Text("Difficulty: \(game.difficulty)")
                                    .font(.caption2)
                                    .foregroundColor(theme.secondaryText.opacity(0.7))
                                Text("Time: \(Int(game.elapsedTime))s")
                                    .font(.caption2)
                                    .foregroundColor(theme.secondaryText.opacity(0.7))
                            }
                        } else {
                            Text("None")
                                .foregroundColor(theme.secondaryText)
                        }
                    }
                    
                    HStack {
                        Text("Settings")
                        Spacer()
                        if let settings = settings {
                            VStack(alignment: .trailing) {
                                Text("✓ Loaded")
                                    .foregroundColor(.green)
                                Text("Modified: \(settings.lastUpdated, style: .relative)")
                                    .font(.caption)
                                    .foregroundColor(theme.secondaryText)
                            }
                        } else {
                            Text("Not loaded")
                                .foregroundColor(.orange)
                        }
                    }
                    
                    Text("Shows when local data was last modified. CloudKit syncs these changes in the background.")
                        .font(.caption2)
                        .foregroundColor(theme.secondaryText)
                        .listRowBackground(Color.clear)
                }
                
                // Sync Events Section
                if let monitor = persistenceService?.syncMonitor, !monitor.syncEvents.isEmpty {
                    Section("Recent Sync Events") {
                        ForEach(monitor.syncEvents.prefix(20)) { event in
                            VStack(alignment: .leading, spacing: 4) {
                                Text(event.message)
                                    .font(.caption)
                                    .foregroundColor(theme.primaryText)
                                Text(event.timestamp, style: .time)
                                    .font(.caption2)
                                    .foregroundColor(theme.secondaryText)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
                
                // Actions Section
                Section("Actions") {
                    Button {
                        refreshData()
                    } label: {
                        HStack {
                            Image(systemName: "arrow.clockwise")
                            Text("Refresh Data")
                        }
                        .foregroundColor(theme.primaryAccent)
                    }
                    
                    Button {
                        forceSaveAll()
                    } label: {
                        HStack {
                            Image(systemName: "icloud.and.arrow.up")
                            Text("Force CloudKit Sync")
                        }
                        .foregroundColor(theme.primaryAccent)
                    }
                    
                    Button {
                        cloudKitStatus.requestAccountStatus()
                    } label: {
                        HStack {
                            Image(systemName: "person.crop.circle.badge.checkmark")
                            Text("Check Account Status")
                        }
                        .foregroundColor(theme.primaryAccent)
                    }
                    
                    Button {
                        testCloudKitDirectly()
                    } label: {
                        HStack {
                            Image(systemName: "cloud.fill")
                            Text("Test CloudKit Connection")
                        }
                        .foregroundColor(theme.primaryAccent)
                    }
                }
                
                // Tips Section
                Section("Sync Tips") {
                    VStack(alignment: .leading, spacing: 12) {
                        tipRow(
                            icon: "wifi",
                            text: "Both devices must be connected to the internet"
                        )
                        tipRow(
                            icon: "person.2.fill",
                            text: "Ensure both devices are signed into the same iCloud account"
                        )
                        tipRow(
                            icon: "clock",
                            text: "CloudKit sync can take 10-30 seconds or longer"
                        )
                        tipRow(
                            icon: "bolt.fill",
                            text: "Try force syncing if data isn't appearing"
                        )
                        tipRow(
                            icon: "exclamationmark.triangle",
                            text: "If sync fails, check Settings → [Your Name] → iCloud"
                        )
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle("CloudKit Debug")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(theme.primaryAccent)
                }
            }
            .onAppear {
                setupPersistenceService()
                refreshData()
            }
        }
    }
    
    private var statusBadge: some View {
        Group {
            switch cloudKitStatus.accountStatus {
            case .available:
                Label("Connected", systemImage: "checkmark.circle.fill")
                    .foregroundColor(.green)
            case .noAccount:
                Label("No Account", systemImage: "xmark.circle.fill")
                    .foregroundColor(.red)
            case .restricted:
                Label("Restricted", systemImage: "exclamationmark.triangle.fill")
                    .foregroundColor(.orange)
            case .couldNotDetermine:
                Label("Checking...", systemImage: "circle.dotted")
                    .foregroundColor(.gray)
            case .temporarilyUnavailable:
                Label("Unavailable", systemImage: "exclamationmark.circle.fill")
                    .foregroundColor(.orange)
            @unknown default:
                Label("Unknown", systemImage: "questionmark.circle.fill")
                    .foregroundColor(.gray)
            }
        }
        .font(.caption)
    }
    
    private func tipRow(icon: String, text: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(theme.primaryAccent)
                .frame(width: 20)
            
            Text(text)
                .font(.caption)
                .foregroundColor(theme.secondaryText)
        }
    }
    
    private func setupPersistenceService() {
        persistenceService = PersistenceService(modelContext: modelContext)
    }
    
    private func refreshData() {
        guard let service = persistenceService else { return }
        
        statistics = service.fetchOrCreateStatistics()
        savedGame = service.fetchSavedGame()
        settings = service.fetchOrCreateSettings()
    }
    
    private func forceSaveAll() {
        guard let service = persistenceService else { return }
        
        // Touch all records to trigger sync
        if let stats = statistics {
            stats.lastUpdated = Date()
        }
        if let game = savedGame {
            game.lastSaved = Date()
        }
        if let settings = settings {
            settings.lastUpdated = Date()
        }
        
        service.forceSave()
        service.syncMonitor.logSync("Manual sync triggered for all data")
        
        // Refresh to show updates
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            refreshData()
        }
    }
    
    private func testCloudKitDirectly() {
        guard let service = persistenceService else { return }
        
        Task {
            do {
                let container = CKContainer.default()
                let database = container.privateCloudDatabase
                
                // Test record
                let testRecord = CKRecord(recordType: "TestSync")
                testRecord["testValue"] = "Sync test at \(Date())" as CKRecordValue
                
                service.syncMonitor.logSync("Testing CloudKit connection...")
                
                let savedRecord = try await database.save(testRecord)
                service.syncMonitor.logSync("✅ CloudKit test successful! Record ID: \(savedRecord.recordID.recordName)")
                
                // Try to fetch it back
                let fetchedRecord = try await database.record(for: savedRecord.recordID)
                if let testValue = fetchedRecord["testValue"] as? String {
                    service.syncMonitor.logSync("✅ Fetch successful! Value: \(testValue)")
                }
            } catch {
                service.syncMonitor.logError("❌ CloudKit test failed: \(error.localizedDescription)")
            }
        }
    }
}

#Preview {
    CloudKitDebugView()
        .environment(\.theme, Theme())
        .environmentObject(CloudKitStatus())
        .modelContainer(for: [GameStatistics.self, SavedGameState.self, UserSettings.self])
}
