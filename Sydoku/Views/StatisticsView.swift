import SwiftUI

/// A view displaying game statistics and performance metrics.
///
/// Shows overall statistics (streaks), per-difficulty stats (games played/completed,
/// best times, average times), and provides an option to reset statistics.
struct StatisticsView: View {
    /// The Sudoku game instance containing the statistics data.
    @ObservedObject var game: SudokuGame
    
    /// Environment value for dismissing the statistics sheet.
    @Environment(\.presentationMode) var presentationMode
    
    /// Environment theme.
    @Environment(\.theme) var theme
    
    /// Whether the reset confirmation alert is showing.
    @State private var showingResetConfirmation = false
    
    var body: some View {
        NavigationView {
            Form {
                // MARK: - Daily Challenge Statistics
                Section(header: Text("Daily Challenges")
                    .foregroundColor(theme.primaryAccent)
                    .fontWeight(.semibold)) {
                    HStack {
                        Image(systemName: "flame.fill")
                            .foregroundColor(theme.warningColor)
                        Text("Current Streak")
                            .foregroundColor(theme.primaryText)
                        Spacer()
                        Text("\(game.stats.dailyChallengeStats.currentDailyStreak) days")
                            .foregroundColor(theme.warningColor)
                            .fontWeight(.semibold)
                    }
                    .listRowBackground(theme.cellBackgroundColor)
                    
                    HStack {
                        Image(systemName: "trophy.fill")
                            .foregroundColor(theme.successColor)
                        Text("Best Streak")
                            .foregroundColor(theme.primaryText)
                        Spacer()
                        Text("\(game.stats.dailyChallengeStats.bestDailyStreak) days")
                            .foregroundColor(theme.successColor)
                            .fontWeight(.semibold)
                    }
                    .listRowBackground(theme.cellBackgroundColor)
                    
                    if game.stats.dailyChallengeStats.perfectDays > 0 {
                        HStack {
                            Image(systemName: "star.fill")
                                .foregroundColor(theme.primaryAccent)
                            Text("Perfect Days")
                                .foregroundColor(theme.primaryText)
                            Spacer()
                            Text("\(game.stats.dailyChallengeStats.perfectDays)")
                                .foregroundColor(theme.primaryAccent)
                                .fontWeight(.semibold)
                        }
                        .listRowBackground(theme.cellBackgroundColor)
                    }
                    
                    // Per-difficulty daily stats
                    ForEach(Difficulty.allCases, id: \.self) { difficulty in
                        let completed = game.stats.dailyChallengeStats.dailiesCompleted[difficulty.rawValue] ?? 0
                        if completed > 0 {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text(difficulty.name)
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundColor(theme.primaryText)
                                    Spacer()
                                    Text("\(completed) completed")
                                        .font(.caption)
                                        .foregroundColor(theme.secondaryText)
                                }
                                
                                HStack {
                                    if let bestTime = game.stats.dailyChallengeStats.bestDailyTimes[difficulty.rawValue] {
                                        Label(formatTime(bestTime), systemImage: "bolt.fill")
                                            .font(.caption)
                                            .foregroundColor(theme.successColor)
                                    }
                                    
                                    Spacer()
                                    
                                    if let avgTime = game.stats.dailyChallengeStats.averageDailyTime(for: difficulty.rawValue) {
                                        Label(formatTime(avgTime), systemImage: "clock.fill")
                                            .font(.caption)
                                            .foregroundColor(theme.secondaryText)
                                    }
                                }
                            }
                            .padding(.vertical, 4)
                            .listRowBackground(theme.cellBackgroundColor)
                        }
                    }
                }
                
                // MARK: - Overall Statistics
                Section(header: Text("All Games")
                    .foregroundColor(theme.primaryAccent)
                    .fontWeight(.semibold)) {
                    HStack {
                        Text("Current Streak")
                            .foregroundColor(theme.primaryText)
                        Spacer()
                        Text("\(game.stats.currentStreak)")
                            .foregroundColor(theme.warningColor)
                            .fontWeight(.semibold)
                    }
                    .listRowBackground(theme.cellBackgroundColor)
                    
                    HStack {
                        Text("Best Streak")
                            .foregroundColor(theme.primaryText)
                        Spacer()
                        Text("\(game.stats.bestStreak)")
                            .foregroundColor(theme.warningColor)
                            .fontWeight(.semibold)
                    }
                    .listRowBackground(theme.cellBackgroundColor)
                }
                
                // MARK: - Per-Difficulty Statistics
                ForEach(Difficulty.allCases, id: \.self) { difficulty in
                    Section(header: Text(difficulty.name)
                        .foregroundColor(theme.primaryAccent)
                        .fontWeight(.semibold)) {
                        HStack {
                            Text("Games Played")
                                .foregroundColor(theme.primaryText)
                            Spacer()
                            Text("\(game.stats.gamesPlayed[difficulty.rawValue] ?? 0)")
                                .foregroundColor(theme.secondaryText)
                        }
                        .listRowBackground(theme.cellBackgroundColor)
                        
                        HStack {
                            Text("Games Completed")
                                .foregroundColor(theme.primaryText)
                            Spacer()
                            Text("\(game.stats.gamesCompleted[difficulty.rawValue] ?? 0)")
                                .foregroundColor(theme.successColor)
                        }
                        .listRowBackground(theme.cellBackgroundColor)
                        
                        if let bestTime = game.stats.bestTimes[difficulty.rawValue] {
                            HStack {
                                Text("Best Time")
                                    .foregroundColor(theme.primaryText)
                                Spacer()
                                Text(formatTime(bestTime))
                                    .foregroundColor(theme.primaryAccent)
                                    .fontWeight(.medium)
                            }
                            .listRowBackground(theme.cellBackgroundColor)
                        }
                        
                        if let avgTime = game.stats.averageTime(for: difficulty.rawValue) {
                            HStack {
                                Text("Average Time")
                                    .foregroundColor(theme.primaryText)
                                Spacer()
                                Text(formatTime(avgTime))
                                    .foregroundColor(theme.secondaryText)
                            }
                            .listRowBackground(theme.cellBackgroundColor)
                        }
                    }
                }
                
                // MARK: - Reset Statistics
                Section {
                    Button(action: {
                        showingResetConfirmation = true
                    }) {
                        HStack {
                            Spacer()
                            Text("Reset Statistics")
                                .foregroundColor(theme.errorColor)
                            Spacer()
                        }
                    }
                    .listRowBackground(theme.cellBackgroundColor)
                }
            }
            .scrollContentBackground(.hidden)
            .background(theme.backgroundColor)
            .navigationTitle("Statistics")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(theme.primaryAccent, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .foregroundColor(.white)
                }
            }
            .alert(isPresented: $showingResetConfirmation) {
                Alert(
                    title: Text("Reset Statistics?"),
                    message: Text("This will permanently delete all your game statistics, including streaks, completion times, and game counts. This action cannot be undone."),
                    primaryButton: .destructive(Text("Reset")) {
                        game.resetStats()
                    },
                    secondaryButton: .cancel()
                )
            }
        }
        #if os(macOS)
        .frame(minWidth: 500, minHeight: 400)
        #endif
    }
    
    /// Formats a time interval as a human-readable string.
    ///
    /// - Parameter time: The time interval in seconds.
    /// - Returns: A formatted string in "HH:MM:SS" or "M:SS" format.
    private func formatTime(_ time: TimeInterval) -> String {
        let hours = Int(time) / 3600
        let minutes = Int(time) / 60 % 60
        let seconds = Int(time) % 60
        
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%d:%02d", minutes, seconds)
        }
    }
}
