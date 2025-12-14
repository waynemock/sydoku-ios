import SwiftUI

struct StatisticsView: View {
    @ObservedObject var game: SudokuGame
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            Form {
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
                
                Section {
                    Button(action: {
                        game.resetStats()
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
        }
        #if os(macOS)
        .frame(minWidth: 500, minHeight: 400)
        #endif
    }
    
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
