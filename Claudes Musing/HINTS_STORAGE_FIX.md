# Hints Storage Fix

## Problem
The completed game history was only saving the **count** of hints used (`hintsUsed: Int`), but not the full grid showing **which cells** had hints applied. This means we couldn't later visualize or analyze where hints were used in a completed game.

## Solution
Updated the system to store both:
1. **`hintsData: [Int]`** - The full 9x9 hints grid (flattened to an array) showing which cells had hints
2. **`hintsUsed: Int`** - A convenience count computed from the hints grid

## Files Changed

### 1. `CompletedGame.swift`
**Added:**
- `hintsData: [Int]` property to store the flattened hints grid
- Updated initializer to accept `hintsData` parameter

**Before:**
```swift
var hintsUsed: Int = 0
```

**After:**
```swift
var hintsData: [Int] = []
var hintsUsed: Int = 0  // Computed for convenience
```

### 2. `PersistenceService.swift`
**Updated `saveCompletedGame()` method:**
- Changed parameter from `hintsUsed: Int` to `hints: [[Int]]` (the full grid)
- Flattens the hints grid for storage: `let hintsData = CompletedGame.flatten(hints)`
- Counts hints from the grid for the convenience property
- Passes both `hintsData` and `hintsUsed` to `CompletedGame` initializer

**Before:**
```swift
func saveCompletedGame(
    ...
    mistakes: Int,
    hintsUsed: Int,  // ❌ Only the count
    ...
)
```

**After:**
```swift
func saveCompletedGame(
    ...
    mistakes: Int,
    hints: [[Int]],  // ✅ Full grid
    ...
) {
    let hintsData = CompletedGame.flatten(hints)
    
    // Count hints for summary
    var hintsUsedCount = 0
    for row in hints {
        for cell in row {
            if cell == 1 {
                hintsUsedCount += 1
            }
        }
    }
    
    let completedGame = CompletedGame(
        ...
        hintsData: hintsData,
        hintsUsed: hintsUsedCount,
        ...
    )
}
```

### 3. `SudokuGame.swift`
**Updated `checkCompletion()` method:**
- Now passes the full `hints` grid instead of counting it first
- The counting is done in `PersistenceService` instead

**Before:**
```swift
// Count hints used
var hintsUsedCount = 0
for row in hints {
    for cell in row {
        if cell == 1 {
            hintsUsedCount += 1
        }
    }
}

persistenceService?.saveCompletedGame(
    ...
    hintsUsed: hintsUsedCount,  // ❌ Only the count
    ...
)
```

**After:**
```swift
persistenceService?.saveCompletedGame(
    ...
    hints: hints,  // ✅ Full grid
    ...
)
```

## Benefits

1. **Complete Data Preservation**: The full hints grid is now stored in the database
2. **Future Features**: You can now implement:
   - Visual replay showing where hints were used
   - Statistics on which cells commonly need hints
   - Analysis of hint patterns by difficulty
   - Comparison of hint usage across games
3. **Backward Compatible**: Still provides `hintsUsed` count for simple displays
4. **CloudKit Sync**: The hints grid will sync across devices like all other game data

## Data Structure

The hints grid is a 9x9 array where:
- `0` = No hint used in this cell
- `1` = Hint was used in this cell

Example:
```swift
hints[3][5] = 1  // User used a hint at row 3, column 5
```

When stored in `CompletedGame`:
```swift
hintsData = [0,0,0,0,0,1,0,0,0, ...]  // Flattened 9x9 grid (81 elements)
hintsUsed = 1  // Count of hints (convenience property)
```

## Testing

After completing a game with hints, you can verify:
```swift
let games = persistenceService.fetchCompletedGames()
if let game = games.first {
    print("Hints used: \(game.hintsUsed)")
    let hintsGrid = CompletedGame.unflatten(game.hintsData)
    // hintsGrid is now a 9x9 array showing where hints were used
}
```

## Migration Note

This is a **schema change** to the `CompletedGame` model. SwiftData will handle this automatically, but:
- Existing completed games won't have `hintsData` (will be empty array)
- New completed games will have full hints data
- No data loss - existing games still have `hintsUsed` count
