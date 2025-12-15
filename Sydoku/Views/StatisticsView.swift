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
    
    /// Whether the reset confirmation alert is showing.
    @State private var showingResetConfirmation = false
    
    var body: some View {
        NavigationView {
            Form {
                // MARK: - Overall Statistics
                Section(header: Text("Overall Stats")) {
                    HStack {
                        Text("Current Streak")
                        Spacer()
                        Text("\(game.stats.currentStreak)")
                            .foregroundColor(.orange)
                            .fontWeight(.semibold)
                    }
                    
                    HStack {
                        Text("Best Streak")
                        Spacer()
                        Text("\(game.stats.bestStreak)")
                            .foregroundColor(.orange)
                            .fontWeight(.semibold)
                    }
                }
                
                // MARK: - Per-Difficulty Statistics
                ForEach(Difficulty.allCases, id: \.self) { difficulty in
                    Section(header: Text(difficulty.name)) {
                        HStack {
                            Text("Games Played")
                            Spacer()
                            Text("\(game.stats.gamesPlayed[difficulty.rawValue] ?? 0)")
                                .foregroundColor(.secondary)
                        }
                        
                        HStack {
                            Text("Games Completed")
                            Spacer()
                            Text("\(game.stats.gamesCompleted[difficulty.rawValue] ?? 0)")
                                .foregroundColor(.green)
                        }
                        
                        if let bestTime = game.stats.bestTimes[difficulty.rawValue] {
                            HStack {
                                Text("Best Time")
                                Spacer()
                                Text(formatTime(bestTime))
                                    .foregroundColor(.blue)
                                    .fontWeight(.medium)
                            }
                        }
                        
                        if let avgTime = game.stats.averageTime(for: difficulty.rawValue) {
                            HStack {
                                Text("Average Time")
                                Spacer()
                                Text(formatTime(avgTime))
                                    .foregroundColor(.secondary)
                            }
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
                                .foregroundColor(.red)
                            Spacer()
                        }
                    }
                }
            }
            .navigationTitle("Statistics")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        presentationMode.wrappedValue.dismiss()
                    }
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
