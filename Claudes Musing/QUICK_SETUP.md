# Quick CloudKit Setup (Clean Install)

Since you're doing a clean install, this is much simpler! No migration needed.

## ✅ Files Created

1. **GameStatistics.swift** - Stores game stats in CloudKit
2. **SavedGameState.swift** - Stores in-progress games in CloudKit  
3. **UserSettings.swift** - Stores user preferences in CloudKit
4. **PersistenceService.swift** - Service for all data operations
5. **StatsAdapter.swift** - Bridges between old structs and new models

## 🔧 Setup Steps

### Step 1: Add Files to Xcode

1. In Xcode, right-click on your project folder
2. Select "Add Files to Sydoku..."
3. Add these new Swift files:
   - GameStatistics.swift
   - SavedGameState.swift
   - UserSettings.swift
   - PersistenceService.swift
   - StatsAdapter.swift

### Step 2: Enable iCloud Capability

1. Select your project in Xcode
2. Select the **Sydoku** target
3. Go to **Signing & Capabilities** tab
4. Click **+ Capability** → Add **iCloud**
5. Check ✅ **CloudKit**
6. Click **+** under **Containers**
7. Enter: `iCloud.com.yourteam.Sydoku` (use your actual team/bundle ID)

### Step 3: Update SudokuGame.swift

Replace UserDefaults persistence with SwiftData. Here are the key changes:

#### Add properties:
```swift
class SudokuGame: ObservableObject {
    // Add these properties
    private var persistenceService: PersistenceService?
    private var statsModel: GameStatistics?
    private var settingsModel: UserSettings?
    
    // Keep existing @Published properties for UI
    @Published var stats = GameStats()
    @Published var settings = GameSettings()
    // ... rest of properties
```

#### Add configuration method:
```swift
func configurePersistence(persistenceService: PersistenceService) {
    self.persistenceService = persistenceService
    
    // Load from SwiftData
    statsModel = persistenceService.fetchOrCreateStatistics()
    stats = StatsAdapter.toStruct(from: statsModel!)
    
    settingsModel = persistenceService.fetchOrCreateSettings()
    settings = SettingsAdapter.toStruct(from: settingsModel!)
    
    // Check for saved game
    checkForSavedGame()
}
```

#### Replace saveStats():
```swift
private func saveStats() {
    guard let statsModel = statsModel else { return }
    StatsAdapter.updateModel(statsModel, from: stats)
    persistenceService?.saveStatistics(statsModel)
}
```

#### Replace saveSettings():
```swift
func saveSettings() {
    guard let settingsModel = settingsModel else { return }
    SettingsAdapter.updateModel(settingsModel, from: settings)
    persistenceService?.saveSettings(settingsModel)
}
```

#### Replace saveGame():
```swift
func saveGame() {
    guard !isComplete && !isGameOver else { return }
    
    persistenceService?.saveGame(
        board: board,
        notes: notes,
        solution: solution,
        initialBoard: initialBoard,
        difficulty: currentDifficulty.rawValue,
        elapsedTime: elapsedTime,
        startDate: gameStartDate,
        mistakes: mistakes,
        isDailyChallenge: isDailyChallenge,
        dailyChallengeDate: dailyChallengeDate
    )
}
```

#### Replace checkForSavedGame():
```swift
private func checkForSavedGame() {
    if let savedGame = persistenceService?.fetchSavedGame() {
        board = SavedGameState.unflatten(savedGame.boardData)
        notes = SavedGameState.decodeNotes(savedGame.notesData)
        solution = SavedGameState.unflatten(savedGame.solutionData)
        initialBoard = SavedGameState.unflatten(savedGame.initialBoardData)
        if let difficulty = Difficulty(rawValue: savedGame.difficulty) {
            currentDifficulty = difficulty
        }
        elapsedTime = savedGame.elapsedTime
        gameStartDate = savedGame.startDate
        mistakes = savedGame.mistakes
        isDailyChallenge = savedGame.isDailyChallenge
        dailyChallengeDate = savedGame.dailyChallengeDate
        hasSavedGame = true
    } else {
        hasSavedGame = false
    }
}
```

#### Replace deleteSavedGame():
```swift
func deleteSavedGame() {
    persistenceService?.deleteSavedGame()
    hasSavedGame = false
}
```

#### Remove these methods (no longer needed):
```swift
// DELETE THESE:
private func loadStats() { ... }
private func loadSettings() { ... }
```

### Step 4: Update MainView (or wherever you create SudokuGame)

```swift
struct MainView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var game = SudokuGame()
    
    var body: some View {
        // Your existing UI
        // ...
        .onAppear {
            let persistence = PersistenceService(modelContext: modelContext)
            game.configurePersistence(persistenceService: persistence)
        }
    }
}
```

### Step 5: Delete and Reinstall

1. Delete the app from all your devices
2. Build and install the new version
3. Data will now be stored in CloudKit!

## ✨ Testing Sync

1. Install on Device 1, play a game
2. Install on Device 2 with same iCloud account
3. Wait ~10-30 seconds
4. Open app on Device 2 - your stats should appear!

## 🎉 Done!

Your Sudoku app now syncs across all devices via iCloud!

## Troubleshooting

**App crashes on launch?**
- Make sure all 5 new Swift files are added to your Xcode target
- Check the build errors - they should now be resolved

**Data not syncing?**
- Make sure you're signed into iCloud on all devices
- Check that CloudKit capability is properly configured
- Give it up to 30 seconds for first sync

**Want to verify CloudKit is working?**
- Visit [CloudKit Dashboard](https://icloud.developer.apple.com/dashboard)
- Select your container
- You should see `CD_GameStatistics`, `CD_SavedGameState`, and `CD_UserSettings` records
