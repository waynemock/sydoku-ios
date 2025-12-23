//
//  GameHistoryView.swift
//  Sydoku
//
//  Created by Wayne Mock on 12/21/25.
//

import SwiftUI
import SwiftData

/// A view displaying the history of completed games.
///
/// Shows a list of all completed games with filtering options by difficulty
/// and daily challenge status.
struct GameHistoryView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.theme) var theme
    @Environment(\.modelContext) private var modelContext
    
    @State private var persistenceService: PersistenceService?
    @State private var completedGames: [Game] = []
    @State private var selectedDifficulty: String? = nil
    @State private var showDailiesOnly = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Filters
                VStack(spacing: 12) {
                    // Difficulty filter
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            FilterChip(
                                title: "All",
                                isSelected: selectedDifficulty == nil,
                                action: { selectedDifficulty = nil }
                            )
                            
                            ForEach(["Easy", "Medium", "Hard"], id: \.self) { difficulty in
                                FilterChip(
                                    title: difficulty,
                                    isSelected: selectedDifficulty == difficulty,
                                    action: { selectedDifficulty = difficulty }
                                )
                            }
                        }
                        .padding(.horizontal)
                    }
                    
                    // Daily challenge filter
                    Toggle("Daily Challenges Only", isOn: $showDailiesOnly)
                        .padding(.horizontal)
                }
                .padding(.vertical, 12)
                .background(theme.backgroundColor)
                
                Divider()
                
                // Games list
                if filteredGames.isEmpty {
                    emptyStateView
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(filteredGames) { game in
                                GameHistoryCard(game: game)
                            }
                        }
                        .padding()
                    }
                }
            }
            .background(theme.backgroundColor)
            .navigationTitle("Game History")
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
                loadGames()
            }
            .onChange(of: selectedDifficulty) { _, _ in
                loadGames()
            }
            .onChange(of: showDailiesOnly) { _, _ in
                loadGames()
            }
        }
    }
    
    private var filteredGames: [Game] {
        completedGames
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "clock.arrow.circlepath")
                .font(.system(size: 60))
                .foregroundColor(theme.secondaryText.opacity(0.5))
            
            Text("No Completed Games")
                .font(.title2.bold())
                .foregroundColor(theme.primaryText)
            
            Text(emptyStateMessage)
                .font(.body)
                .foregroundColor(theme.secondaryText)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var emptyStateMessage: String {
        if showDailiesOnly {
            return "You haven't completed any daily challenges yet. Complete a daily challenge to see it here!"
        } else if let difficulty = selectedDifficulty {
            return "You haven't completed any \(difficulty) puzzles yet. Try a \(difficulty) puzzle to see your history!"
        } else {
            return "You haven't completed any games yet. Finish a puzzle to see it in your history!"
        }
    }
    
    private func setupPersistenceService() {
        persistenceService = PersistenceService(modelContext: modelContext)
    }
    
    private func loadGames() {
        guard let service = persistenceService else { return }
        
        completedGames = service.fetchCompletedGames(
            difficulty: selectedDifficulty,
            isDailyChallenge: showDailiesOnly ? true : nil
        )
    }
}

/// A filter chip for the game history view.
private struct FilterChip: View {
    @Environment(\.theme) var theme
    
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline.weight(isSelected ? .semibold : .regular))
                .foregroundColor(isSelected ? .white : theme.primaryText)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(isSelected ? theme.primaryAccent : theme.primaryAccent.opacity(0.1))
                )
        }
        .buttonStyle(.plain)
    }
}

/// A card displaying a completed game's information.
private struct GameHistoryCard: View {
    @Environment(\.theme) var theme
    
    let game: Game
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                // Difficulty badge
                Text(game.difficulty)
                    .font(.caption.weight(.semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(difficultyColor)
                    )
                
                if game.isDailyChallenge {
                    Label("Daily", systemImage: "calendar")
                        .font(.caption.weight(.semibold))
                        .foregroundColor(theme.primaryAccent)
                }
                
                Spacer()
                
                if let completionDate = game.completionDate {
                    Text(completionDate, style: .date)
                        .font(.caption)
                        .foregroundColor(theme.secondaryText)
                } else {
                    Text("In progress")
                        .font(.caption)
                        .foregroundColor(theme.secondaryText)

                }
            }
            
            // Stats
            HStack(spacing: 20) {
//                statItem(
//                    icon: "clock",
//                    label: "Time",
//                    value: game.completionDate != nil ? formatTime(game.completionTime) : "In progress"
//                )
                
                statItem(
                    icon: "xmark.circle",
                    label: "Mistakes",
                    value: "\(game.mistakes)"
                )
                
                statItem(
                    icon: "lightbulb",
                    label: "Hints",
                    value: "\(game.hintsUsed)"
                )
            }
            
            // Perfect game indicator
            if game.mistakes == 0 {
                HStack(spacing: 4) {
                    Image(systemName: "star.fill")
                        .font(.caption2)
                    Text("Perfect Game!")
                        .font(.caption.weight(.semibold))
                }
                .foregroundColor(.yellow)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(theme.primaryAccent.opacity(0.05))
        )
    }
    
    private var difficultyColor: Color {
        switch game.difficulty.lowercased() {
        case "easy":
            return .green
        case "medium":
            return .orange
        case "hard":
            return .red
        default:
            return theme.primaryAccent
        }
    }
    
    private func statItem(icon: String, label: String, value: String) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(theme.primaryAccent)
            
            Text(value)
                .font(.subheadline.weight(.semibold))
                .foregroundColor(theme.primaryText)
            
            Text(label)
                .font(.caption2)
                .foregroundColor(theme.secondaryText)
        }
        .frame(maxWidth: .infinity)
    }
    
    private func formatTime(_ seconds: TimeInterval) -> String {
        let hours = Int(seconds) / 3600
        let minutes = Int(seconds) / 60 % 60
        let secs = Int(seconds) % 60
        
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, secs)
        } else {
            return String(format: "%d:%02d", minutes, secs)
        }
    }
}

#Preview {
    GameHistoryView()
        .environment(\.theme, Theme())
        .modelContainer(for: [Game.self])
}
