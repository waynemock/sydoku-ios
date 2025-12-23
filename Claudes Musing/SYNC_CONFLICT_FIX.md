# CloudKit Sync Conflict Fix

## Problem

When a game was completed on Device A but Device B had an older, unfinished version:

1. **Device A** completes game → saves as completed → deletes in-progress game → syncs to CloudKit
2. **Device B** launches → loads old in-progress game from local SwiftData
3. **Device B** saves the stale data → overwrites CloudKit
4. **Device A** syncs back → gets the stale in-progress game again (completed game is lost!)

This created a frustrating loop where completed games would "revert" to in-progress state.

## Root Cause

The app was loading local data **before** checking CloudKit for updates:

```swift
// OLD ORDER (problematic):
func configurePersistence(persistenceService: PersistenceService) {
    self.persistenceService = persistenceService
    checkForSavedGame()  // ❌ Loads stale local data first
}
```

## Solution

We implemented a three-part fix:

### 1. Sync from CloudKit First (SudokuGame.swift)

Changed the initialization order to sync from CloudKit **before** loading local data:

```swift
// NEW ORDER (fixed):
func configurePersistence(persistenceService: PersistenceService) {
    self.persistenceService = persistenceService
    
    // Sync from CloudKit FIRST
    Task {
        await syncAllFromCloudKit()
        
        // Only check local if CloudKit had no game (offline case)
        if !hasSavedGame {
            await MainActor.run {
                checkForSavedGame()
            }
        }
    }
}
```

### 2. Delete Stale Local Games (PersistenceService.swift)

When CloudKit has no in-progress game, we now delete any stale local game:

```swift
func syncInProgressGameFromCloudKit() async -> Game? {
    guard let cloudKitGame = try await cloudKitService.downloadInProgressGame() else {
        // No game in CloudKit
        if let localGame = fetchInProgressGame() {
            // Local game exists but CloudKit doesn't have it
            // This means it was completed/deleted on another device
            syncMonitor.logSync("⚠️ Deleting stale local in-progress game")
            deleteInProgressGame()
        }
        return nil
    }
    // ... rest of sync logic
}
```

### 3. Prevent Overwriting Completed Games (SudokuGame.swift)

Added a safety check to prevent saving over a completed game:

```swift
func saveGame() {
    if isComplete || isGameOver {
        return
    }
    
    // Check if the game has been completed elsewhere
    if let existingGame = persistenceService?.fetchInProgressGame() {
        if existingGame.isCompleted {
            print("⚠️ Prevented saving over completed game")
            deleteSavedGame()
            return
        }
    }
    
    // ... save logic
}
```

## How It Works Now

### Scenario: Game Completed on Device A

1. **Device A** completes game → saves as completed → deletes in-progress → syncs to CloudKit
2. **Device B** launches → `configurePersistence()` called
3. **Device B** syncs from CloudKit → finds NO in-progress game
4. **Device B** checks local storage → finds stale in-progress game
5. **Device B** deletes the stale local game (it was completed on Device A)
6. **Device B** shows "no saved game" correctly ✅

### Scenario: Game Updated on Device A

1. **Device A** makes moves → debounced save → syncs to CloudKit
2. **Device B** launches → syncs from CloudKit
3. **Device B** gets fresh game data with newer timestamp
4. **Device B** updates local storage with CloudKit data
5. **Device B** shows the latest game state ✅

### Scenario: Offline Mode

1. **Device** has no internet → CloudKit sync fails/times out
2. **Device** falls back to local storage → loads last known state
3. **Device** can still play offline
4. When connectivity returns → syncs with CloudKit ✅

## Testing Checklist

- [ ] Complete a game on Device A, launch Device B → should not show old game
- [ ] Start a game on Device A, continue on Device B → should see latest moves
- [ ] Make moves on Device A, immediately open Device B → should sync correctly
- [ ] Complete a game on Device A while Device B is running → Device B should detect deletion on foreground
- [ ] Test offline mode → should fall back to local data gracefully

## Technical Details

### Sync Order

The app now follows this sequence on launch:

1. Initialize persistence service
2. Load statistics and settings (these always exist)
3. **Sync from CloudKit** (settings, statistics, game)
4. Only if CloudKit has no game → check local storage
5. Show appropriate UI based on results

### Timestamp Comparison

All sync operations use `lastSaved` timestamps to determine which version is newer:

- CloudKit timestamp > Local timestamp → Use CloudKit data
- Local timestamp > CloudKit timestamp → Keep local data (it's newer)
- No CloudKit data → Check if local should be deleted (completed elsewhere)

### Performance Impact

- Initial launch may be slightly slower due to CloudKit sync
- This is acceptable for correctness and data consistency
- Offline mode still works (falls back to local data)
- Background sync still happens for quick updates

## Related Files

- `SudokuGame.swift` - Main game controller with sync logic
- `PersistenceService.swift` - Data persistence and CloudKit sync
- `Game.swift` - SwiftData model for games
- `CloudKitService.swift` - CloudKit communication layer

## Future Improvements

- Add conflict resolution UI if timestamps are very close
- Implement optimistic locking with version numbers
- Add user notification when syncing resolves a conflict
- Cache CloudKit responses for faster subsequent launches
