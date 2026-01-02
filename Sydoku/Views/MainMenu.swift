import SwiftUI

/// The main menu for game tools and navigation.
struct MainMenu: View {
    @ObservedObject var game: SudokuGame
    let theme: Theme
    
    @Binding var showingHistory: Bool
    @Binding var showingStats: Bool
    @Binding var showingSettings: Bool
    @Binding var showingAbout: Bool
    @Binding var showingErrorCheckingToast: Bool
    @Binding var showingCloudKitInfo: Bool
    
    /// The shared CloudKit status manager from the app environment.
    @EnvironmentObject private var cloudKitStatus: CloudKitStatus

    var isDisabled: Bool {
        game.isGenerating || game.isComplete || game.isPaused || game.isMistakeLimitReached
    }

    var body: some View {
        MenuButton(
            icon: "ellipsis.circle",
            theme: theme
        ) {
            // Game actions section
            MenuItem(
                icon: "lightbulb",
                title: "Show Hint",
                disabled: isDisabled,
                action: { game.giveHint() }
            )
            
            MenuItem(
                icon: "wand.and.stars",
                title: "Auto Notes",
                disabled: isDisabled,
                action: { game.autoFillNotes() }
            )
            
            MenuItem(
                icon: "trash",
                title: "Clear Notes",
                disabled: isDisabled,
                action: { game.clearAllNotes() }
            )
            
            MenuItem(
                icon: "arrow.counterclockwise",
                title: "Restart Game",
                disabled: isDisabled,
                action: { game.restartGame() }
            )
            
            MenuDivider()
            
            // Toggle section
            MenuItem(
                icon: game.settings.autoErrorChecking ? "checkmark.circle.fill" : "circle",
                title: "Auto Error Checking",
                action: {
                    game.settings.autoErrorChecking.toggle()
                    game.saveSettings()
                    
                    // Show toast feedback
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        showingErrorCheckingToast = true
                    }
                }
            )
            
            MenuDivider()
            
            // Navigation section
            MenuItem(
                icon: "fossil.shell.fill",
                title: "Game History",
                action: { showingHistory = true }
            )
            
            MenuItem(
                icon: "chart.bar.fill",
                title: "Statistics",
                action: { showingStats = true }
            )
            
            MenuItem(
                icon: "gearshape.fill",
                title: "Settings",
                action: { showingSettings = true }
            )
            
            MenuItem(
                icon: cloudKitStatus.isAvailable ? "icloud.fill" : "icloud.slash",
                title: "iCloud Sync",
                action: { showingCloudKitInfo = true }
            )
            
            MenuDivider()
            
            MenuItem(
                icon: "info.circle",
                title: "About Sydoku",
                action: { showingAbout = true }
            )
        }
    }
}

