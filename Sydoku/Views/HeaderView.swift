import SwiftUI
internal import CloudKit

/// The header section containing app title, timer, and action buttons.
///
/// Displays the app name, daily challenge indicator, timer with pause button (always centered on iPad, below board on iPhone),
/// and action menus for creating new games and accessing tools/settings.
struct HeaderView: View {
    /// The game instance managing puzzle state and logic.
    @ObservedObject var game: SudokuGame
    
    /// The current theme for styling.
    var theme: Theme
    
    /// Binding to show/hide the new game picker.
    @Binding var showingNewGamePicker: Bool
    
    /// Binding to show/hide the statistics sheet.
    @Binding var showingStats: Bool
    
    /// Binding to show/hide the settings sheet.
    @Binding var showingSettings: Bool
    
    /// Binding to show/hide the about sheet.
    @Binding var showingAbout: Bool
    
    /// Binding to show/hide the error checking toast.
    @Binding var showingErrorCheckingToast: Bool
    
    /// Binding to show/hide the CloudKit info sheet.
    @Binding var showingCloudKitInfo: Bool
    
    /// The shared CloudKit status manager from the app environment.
    @EnvironmentObject private var cloudKitStatus: CloudKitStatus
    
    @State private var isShowingCloudKitButton = false
    @State private var pulseAnimation = false
    
    /// Creates a header view with the specified game, theme, and bindings.
    init(
        game: SudokuGame,
        theme: Theme,
        showingNewGamePicker: Binding<Bool>,
        showingStats: Binding<Bool>,
        showingSettings: Binding<Bool>,
        showingAbout: Binding<Bool>,
        showingErrorCheckingToast: Binding<Bool>,
        showingCloudKitInfo: Binding<Bool>
    ) {
        self.game = game
        self.theme = theme
        self._showingNewGamePicker = showingNewGamePicker
        self._showingStats = showingStats
        self._showingSettings = showingSettings
        self._showingAbout = showingAbout
        self._showingErrorCheckingToast = showingErrorCheckingToast
        self._showingCloudKitInfo = showingCloudKitInfo
    }
    
    var body: some View {
        ZStack {
            // Left and right content
            HStack {
                // Left side: Title and puzzle info
                VStack(alignment: .leading, spacing: 0) {
                    HStack(spacing: 8) {
                        Text("Sydoku")
                            .foregroundColor(theme.primaryText)
                            .font(.app(size: 34))
                            .fontWeight(.bold)
                    }
                    
                    // Puzzle type and difficulty
                    if !game.isGenerating && (game.hasSavedGame || !game.initialBoard.allSatisfy({ $0.allSatisfy({ $0 == 0 }) })) {
                        Text(game.isDailyChallenge ? "Daily Challenge • \(game.difficulty.name)" : game.difficulty.name)
                            .font(.appSubheadline)
                            .foregroundColor(theme.secondaryText)
                    }
                }
                
                Spacer()
                
                // Right side: Action buttons
                HStack(spacing: 12) {
                    // New game button
                    Button(action: {
                        // Always show new game picker - no longer show continue alert
                        game.stopTimer()
                        showingNewGamePicker = true
                    }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 40))
                            .foregroundColor(theme.primaryAccent)
                            .frame(width: 44, height: 44)
                    }
                    .disabled(game.isGenerating)
                    .buttonStyle(.plain)
                    
                    // Tools menu button
                    MenuButtonView(
                        game: game,
                        theme: theme,
                        showingStats: $showingStats,
                        showingSettings: $showingSettings,
                        showingAbout: $showingAbout,
                        showingErrorCheckingToast: $showingErrorCheckingToast,
                        showingCloudKitInfo: $showingCloudKitInfo
                    )
                    
                    // iCloud status indicator
                    if isShowingCloudKitButton {
                        Button(action: { showingCloudKitInfo = true }) {
                            ZStack {
                                // Animated pulse background for attention
                                Circle()
                                    .fill(theme.primaryAccent.opacity(0.2))
                                    .frame(width: 44, height: 44)
                                    .scaleEffect(pulseAnimation ? 1.2 : 1.0)
                                    .opacity(pulseAnimation ? 0 : 1)
                                
                                Image(systemName: "icloud.slash.fill")
                                    .font(.system(size: 22))
                                    .foregroundColor(theme.primaryAccent)
                                
                                // Small badge indicator
                                Circle()
                                    .fill(Color.red)
                                    .frame(width: 10, height: 10)
                                    .offset(x: 15, y: -15)
                            }
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("iCloud not connected")
                        .accessibilityHint("Tap to learn how to enable iCloud sync")
                    }
                    
                }
            }
        }
        .padding(.horizontal)
        .padding(.top)
        .onAppear {
            if !UserDefaults.standard.isSkipCloudKitCheck {
                cloudKitStatus.initialize() { status in
                    isShowingCloudKitButton = status != .available && !UserDefaults.standard.isSkipCloudKitCheck
                    
                    // Start pulse animation when button appears
                    if isShowingCloudKitButton {
                        startPulseAnimation()
                    }
                }
            }
        }
        .onChange(of: showingCloudKitInfo) { oldValue, newValue in
            // Hide the CloudKit button if user chose to permanently dismiss
            if !newValue && UserDefaults.standard.isSkipCloudKitCheck && isShowingCloudKitButton {
                isShowingCloudKitButton = false
            }
        }
        
    }
    
    /// Starts a repeating pulse animation to draw attention to the iCloud button.
    private func startPulseAnimation() {
        withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: false)) {
            pulseAnimation = true
        }
    }
}
