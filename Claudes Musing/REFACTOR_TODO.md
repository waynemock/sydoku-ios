# Refactor TODO - Update These Files

## Immediate Actions Required

### 1. Rename File in Xcode
- **Current:** `CompletedGame.swift`
- **New Name:** `Game.swift`
- Right-click file in Xcode → Refactor → Rename

### 2. Delete Obsolete File
- Delete `SavedGameState.swift` from your project

### 3. Update App Entry Point

Find your `@main` app struct and update the model container:

```swift
// BEFORE
.modelContainer(for: [SavedGameState.self, CompletedGame.self, GameStatistics.self, UserSettings.self])

// AFTER
.modelContainer(for: [Game.self, GameStatistics.self, UserSettings.self])
```

### 4. Update Files That Reference Old Code

Run a project-wide search (Cmd+Shift+F) for each of these and update:

#### Search: `SavedGameState`
Replace with: `Game`

#### Search: `CompletedGame`
Replace with: `Game`

#### Search: `fetchSavedGame`
Replace with: `fetchInProgressGame`

#### Search: `saveGame(`
Replace with: `saveInProgressGame(`

#### Search: `deleteSavedGame`
Replace with: `deleteInProgressGame`

#### Search: `hasSavedGame`
Replace with: `hasInProgressGame`

#### Search: `syncSavedGameFromCloudKit`
Replace with: `syncInProgressGameFromCloudKit`

### 5. Known Files to Update

Based on the searches we did, these files likely need updates:

- `MainView.swift` - probably uses `fetchSavedGame()`, `hasSavedGame()`
- `NumberPad.swift` - might reference saved game state
- `SudokuGame.swift` - likely saves/loads games
- Any views showing game history

### 6. Update Model Context Queries

Look for any direct `FetchDescriptor` usage:

```swift
// BEFORE
let descriptor = FetchDescriptor<SavedGameState>(...)
let descriptor = FetchDescriptor<CompletedGame>(...)

// AFTER  
let descriptor = FetchDescriptor<Game>(
    predicate: #Predicate { !$0.isCompleted }  // for in-progress
)
let descriptor = FetchDescriptor<Game>(
    predicate: #Predicate { $0.isCompleted }   // for completed
)
```

### 7. Test CloudKit Sync

After changes:
1. Run app on Device 1
2. Start a game, let it auto-save
3. Open app on Device 2
4. Verify game syncs correctly
5. Complete the game on Device 2
6. Check Device 1 shows it in history

### 8. Build and Fix Errors

After making these changes:
1. Build the project (Cmd+B)
2. Fix any compiler errors
3. Look for any deprecated method calls
4. Update parameter names if needed

## Optional Enhancements

### Consider Adding (Future)
- Migration code to convert old `SavedGameState` records to `Game`
- Support for multiple in-progress games (just remove the delete in `saveInProgressGame`)
- Query optimizations with indexes on `isCompleted`, `completionDate`

## Rollback Plan

If you need to revert:
1. Git revert these commits
2. Or restore these files from version control:
   - `CompletedGame.swift` (old version)
   - `SavedGameState.swift`
   - `PersistenceService.swift` (old version)
   - `CloudKitService.swift` (old version)

---

**Status:** 🚧 In Progress  
**Priority:** High - Required before next app run  
**Estimated Time:** 30-60 minutes
