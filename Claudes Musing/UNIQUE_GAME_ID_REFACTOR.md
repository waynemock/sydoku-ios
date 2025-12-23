# Unique Game ID Refactor - Eliminating Race Conditions

## Problem
The previous implementation used a **fixed ID** (`"DD507EF0-34A4-4757-9C97-B28E542E2247"`) for ALL in-progress games. This created race conditions when playing on multiple devices:

1. Device A saves game at 13:17:57 with fixed ID
2. Device B saves game at 13:17:58 with fixed ID (overwrites A's game)
3. Device A completes game and **deletes** fixed ID from CloudKit
4. Device B syncs and sees stale in-progress game (propagation delay)
5. **Result: Completed game on Device A doesn't appear as completed on Device B**

## Solution
**Use unique UUIDs for each game**, and **never delete completed games** - just mark them as `isCompleted = true`.

### Key Changes

#### 1. Unique Game IDs (`Game.swift`)
- Removed fixed `inProgressGameID` constant
- Each game gets a unique UUID when created
- The UUID is passed through saves to maintain identity
- Default game initializer uses `UUID().uuidString`

**Benefits of UUIDs:**
- ✅ Guaranteed unique across all devices
- ✅ No hash collisions
- ✅ Simple and standard
- ✅ Efficient to generate

#### 2. Upsert Logic for In-Progress Games (`PersistenceService.swift`)
**Before:** Delete existing → Create new (race condition prone)
**After:** Update existing OR create new (atomic upsert)

```swift
func saveInProgressGame(gameID: String? = nil, ...) -> String {
    // If gameID provided, try to find and update existing
    if let gameID = gameID {
        if let existingGame = try? modelContext.fetch(descriptor).first {
            // Update existing (upsert)
            existingGame.boardData = boardData
            existingGame.elapsedTime = elapsedTime
            // ... update other fields
            return gameID
        }
    }
    
    // Create new game with UUID
    let newGameID = gameID ?? UUID().uuidString
    let game = Game(gameID: newGameID, ...)
    modelContext.insert(game)
    return newGameID
}
```

**Key point:** The method now returns the gameID, which the caller should store and pass back on subsequent saves.

#### 3. Completion Marks Game Instead of Deleting (`PersistenceService.swift`)
**Before:** Delete in-progress game → Create new completed game
**After:** Update same game record with `isCompleted = true`

```swift
func saveCompletedGame(gameID: String, ...) {
    // Find and update the SAME game
    if let existingGame = try? modelContext.fetch(descriptor).first {
        existingGame.isCompleted = true
        existingGame.completionDate = completionDate
        existingGame.notesData = Data() // Clear notes
        // ... clear UI state
    }
}
```

**Key point:** The gameID must be passed to identify which game is being completed.

#### 4. Smart Sync Detects Completion (`PersistenceService.swift`)
When syncing, check if local in-progress game was completed elsewhere:

```swift
func syncInProgressGameFromCloudKit() async -> Game? {
    let allGames = try await cloudKitService.downloadAllGames()
    
    // Find in-progress games
    let inProgressGames = allGames.filter { !$0.isCompleted }
    
    // Check if local game was completed elsewhere
    if let localGame = fetchInProgressGame() {
        let completedVersion = allGames.first { 
            $0.gameID == localGame.gameID && $0.isCompleted 
        }
        
        if let completedVersion = completedVersion {
            // Update local game to completed status
            localGame.isCompleted = true
            localGame.completionDate = completedVersion.completionDate
            // ...
            return nil // No in-progress game anymore
        }
    }
}
```

#### 5. CloudKit Uses Game ID as Record Name (`CloudKitService.swift`)
**Before:** In-progress used fixed ID, completed used game ID
**After:** ALL games use their game ID as the CloudKit record name

```swift
func uploadGame(_ game: Game, timestamp: Date) async throws {
    let recordName = game.gameID // Always use gameID
    let recordID = CKRecord.ID(recordName: recordName)
    // ... upsert logic
}
```

#### 6. New Download Method (`CloudKitService.swift`)
Added `downloadAllGames()` to fetch both in-progress and completed games in one query:

```swift
func downloadAllGames() async throws -> [CloudKitGame] {
    // Query all games
    let predicate = NSPredicate(value: true)
    let query = CKQuery(recordType: RecordType.game, predicate: predicate)
    // ... fetch and parse
    return games
}
```

## Benefits

### ✅ No More Race Conditions
- Each game has a unique UUID
- Multiple devices can update the same game without conflicts
- Completion status propagates reliably

### ✅ Simpler Logic
- No need to delete in-progress games when completing
- No need to clean up CloudKit records (they just get marked completed)
- Reduces potential for sync errors

### ✅ Better Multi-Device Experience
- Device A completes game → marks `isCompleted = true`
- Device B syncs → sees same game ID with `isCompleted = true`
- Device B automatically updates local copy to completed
- **Game instantly appears as completed on all devices**

### ✅ Clearer Data Model
- One game = One record (from start to completion)
- Completion is a state change, not a record migration
- Easier to track game lifecycle

## Caller Responsibilities

The calling code (e.g., `SudokuGame`) must track the `gameID` throughout the game's lifecycle:

### Starting a New Game
```swift
// When starting a new game, don't pass a gameID
let gameID = persistenceService.saveInProgressGame(
    gameID: nil,  // Will generate new UUID
    board: board,
    // ... other params
)

// Store this gameID for future saves
self.currentGameID = gameID
```

### Saving Progress
```swift
// When auto-saving or manually saving
persistenceService.saveInProgressGame(
    gameID: self.currentGameID,  // Pass existing ID to update
    board: board,
    // ... other params
)
```

### Completing
```swift
// When completing the game
persistenceService.saveCompletedGame(
    gameID: self.currentGameID,  // Pass existing ID to mark complete
    // ... other params
)
```

### Loading from Sync
```swift
// When loading a synced game
if let syncedGame = await persistenceService.syncInProgressGameFromCloudKit() {
    self.currentGameID = syncedGame.gameID  // Store the synced game's ID
    // ... load other game data
}
```

## Migration Notes

### Existing Data
- Old games with fixed ID will continue to work
- New games will use unique IDs
- Completed games already use unique IDs (no change needed)

### CloudKit Records
- Old fixed-ID in-progress game records will be orphaned (safe to ignore)
- Can optionally clean up with a maintenance script
- New games will create properly-identified records

## Testing Checklist

- [ ] Start game on Device A → Appears on Device B
- [ ] Play game on Device A → Updates sync to Device B
- [ ] Complete game on Device A → Device B shows as completed
- [ ] Start different game on Device B while A has in-progress → Both games coexist
- [ ] Complete game on both devices (same puzzle) → Only one completed record
- [ ] Daily challenges sync correctly across devices
- [ ] Game history shows all completed games
- [ ] Statistics update correctly when completing games

## Files Changed

1. **Game.swift**
   - Removed fixed `inProgressGameID` constant
   - Added `generateGameID()` static method

2. **PersistenceService.swift**
   - `saveInProgressGame()` now uses upsert logic
   - `saveCompletedGame()` now updates existing game
   - `syncInProgressGameFromCloudKit()` checks for completed versions
   - Removed `deleteInProgressGame()` calls (no longer needed on completion)

3. **CloudKitService.swift**
   - `uploadGame()` always uses gameID as record name
   - Added `downloadAllGames()` method
   - Updated logging to include gameID

## Performance Notes

- `downloadAllGames()` fetches more data than before, but:
  - Only runs on app launch / foreground
  - Allows proper completion detection
  - Can add pagination/limits if game count grows large
  - Alternative: Keep `downloadInProgressGame()` for quick check, fallback to `downloadAllGames()` only when needed
