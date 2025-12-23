//
//  CloudKitSyncIndicator.swift
//  Sydoku
//
//  Created by Wayne Mock on 12/19/25.
//

import SwiftUI

/// A subtle sync indicator that can be shown in the UI to indicate CloudKit sync status.
struct CloudKitSyncIndicator: View {
    let syncMonitor: CloudKitSyncMonitor
    let cloudKitStatus: CloudKitStatus
    
    @Environment(\.theme) var theme
    @State private var rotation: Double = 0
    
    var body: some View {
        HStack(spacing: 6) {
            if cloudKitStatus.isAvailable {
                if syncMonitor.isSyncing {
                    // Syncing animation
                    Image(systemName: "arrow.triangle.2.circlepath")
                        .font(.caption)
                        .foregroundColor(theme.primaryAccent)
                        .rotationEffect(.degrees(rotation))
                        .onAppear {
                            withAnimation(.linear(duration: 1).repeatForever(autoreverses: false)) {
                                rotation = 360
                            }
                        }
                    
                    Text("Syncing...")
                        .font(.caption2)
                        .foregroundColor(theme.secondaryText)
                } else if let lastSync = syncMonitor.lastSyncTime, 
                          Date().timeIntervalSince(lastSync) < 60 {
                    // Recently synced
                    Image(systemName: "checkmark.icloud.fill")
                        .font(.caption)
                        .foregroundColor(.green)
                    
                    Text("Synced")
                        .font(.caption2)
                        .foregroundColor(theme.secondaryText)
                } else {
                    // Cloud available but no recent sync
                    Image(systemName: "icloud.fill")
                        .font(.caption)
                        .foregroundColor(theme.secondaryText.opacity(0.6))
                }
            } else {
                // Cloud not available
                Image(systemName: "icloud.slash.fill")
                    .font(.caption)
                    .foregroundColor(.orange)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(theme.cellBackgroundColor.opacity(0.8))
        )
    }
}

/// A compact version for use in navigation bars or tight spaces.
struct CloudKitSyncIndicatorCompact: View {
    let syncMonitor: CloudKitSyncMonitor
    let cloudKitStatus: CloudKitStatus
    
    @State private var rotation: Double = 0
    
    var body: some View {
        Group {
            if cloudKitStatus.isAvailable {
                if syncMonitor.isSyncing {
                    Image(systemName: "arrow.triangle.2.circlepath")
                        .rotationEffect(.degrees(rotation))
                        .onAppear {
                            withAnimation(.linear(duration: 1).repeatForever(autoreverses: false)) {
                                rotation = 360
                            }
                        }
                } else if let lastSync = syncMonitor.lastSyncTime,
                          Date().timeIntervalSince(lastSync) < 60 {
                    Image(systemName: "checkmark.icloud.fill")
                        .foregroundColor(.green)
                } else {
                    Image(systemName: "icloud.fill")
                        .foregroundColor(.secondary)
                }
            } else {
                Image(systemName: "icloud.slash.fill")
                    .foregroundColor(.orange)
            }
        }
        .font(.caption)
    }
}

#Preview("Full Indicator - Syncing") {
    CloudKitSyncIndicator(
        syncMonitor: {
            let monitor = CloudKitSyncMonitor()
            monitor.isSyncing = true
            return monitor
        }(),
        cloudKitStatus: {
            let status = CloudKitStatus()
            return status
        }()
    )
    .environment(\.theme, Theme())
}

#Preview("Full Indicator - Synced") {
    CloudKitSyncIndicator(
        syncMonitor: {
            let monitor = CloudKitSyncMonitor()
            monitor.lastSyncTime = Date()
            return monitor
        }(),
        cloudKitStatus: {
            let status = CloudKitStatus()
            return status
        }()
    )
    .environment(\.theme, Theme())
}

#Preview("Compact Indicator") {
    CloudKitSyncIndicatorCompact(
        syncMonitor: {
            let monitor = CloudKitSyncMonitor()
            monitor.isSyncing = true
            return monitor
        }(),
        cloudKitStatus: CloudKitStatus()
    )
}
