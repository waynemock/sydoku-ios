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
    
    @State private var selectedDifficulty: Difficulty? = nil
    @State private var showDailiesOnly = false
    @State private var showInProgress = true
    @State private var showCompleted = true
    
    // Persistence service for CloudKit-aware operations
    private var persistenceService: PersistenceService {
        PersistenceService(modelContext: modelContext)
    }
    
    // Optional callback for when a game is selected to resume
    var onResumeGame: ((Game) -> Void)?
    
    // Optional callback for when a completed game is selected to view
    var onViewGame: ((Game) -> Void)?
    
    // Use @Query for efficient, reactive data fetching
    // Completed games will sort by completion date, in-progress by start date
    @Query(
        sort: [
            SortDescriptor(\Game.completionDate, order: .reverse),
            SortDescriptor(\Game.startDate, order: .reverse)
        ]
    ) private var allGames: [Game]
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Games list
                if filteredGames.isEmpty {
                    emptyStateView
                } else {
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            // In Progress Section
                            if !inProgressGames.isEmpty {
                                VStack(alignment: .leading, spacing: 12) {
                                    Text("In Progress")
                                        .font(.title3.bold())
                                        .foregroundColor(theme.primaryText)
                                        .padding(.horizontal)
                                    
                                    ForEach(inProgressGames, id: \.gameID) { game in
                                        GameHistoryCard(game: game, showResumeButton: true) {
                                            // Resume this game
                                            onResumeGame?(game)
                                            dismiss()
                                        } onView: {
                                            // View this game (shouldn't happen for in-progress games)
                                            onViewGame?(game)
                                            dismiss()
                                        }
                                        .swipeToDelete(theme: theme) {
                                            deleteGame(game)
                                        }
                                        .id(game.gameID)
                                    }
                                }
                            }
                            
                            // Completed Section
                            if !completedGames.isEmpty {
                                VStack(alignment: .leading, spacing: 12) {
                                    Text("Completed")
                                        .font(.title3.bold())
                                        .foregroundColor(theme.primaryText)
                                        .padding(.horizontal)
                                    
                                    ForEach(completedGames, id: \.gameID) { game in
                                        GameHistoryCard(game: game, showResumeButton: false, onResume: nil, onView: {
                                            // View this completed game
                                            onViewGame?(game)
                                            dismiss()
                                        })
                                        .swipeToDelete(theme: theme) {
                                            deleteGame(game)
                                        }
                                        .id(game.gameID)
                                    }
                                }
                            }
                        }
                        .padding()
                    }
                }
            }
            .background(theme.backgroundColor)
            .navigationTitle("Games")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(theme.backgroundColor, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(theme.colorScheme, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    FilterMenuButton(
                        selectedDifficulty: $selectedDifficulty,
                        showInProgress: $showInProgress,
                        showCompleted: $showCompleted,
                        showDailiesOnly: $showDailiesOnly
                    )
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .foregroundColor(theme.primaryAccent)
                }
            }
        }
        .interactiveDismissDisabled()
    }
    
    private var filteredGames: [Game] {
        var games = allGames
        
        // Filter by completion status
        if !showInProgress || !showCompleted {
            games = games.filter { game in
                if showInProgress && !game.isCompleted { return true }
                if showCompleted && game.isCompleted { return true }
                return false
            }
        }
        
        // Filter by difficulty
        if let difficulty = selectedDifficulty {
            games = games.filter { $0.difficulty.lowercased() == difficulty.rawValue }
        }
        
        // Filter by daily challenge
        if showDailiesOnly {
            games = games.filter { $0.isDailyChallenge }
        }
        
        // Remove duplicates by gameID (defensive programming)
        var seenIDs = Set<String>()
        games = games.filter { game in
            if seenIDs.contains(game.gameID) {
                return false
            }
            seenIDs.insert(game.gameID)
            return true
        }
        
        return games
    }
    
    private var inProgressGames: [Game] {
        filteredGames.filter { !$0.isCompleted }
    }
    
    private var completedGames: [Game] {
        filteredGames.filter { $0.isCompleted }
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
        if !showInProgress && !showCompleted {
            return "Please select at least one filter to view games."
        } else if showDailiesOnly {
            return "You haven't completed any daily challenges yet. Complete a daily challenge to see it here!"
        } else if let difficulty = selectedDifficulty {
            if showInProgress && !showCompleted {
                return "No in-progress \(difficulty.name) puzzles."
            } else if showCompleted && !showInProgress {
                return "You haven't completed any \(difficulty.name) puzzles yet. Try a \(difficulty.name) puzzle to see your history!"
            } else {
                return "No \(difficulty.name) puzzles found."
            }
        } else {
            if showInProgress && !showCompleted {
                return "No games in progress. Start a new puzzle!"
            } else if showCompleted && !showInProgress {
                return "You haven't completed any games yet. Finish a puzzle to see it in your history!"
            } else {
                return "No games found. Start playing to see your games here!"
            }
        }
    }
    
    /// Deletes a game from both local storage and CloudKit.
    private func deleteGame(_ game: Game) {
        withAnimation {
            persistenceService.deleteGame(game)
        }
    }
}

/// A menu button that displays filter options.
private struct FilterMenuButton: View {
    @Environment(\.theme) var theme
    
    @Binding var selectedDifficulty: Difficulty?
    @Binding var showInProgress: Bool
    @Binding var showCompleted: Bool
    @Binding var showDailiesOnly: Bool
    
    private var activeFilterCount: Int {
        var count = 0
        if selectedDifficulty != nil { count += 1 }
        if !showInProgress { count += 1 }
        if !showCompleted { count += 1 }
        if showDailiesOnly { count += 1 }
        return count
    }
    
    var body: some View {
        Menu {
            Section("Difficulty") {
                Button(action: { selectedDifficulty = nil }) {
                    HStack {
                        Text("All Difficulties")
                        Spacer()
                        if selectedDifficulty == nil {
                            Image(systemName: "checkmark")
                        }
                    }
                }
                
                ForEach(Difficulty.allCases, id: \.self) { difficulty in
                    Button(action: { 
                        selectedDifficulty = selectedDifficulty == difficulty ? nil : difficulty
                    }) {
                        HStack {
                            Text(difficulty.name)
                            Spacer()
                            if selectedDifficulty == difficulty {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            }
            
            Section("Status") {
                Button(action: { showInProgress.toggle() }) {
                    HStack {
                        Text("In Progress")
                        Spacer()
                        if showInProgress {
                            Image(systemName: "checkmark")
                        }
                    }
                }
                
                Button(action: { showCompleted.toggle() }) {
                    HStack {
                        Text("Completed")
                        Spacer()
                        if showCompleted {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
            
            Section("Type") {
                Button(action: { showDailiesOnly.toggle() }) {
                    HStack {
                        Text("Daily Challenges")
                        Spacer()
                        if showDailiesOnly {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
            
            if activeFilterCount > 0 {
                Section {
                    Button(role: .destructive, action: resetFilters) {
                        Label("Clear All Filters", systemImage: "xmark.circle")
                    }
                }
            }
        } label: {
            HStack(spacing: 4) {
                Image(systemName: "line.3.horizontal.decrease.circle")
                    .font(.system(size: 20))
                if activeFilterCount > 0 {
                    ZStack {
                        Circle()
                            .fill(theme.primaryAccent)
                            .frame(width: 16, height: 16)
                        Text("\(activeFilterCount)")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.white)
                    }
                    .offset(x: -4, y: -8)
                }
            }
            .foregroundColor(theme.primaryAccent)
        }
    }
    
    private func resetFilters() {
        selectedDifficulty = nil
        showInProgress = true
        showCompleted = true
        showDailiesOnly = false
    }
}

/// A card displaying a completed game's information.
private struct GameHistoryCard: View {
    @Environment(\.theme) var theme
    @Environment(\.modelContext) private var modelContext
    
    let game: Game
    let showResumeButton: Bool
    let onResume: (() -> Void)?
    let onView: (() -> Void)?
    
    /// Get the daily challenge time context (Today, Yesterday, or Past).
    private var dailyChallengeContext: String? {
        guard game.isDailyChallenge, let savedDateString = game.dailyChallengeDate else {
            return nil
        }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        
        guard let savedDate = formatter.date(from: savedDateString) else {
            return nil
        }
        
        let calendar = Calendar.current
        if calendar.isDateInToday(savedDate) {
            return "Today"
        } else if calendar.isDateInYesterday(savedDate) {
            return "Yesterday"
        } else {
            return "Past"
        }
    }
    
    /// Get the display text for daily challenges.
    private var dailyDisplayText: String {
        if game.isCompleted {
            // Completed games just show "Daily"
            return "Daily"
        } else if let context = dailyChallengeContext {
            // In-progress games show context
            return "Daily: \(context)"
        } else {
            return "Daily"
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            VStack(alignment: .leading, spacing: 6) {
                // Chips row
                HStack {
                    // Difficulty badge
                    Text(game.difficulty.capitalized)
                        .font(.caption.weight(.semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(difficultyColor)
                        )
                    
                    if game.isDailyChallenge {
                        Text(dailyDisplayText)
                            .font(.caption.weight(.semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(theme.primaryAccent)
                            )
                    }
                    
                    if !game.isCompleted {
                        Text("In Progress")
                            .font(.caption.weight(.semibold))
                            .foregroundColor(theme.primaryAccent)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(theme.primaryAccent.opacity(0.15))
                            )
                    }
                    
                    Spacer()
                }
                
                // Date (completion or start date)
                Text(game.completionDate ?? game.startDate, format: .dateTime.month(.abbreviated).day().year())
                    .font(.caption)
                    .foregroundColor(theme.secondaryText)
            }
            
            // Stats
            HStack(spacing: 20) {
                statItem(
                    icon: "clock",
                    label: "Time",
                    value: formatTime(game.elapsedTime)
                )
                
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
            
            // Bottom section
            HStack {
                // Perfect game indicator
                if game.isCompleted && game.mistakes == 0 {
                    HStack(spacing: 4) {
                        Image(systemName: "star.fill")
                            .font(.caption2)
                        Text("Perfect Game!")
                            .font(.caption.weight(.semibold))
                    }
                    .foregroundColor(.yellow)
                }
                
                Spacer()
                
                // Resume button for in-progress games
                if showResumeButton {
                    Button(action: {
                        onResume?()
                    }) {
                        HStack(spacing: 4) {
                            Text("Resume")
                                .font(.subheadline.weight(.semibold))
                            Image(systemName: "arrow.right")
                                .font(.caption)
                        }
                        .foregroundColor(theme.primaryAccent)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(theme.primaryAccent.opacity(0.15))
                        )
                    }
                    .buttonStyle(.plain)
                }
                
                // View button for completed games
                if game.isCompleted {
                    Button(action: {
                        onView?()
                    }) {
                        HStack(spacing: 4) {
                            Text("View")
                                .font(.subheadline.weight(.semibold))
                            Image(systemName: "eye")
                                .font(.caption)
                        }
                        .foregroundColor(theme.primaryAccent)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(theme.primaryAccent.opacity(0.15))
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(game.isCompleted ? 
                      theme.cellBackgroundColor : 
                      theme.primaryAccent.opacity(0.08))
                .overlay {
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(game.isCompleted ? Color.clear : theme.primaryAccent.opacity(0.3), lineWidth: 1)
                }
        )
        .id(game.gameID) // Force SwiftUI to treat each card as unique
    }
    
    private var difficultyColor: Color {
        switch game.difficulty.lowercased() {
        case "easy":
            return theme.successColor
        case "medium":
            return theme.warningColor
        case "hard":
            return theme.errorColor
        default:
            return theme.primaryAccent
        }
    }
    
    private func statItem(icon: String, label: String, value: String) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 20))
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
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Game.self, configurations: config)
    
    // Create mock games
    let now = Date()
    let calendar = Calendar.current
    
    // In-progress Easy game
    let inProgressEasy = Game(
        initialBoardData: Array(repeating: 0, count: 81),
        solutionData: Array(repeating: 5, count: 81),
        boardData: Array(repeating: 0, count: 81),
        difficulty: "easy",
        elapsedTime: 245, // 4:05
        startDate: calendar.date(byAdding: .hour, value: -1, to: now)!,
        mistakes: 2,
        hintsData: Array(repeating: 0, count: 81),
        isDailyChallenge: false,
        dailyChallengeDate: nil,
        isCompleted: false
    )
    
    // In-progress Medium daily challenge (from yesterday - should show "Past" chip)
    let inProgressMediumDaily = Game(
        initialBoardData: Array(repeating: 0, count: 81),
        solutionData: Array(repeating: 5, count: 81),
        boardData: Array(repeating: 0, count: 81),
        difficulty: "medium",
        elapsedTime: 780, // 13:00
        startDate: calendar.date(byAdding: .day, value: -1, to: now)!,
        mistakes: 5,
        hintsData: Array(repeating: 0, count: 81),
        isDailyChallenge: true,
        dailyChallengeDate: "2025-12-23", // Yesterday's date - will show "Past" chip
        isCompleted: false
    )
    
    // Completed Easy game - Perfect!
    let completedEasyPerfect = Game(
        initialBoardData: Array(repeating: 0, count: 81),
        solutionData: Array(repeating: 5, count: 81),
        boardData: Array(repeating: 5, count: 81),
        difficulty: "easy",
        elapsedTime: 180, // 3:00
        startDate: calendar.date(byAdding: .day, value: -1, to: now)!,
        mistakes: 0,
        hintsData: Array(repeating: 0, count: 81),
        isDailyChallenge: false,
        dailyChallengeDate: nil,
        isCompleted: true,
        completionDate: calendar.date(byAdding: .day, value: -1, to: now)!
    )
    
    // Completed Medium game with mistakes
    let completedMedium = Game(
        initialBoardData: Array(repeating: 0, count: 81),
        solutionData: Array(repeating: 5, count: 81),
        boardData: Array(repeating: 5, count: 81),
        difficulty: "medium",
        elapsedTime: 540, // 9:00
        startDate: calendar.date(byAdding: .day, value: -2, to: now)!,
        mistakes: 3,
        hintsData: Array(repeating: 0, count: 81),
        isDailyChallenge: false,
        dailyChallengeDate: nil,
        isCompleted: true,
        completionDate: calendar.date(byAdding: .day, value: -2, to: now)!
    )
    
    // Completed Hard daily challenge - Perfect!
    let completedHardDailyPerfect = Game(
        initialBoardData: Array(repeating: 0, count: 81),
        solutionData: Array(repeating: 5, count: 81),
        boardData: Array(repeating: 5, count: 81),
        difficulty: "hard",
        elapsedTime: 1800, // 30:00
        startDate: calendar.date(byAdding: .day, value: -3, to: now)!,
        mistakes: 0,
        hintsData: Array(repeating: 0, count: 81),
        isDailyChallenge: true,
        dailyChallengeDate: "2025-12-20",
        isCompleted: true,
        completionDate: calendar.date(byAdding: .day, value: -3, to: now)!
    )
    
    // Completed Hard game with many mistakes and hints
    let completedHardWithHelp = Game(
        initialBoardData: Array(repeating: 0, count: 81),
        solutionData: Array(repeating: 5, count: 81),
        boardData: Array(repeating: 5, count: 81),
        difficulty: "hard",
        elapsedTime: 2400, // 40:00
        startDate: calendar.date(byAdding: .day, value: -5, to: now)!,
        mistakes: 8,
        hintsData: [1, 1, 1, 0, 0, 0, 0, 0, 0] + Array(repeating: 0, count: 72), // 3 hints used
        isDailyChallenge: false,
        dailyChallengeDate: nil,
        isCompleted: true,
        completionDate: calendar.date(byAdding: .day, value: -5, to: now)!
    )
    
    // Completed Easy daily challenge
    let completedEasyDaily = Game(
        initialBoardData: Array(repeating: 0, count: 81),
        solutionData: Array(repeating: 5, count: 81),
        boardData: Array(repeating: 5, count: 81),
        difficulty: "easy",
        elapsedTime: 150, // 2:30
        startDate: calendar.date(byAdding: .day, value: -7, to: now)!,
        mistakes: 1,
        hintsData: [1, 0, 0] + Array(repeating: 0, count: 78), // 1 hint used
        isDailyChallenge: true,
        dailyChallengeDate: "2025-12-16",
        isCompleted: true,
        completionDate: calendar.date(byAdding: .day, value: -7, to: now)!
    )
    
    // In-progress Hard game
    let inProgressHard = Game(
        initialBoardData: Array(repeating: 0, count: 81),
        solutionData: Array(repeating: 5, count: 81),
        boardData: Array(repeating: 0, count: 81),
        difficulty: "hard",
        elapsedTime: 1200, // 20:00
        startDate: calendar.date(byAdding: .hour, value: -4, to: now)!,
        mistakes: 10,
        hintsData: [1, 1, 0, 0, 0] + Array(repeating: 0, count: 76), // 2 hints used
        isDailyChallenge: false,
        dailyChallengeDate: nil,
        isCompleted: false
    )
    
    // In-progress daily challenge from TODAY (should show "Daily: Today")
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd"
    let todayDateString = formatter.string(from: now)
    
    let inProgressTodayDaily = Game(
        initialBoardData: Array(repeating: 0, count: 81),
        solutionData: Array(repeating: 5, count: 81),
        boardData: Array(repeating: 0, count: 81),
        difficulty: "easy",
        elapsedTime: 120, // 2:00
        startDate: calendar.date(byAdding: .hour, value: -1, to: now)!,
        mistakes: 1,
        hintsData: Array(repeating: 0, count: 81),
        isDailyChallenge: true,
        dailyChallengeDate: todayDateString, // Today's date - will show "Daily: Today"
        isCompleted: false
    )
    
    // In-progress daily challenge from 3 days ago (should show "Daily: Past")
    let inProgressPastDaily = Game(
        initialBoardData: Array(repeating: 0, count: 81),
        solutionData: Array(repeating: 5, count: 81),
        boardData: Array(repeating: 0, count: 81),
        difficulty: "hard",
        elapsedTime: 900, // 15:00
        startDate: calendar.date(byAdding: .day, value: -3, to: now)!,
        mistakes: 7,
        hintsData: [1, 0, 0] + Array(repeating: 0, count: 78),
        isDailyChallenge: true,
        dailyChallengeDate: "2025-12-21", // 3 days ago - will show "Daily: Past"
        isCompleted: false
    )
    
    // Insert all mock games
    container.mainContext.insert(inProgressEasy)
    container.mainContext.insert(inProgressMediumDaily)
    container.mainContext.insert(inProgressTodayDaily)
    container.mainContext.insert(inProgressPastDaily)
    container.mainContext.insert(completedEasyPerfect)
    container.mainContext.insert(completedMedium)
    container.mainContext.insert(completedHardDailyPerfect)
    container.mainContext.insert(completedHardWithHelp)
    container.mainContext.insert(completedEasyDaily)
    container.mainContext.insert(inProgressHard)
    
    return GameHistoryView(onResumeGame: { game in
        print("📱 Resuming game:")
        print("  - Difficulty: \(game.difficulty)")
        print("  - Daily Challenge: \(game.isDailyChallenge)")
        print("  - Elapsed Time: \(Int(game.elapsedTime))s")
        print("  - Mistakes: \(game.mistakes)")
        print("  - Hints Used: \(game.hintsUsed)")
        print("  - Game ID: \(game.gameID)")
    }, onViewGame: { game in
        print("👁️ Viewing completed game:")
        print("  - Difficulty: \(game.difficulty)")
        print("  - Daily Challenge: \(game.isDailyChallenge)")
        print("  - Completion Time: \(Int(game.elapsedTime))s")
        print("  - Mistakes: \(game.mistakes)")
        print("  - Hints Used: \(game.hintsUsed)")
        print("  - Perfect Game: \(game.mistakes == 0)")
        print("  - Game ID: \(game.gameID)")
    })
    .environment(\.theme, Theme())
    .modelContainer(container)
}
