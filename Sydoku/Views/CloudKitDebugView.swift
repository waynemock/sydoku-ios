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
    @State private var inProgressGame: Game?
    @State private var settings: UserSettings?
    @State private var completedGamesCount: Int = 0
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // CloudKit Status Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("CloudKit Status")
                            .font(.headline)
                            .foregroundColor(theme.primaryText)
                        
                        VStack(spacing: 12) {
                            HStack {
                                Text("Account Status")
                                    .font(.subheadline)
                                    .foregroundColor(theme.secondaryText)
                                Spacer()
                                statusBadge
                            }
                            
                            if let monitor = persistenceService?.syncMonitor {
                                HStack {
                                    Text("Last Sync")
                                        .font(.subheadline)
                                        .foregroundColor(theme.secondaryText)
                                    Spacer()
                                    if let lastSync = monitor.lastSyncTime {
                                        Text(lastSync, style: .relative)
                                            .font(.subheadline)
                                            .foregroundColor(theme.secondaryText)
                                    } else {
                                        Text("Never")
                                            .font(.subheadline)
                                            .foregroundColor(theme.secondaryText)
                                    }
                                }
                                
                                HStack {
                                    Text("Syncing")
                                        .font(.subheadline)
                                        .foregroundColor(theme.secondaryText)
                                    Spacer()
                                    if monitor.isSyncing {
                                        HStack(spacing: 4) {
                                            ProgressView()
                                                .progressViewStyle(CircularProgressViewStyle())
                                                .scaleEffect(0.7)
                                            Text("Syncing")
                                                .font(.caption)
                                        }
                                        .foregroundColor(theme.primaryAccent)
                                    } else {
                                        Label("Idle", systemImage: "checkmark.circle.fill")
                                            .foregroundColor(.green)
                                            .font(.caption)
                                    }
                                }
                            }
                        }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(theme.primaryAccent.opacity(0.05))
                    )
                    
                    // Data Status Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Local Data Status")
                            .font(.headline)
                            .foregroundColor(theme.primaryText)
                        
                        VStack(spacing: 12) {
                            HStack(alignment: .top) {
                                Text("Statistics")
                                    .font(.subheadline)
                                    .foregroundColor(theme.secondaryText)
                                Spacer()
                                if let stats = statistics {
                                    VStack(alignment: .trailing, spacing: 2) {
                                        Text("✓ Loaded")
                                            .font(.subheadline)
                                            .foregroundColor(.green)
                                        Text(stats.lastUpdated, style: .relative)
                                            .font(.caption2)
                                            .foregroundColor(theme.secondaryText)
                                    }
                                } else {
                                    Text("Not loaded")
                                        .font(.subheadline)
                                        .foregroundColor(.orange)
                                }
                            }
                            
                            HStack(alignment: .top) {
                                Text("Saved Game")
                                    .font(.subheadline)
                                    .foregroundColor(theme.secondaryText)
                                Spacer()
                                if let game = inProgressGame {
                                    VStack(alignment: .trailing, spacing: 2) {
                                        Text("✓ In Progress")
                                            .font(.subheadline)
                                            .foregroundColor(.green)
                                        Text(game.lastSaved, style: .relative)
                                            .font(.caption2)
                                            .foregroundColor(theme.secondaryText)
                                        Text("Difficulty: \(game.difficulty)")
                                            .font(.caption2)
                                            .foregroundColor(theme.secondaryText.opacity(0.7))
                                        Text("Time: \(Int(game.elapsedTime))s")
                                            .font(.caption2)
                                            .foregroundColor(theme.secondaryText.opacity(0.7))
                                        Text("Mistakes: \(game.mistakes)")
                                            .font(.caption2)
                                            .foregroundColor(theme.secondaryText.opacity(0.7))
                                    }
                                } else {
                                    Text("None")
                                        .font(.subheadline)
                                        .foregroundColor(theme.secondaryText)
                                }
                            }
                            
                            HStack(alignment: .top) {
                                Text("Settings")
                                    .font(.subheadline)
                                    .foregroundColor(theme.secondaryText)
                                Spacer()
                                if let settings = settings {
                                    VStack(alignment: .trailing, spacing: 2) {
                                        Text("✓ Loaded")
                                            .font(.subheadline)
                                            .foregroundColor(.green)
                                        Text(settings.lastUpdated, style: .relative)
                                            .font(.caption2)
                                            .foregroundColor(theme.secondaryText)
                                    }
                                } else {
                                    Text("Not loaded")
                                        .font(.subheadline)
                                        .foregroundColor(.orange)
                                }
                            }
                            
                            HStack(alignment: .top) {
                                Text("Completed Games")
                                    .font(.subheadline)
                                    .foregroundColor(theme.secondaryText)
                                Spacer()
                                Text("\(completedGamesCount) games")
                                    .font(.subheadline)
                                    .foregroundColor(.green)
                            }
                        }
                        
                        Text("Shows when local data was last modified. CloudKit syncs these changes in the background.")
                            .font(.caption2)
                            .foregroundColor(theme.secondaryText)
                            .padding(.top, 4)
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(theme.primaryAccent.opacity(0.05))
                    )
                    
                    // Sync Events Section
                    if let monitor = persistenceService?.syncMonitor, !monitor.syncEvents.isEmpty {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Recent Sync Events")
                                .font(.headline)
                                .foregroundColor(theme.primaryText)
                            
                            VStack(spacing: 8) {
                                ForEach(monitor.syncEvents.prefix(20)) { event in
                                    HStack(alignment: .top, spacing: 8) {
                                        Text(event.timestamp, style: .time)
                                            .font(.caption2)
                                            .foregroundColor(theme.secondaryText)
                                            .frame(width: 60, alignment: .leading)
                                        
                                        Text(event.message)
                                            .font(.caption)
                                            .foregroundColor(theme.primaryText)
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                    }
                                    .padding(.vertical, 4)
                                }
                            }
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(theme.primaryAccent.opacity(0.05))
                        )
                    }
                    
                    // Actions Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Actions")
                            .font(.headline)
                            .foregroundColor(theme.primaryText)
                        
                        VStack(spacing: 8) {
                            Button(action: refreshData) {
                                HStack {
                                    Image(systemName: "arrow.clockwise")
                                        .frame(width: 24)
                                    Text("Refresh Data")
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                }
                                .font(.subheadline)
                                .foregroundColor(theme.primaryAccent)
                                .padding(.vertical, 8)
                            }
                            .buttonStyle(.plain)
                            
                            Button(action: forceSaveAll) {
                                HStack {
                                    Image(systemName: "icloud.and.arrow.up")
                                        .frame(width: 24)
                                    Text("Force CloudKit Sync")
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                }
                                .font(.subheadline)
                                .foregroundColor(theme.primaryAccent)
                                .padding(.vertical, 8)
                            }
                            .buttonStyle(.plain)
                            
                            Button(action: { cloudKitStatus.requestAccountStatus() }) {
                                HStack {
                                    Image(systemName: "person.crop.circle.badge.checkmark")
                                        .frame(width: 24)
                                    Text("Check Account Status")
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                }
                                .font(.subheadline)
                                .foregroundColor(theme.primaryAccent)
                                .padding(.vertical, 8)
                            }
                            .buttonStyle(.plain)
                            
                            Button(action: testCloudKitDirectly) {
                                HStack {
                                    Image(systemName: "cloud.fill")
                                        .frame(width: 24)
                                    Text("Test CloudKit Connection")
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                }
                                .font(.subheadline)
                                .foregroundColor(theme.primaryAccent)
                                .padding(.vertical, 8)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(theme.primaryAccent.opacity(0.05))
                    )
                    
                    // Tips Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Sync Tips")
                            .font(.headline)
                            .foregroundColor(theme.primaryText)
                        
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
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(theme.primaryAccent.opacity(0.05))
                    )
                }
                .padding()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(theme.backgroundColor)
            .navigationTitle("CloudKit Debug")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
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
        inProgressGame = service.fetchInProgressGame()
        settings = service.fetchOrCreateSettings()
        completedGamesCount = service.fetchCompletedGames().count
    }
    
    private func forceSaveAll() {
        guard let service = persistenceService else { return }
        
        // Touch all records to trigger sync
        if let stats = statistics {
            stats.lastUpdated = Date()
        }
        if let game = inProgressGame {
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
        .modelContainer(for: [GameStatistics.self, UserSettings.self, Game.self])
}

