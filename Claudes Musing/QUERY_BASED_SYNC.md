# Query-Based Sync Implementation

## The Issue
iPad wasn't picking up new games started on iPhone because it was only checking for its own local game's ID in CloudKit, not discovering new games from other devices.

## The Solution
Changed to **query-based sync** that queries CloudKit for all in-progress games and picks the most recent one.

### CloudKit Fields to Make Queryable

In CloudKit Dashboard, make these fields queryable for the `Game` record type:
- `isCompleted` (Int64) - **Required** for querying in-progress games
- `lastSaved` (Date/Time) - **Optional but recommended** for sorting by most recent

### Changes Made

#### 1. CloudKitService.swift
Added `downloadInProgressGames()` method:
```swift
func downloadInProgressGames() async throws -> [CloudKitGame] {
    // Query: isCompleted == 0
    // Sort: lastSaved descending
    // Returns: All in-progress games, newest first
}
```

#### 2. PersistenceService.swift
Updated `syncInProgressGameFromCloudKit()` to:
1. Query for all in-progress games in CloudKit
2. Pick the most recent one (first in sorted results)
3. Compare with local game:
   - **No local game:** Create from CloudKit
   - **Same game ID:** Update if CloudKit is newer
   - **Different game ID:** Replace local with CloudKit game

### How It Works Now

**Scenario: Start game on iPhone, switch to iPad**

1. **iPhone:** Creates game with UUID `"ABC-123"`, uploads to CloudKit
2. **iPad foregrounds:** Calls `syncInProgressGameFromCloudKit()`
3. **iPad:** Queries CloudKit: `isCompleted == 0`, sorted by `lastSaved desc`
4. **CloudKit returns:** `["ABC-123"]` (most recent in-progress game)
5. **iPad:** No local game, creates from CloudKit with ID `"ABC-123"`
6. **Result:** ✅ iPad now has the same game as iPhone!

**Scenario: Play on iPhone, then iPad**

1. **iPhone:** Updates game `"ABC-123"` at 13:42:07
2. **iPad foregrounds:** Has local game `"ABC-123"` from 13:42:02
3. **iPad:** Queries CloudKit, gets `"ABC-123"` from 13:42:07
4. **iPad:** Same ID, CloudKit newer → updates local game
5. **Result:** ✅ iPad has latest progress from iPhone!

**Scenario: Start new game on iPhone while iPad has old game**

1. **iPad:** Has local game `"OLD-999"`
2. **iPhone:** Starts new game `"NEW-123"` at 13:45:00
3. **iPad foregrounds:** Queries CloudKit
4. **CloudKit returns:** `"NEW-123"` (most recent)
5. **iPad:** Different ID, CloudKit is newer → deletes `"OLD-999"`, creates `"NEW-123"`
6. **Result:** ✅ iPad switches to iPhone's new game!

### CloudKit Dashboard Setup

1. Go to CloudKit Dashboard
2. Select your container
3. Go to Schema → Record Types → Game
4. Find the `isCompleted` field
5. Check "Queryable" and "Sortable"
6. Find the `lastSaved` field (optional)
7. Check "Queryable" and "Sortable"
8. Deploy to Production

### Error Handling

If CloudKit queries fail (e.g., fields not queryable):
- Error is caught and logged
- Returns local game if available
- App continues to function with local data
- Sync will retry on next foreground

### Benefits

1. ✅ **Discovery:** iPad finds new games from iPhone automatically
2. ✅ **Latest Wins:** Always uses most recently saved game across devices
3. ✅ **Automatic Switch:** Seamlessly switches to newest game from any device
4. ✅ **Completion Detection:** Still checks if local game was completed elsewhere
5. ✅ **Error Resilient:** Falls back to local data on query failures

### Testing

- [ ] Make `isCompleted` and `lastSaved` queryable in CloudKit Dashboard
- [ ] Start game on iPhone
- [ ] Foreground iPad → Should automatically load iPhone's game
- [ ] Play on iPad
- [ ] Foreground iPhone → Should see iPad's progress
- [ ] Complete on iPhone
- [ ] Foreground iPad → Should show as completed
- [ ] Start new game on iPhone while iPad has old game
- [ ] Foreground iPad → Should switch to new game
