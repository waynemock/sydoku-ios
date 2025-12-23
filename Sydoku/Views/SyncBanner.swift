import SwiftUI

/// A banner that displays sync status and allows retry for failed syncs.
///
/// Shows different states:
/// - Background syncing with iCloud
/// - Connection issue (offline/timed out)
/// - Retry button for failed syncs
struct SyncBanner: View {
    /// The game instance to perform sync operations.
    @ObservedObject var game: SudokuGame
    
    /// Whether the sync timed out (offline or slow connection).
    @Binding var syncTimedOut: Bool
    
    /// Whether a background sync is in progress.
    @Binding var isBackgroundSyncing: Bool
    
    /// Whether a retry sync is currently in progress.
    @Binding var isRetrying: Bool
    
    var body: some View {
        if syncTimedOut || isBackgroundSyncing {
            bannerContent
                .transition(.move(edge: .top).combined(with: .opacity))
        }
    }
    
    /// The main banner content.
    private var bannerContent: some View {
        HStack(spacing: 12) {
            Image(systemName: isBackgroundSyncing || isRetrying ? "icloud.and.arrow.down" : "exclamationmark.icloud")
                .font(.title3)
                .foregroundStyle(.white)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(isBackgroundSyncing || isRetrying ? "Syncing..." : "Connection Issue")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                Text(isBackgroundSyncing || isRetrying ? "Syncing with iCloud in the background" : "Playing offline with local data")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.9))
            }
            
            Spacer()
            
            // Show retry button only if not currently syncing
            if !isBackgroundSyncing && !isRetrying {
                Button {
                    // Retry sync
                    isRetrying = true
                    Task {
                        await game.syncAllFromCloudKit()
                        // If we get here, sync completed successfully
                        await MainActor.run {
                            withAnimation {
                                syncTimedOut = false
                                isRetrying = false
                            }
                        }
                    }
                } label: {
                    HStack(spacing: 6) {
                        if isRetrying {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.8)
                        }
                        Text("Retry")
                            .font(.subheadline.weight(.semibold))
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(.white.opacity(0.2))
                    )
                }
            } else {
                // Show progress indicator when syncing
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(0.9)
            }
            
            Button {
                withAnimation {
                    syncTimedOut = false
                    isRetrying = false
                    isBackgroundSyncing = false
                }
            } label: {
                Image(systemName: "xmark")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white)
                    .frame(width: 20, height: 20)
            }
            .disabled(isRetrying || isBackgroundSyncing)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            LinearGradient(
                colors: isBackgroundSyncing || isRetrying ? [.blue, .blue.opacity(0.8)] : [.orange, .orange.opacity(0.8)],
                startPoint: .leading,
                endPoint: .trailing
            )
        )
    }
}
