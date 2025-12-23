# Game Model Refactor - Migration Guide

## Overview

We've successfully refactored the persistence layer to use a **unified `Game` model** instead of separate `SavedGameState` and `CompletedGame` models. This simplifies the architecture and eliminates duplicate code while maintaining all the best practices we built.

## What Changed

### Models

#### ✅ NEW: `Game` (previously `CompletedGame.swift`, now `Game.swift`)
- **Unified model** for both in-progress and completed games
- Added `isCompleted: Bool` to distinguish game states
- Added `completionDate: Date?` (nil for in-progress games)
- Added `lastSaved: Date` for sync tracking
- Added `notesData: Data` for in-progress game notes
- Merged all functionality from both old models

#### ❌ REMOVED: `SavedGameState`
- All functionality moved to `Game` model
- File can be deleted: `SavedGameState.swift`

### PersistenceService Methods

#### In-Progress Game Methods (replacing "Saved Game")
- `fetchInProgressGame()` - replaces `fetchSavedGame()`
- `saveInProgressGame(...)` - replaces `saveGame(...)`
- `deleteInProgressGame()` - replaces `deleteSavedGame()`
- `hasInProgressGame()` - replaces `hasSavedGame()`
- `syncInProgressGameFromCloudKit()` - replaces `syncSavedGameFromCloudKit()`

#### Completed Game Methods (updated signatures)
- `saveCompletedGame(...)` - now creates `Game` with `isCompleted = true`
- `fetchCompletedGames()` - returns `[Game]` instead of `[CompletedGame]`
- `deleteCompletedGame(_ game: Game)` - takes `Game` instead of `CompletedGame`
- `deleteAllCompletedGames()` - updated to use `Game` predicate

### CloudKitService Methods

#### Game Management (unified)
- `uploadGame(_ game: Game, timestamp: Date)` - replaces `uploadSavedGame(...)`
- `downloadInProgressGame()` - replaces `downloadSavedGame()`
- `deleteInProgressGame()` - replaces `deleteSavedGame()`
- `deleteGame(gameID: String)` - new method for deleting completed games

#### CloudKit Record Structure
- Record type changed from `"SavedGame"` to `"Game"`
- In-progress games use fixed ID: `"current-in-progress-game"`
- Completed games use their unique `gameID` as record name

### Data Models

#### CloudKitGame (updated)
```swift
struct CloudKitGame {
    let initialBoardData: [Int]
    let solutionData: [Int]
    let boardData: [Int]
    let notesData: Data          // NEW
    let difficulty: String
    let elapsedTime: TimeInterval
    let startDate: Date
    let mistakes: Int
    let hintsData: [Int]
    let hintsUsed: Int
    let isDailyChallenge: Bool
    let dailyChallengeDate: String?
    let isCompleted: Bool        // NEW
    let completionDate: Date?    // NEW
    let lastSaved: Date
    let gameID: String           // NEW
}
```

## Migration Steps

### 1. Update Your Code

Search for and replace these method calls:

```swift
// OLD → NEW
persistence.fetchSavedGame()              → persistence.fetchInProgressGame()
persistence.saveGame(...)                 → persistence.saveInProgressGame(...)
persistence.deleteSavedGame()             → persistence.deleteInProgressGame()
persistence.hasSavedGame()                → persistence.hasInProgressGame()
persistence.syncSavedGameFromCloudKit()   → persistence.syncInProgressGameFromCloudKit()
```

### 2. Update Type References

```swift
// OLD
if let game: SavedGameState = ...
let games: [CompletedGame] = ...

// NEW
if let game: Game = ...
let games: [Game] = ...
```

### 3. Update Static Method Calls

```swift
// OLD
SavedGameState.flatten(...)
SavedGameState.unflatten(...)
SavedGameState.encodeNotes(...)
SavedGameState.decodeNotes(...)
CompletedGame.flatten(...)
CompletedGame.unflatten(...)

// NEW
Game.flatten(...)
Game.unflatten(...)
Game.encodeNotes(...)
Game.decodeNotes(...)
```

### 4. Update SwiftData Schema

Add `Game` to your model container configuration:

```swift
// If you have this:
ModelContainer(for: SavedGameState.self, CompletedGame.self, ...)

// Change to:
ModelContainer(for: Game.self, ...)
```

### 5. Delete Old Files

After confirming everything works:
- Delete `SavedGameState.swift`

### 6. Update CloudKit Schema (if needed)

The CloudKit record type has changed from `SavedGame` to `Game`. CloudKit will handle this automatically, but you may want to:
1. Test with a fresh CloudKit container first
2. Or manually update/migrate existing records

## Benefits of This Refactor

✅ **Simpler Architecture** - One model instead of two  
✅ **Single Source of Truth** - All games in one collection  
✅ **Better Sync** - Unified CloudKit sync logic  
✅ **More Flexible** - Could support multiple in-progress games in future  
✅ **Cleaner Code** - Less duplication, easier to maintain  
✅ **Same Best Practices** - All timestamp synchronization and retry logic preserved  

## Querying Games

### In-Progress Games
```swift
let descriptor = FetchDescriptor<Game>(
    predicate: #Predicate { !$0.isCompleted },
    sortBy: [SortDescriptor(\.lastSaved, order: .reverse)]
)
```

### Completed Games
```swift
let descriptor = FetchDescriptor<Game>(
    predicate: #Predicate { $0.isCompleted },
    sortBy: [SortDescriptor(\.completionDate, order: .reverse)]
)
```

### Specific Completed Games
```swift
let descriptor = FetchDescriptor<Game>(
    predicate: #Predicate { 
        $0.isCompleted && 
        $0.difficulty == "Easy" && 
        $0.isDailyChallenge == true 
    }
)
```

## Backward Compatibility

⚠️ **Breaking Change**: This is a schema change that requires migration.

Users upgrading from the old version will:
1. Lose their in-progress game (it will be replaced on first save)
2. Keep their completed game history (if you migrate the data)

If you need to preserve in-progress games, you'll need to:
1. Fetch existing `SavedGameState` records
2. Convert them to `Game` records with `isCompleted = false`
3. Delete old `SavedGameState` records

## Testing Checklist

- [ ] In-progress game saves correctly
- [ ] In-progress game loads on app restart
- [ ] In-progress game syncs to CloudKit
- [ ] In-progress game syncs from CloudKit
- [ ] Completing a game marks it as `isCompleted = true`
- [ ] Completed games appear in history
- [ ] Completed games sync to CloudKit
- [ ] Deleting in-progress game works
- [ ] Deleting completed games works
- [ ] Statistics update correctly
- [ ] CloudKit sync indicator works
- [ ] Multi-device sync works correctly

## Questions or Issues?

If you encounter any issues during migration, check:
1. All references to `SavedGameState` are removed
2. All references to `CompletedGame` are changed to `Game`
3. SwiftData model container includes `Game`
4. CloudKit permissions are still valid
5. The new predicate syntax is correct for your queries

---

**Created:** December 21, 2025  
**Status:** ✅ Complete - Ready for Testing
