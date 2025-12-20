# Data Persistence Architecture

## Before CloudKit (UserDefaults)

```
┌──────────────────────────────────────────┐
│           SudokuGame                     │
│  ┌────────────────────────────────────┐  │
│  │  @Published var stats: GameStats   │  │
│  │  @Published var settings: ...      │  │
│  └───────────────┬────────────────────┘  │
│                  │                        │
│            saveStats()                    │
│            loadStats()                    │
│                  │                        │
│                  ▼                        │
│  ┌────────────────────────────────────┐  │
│  │       JSONEncoder/Decoder          │  │
│  └───────────────┬────────────────────┘  │
└──────────────────┼───────────────────────┘
                   │
                   ▼
        ┌─────────────────────┐
        │   UserDefaults      │ ← Local only, no sync
        │   (This Device)     │
        └─────────────────────┘
```

## After CloudKit (SwiftData)

```
┌──────────────────────────────────────────────────────────────┐
│                     Your Sydoku App                          │
│                                                              │
│  ┌────────────────────────────┐                             │
│  │       SudokuGame           │                             │
│  │                            │                             │
│  │  @Published stats/settings │ ← For UI updates           │
│  │  (GameStats/GameSettings)  │                             │
│  └──────────┬─────────────────┘                             │
│             │                                                │
│             ▼                                                │
│  ┌────────────────────────────┐                             │
│  │    PersistenceService      │ ← Manages all persistence   │
│  │                            │                             │
│  │  - fetchOrCreateStats()    │                             │
│  │  - saveStatistics()        │                             │
│  │  - saveGame()              │                             │
│  │  - fetchSavedGame()        │                             │
│  └──────────┬─────────────────┘                             │
│             │                                                │
│             ▼                                                │
│  ┌────────────────────────────┐                             │
│  │      StatsAdapter          │ ← Converts between formats  │
│  │   SettingsAdapter          │                             │
│  └──────────┬─────────────────┘                             │
│             │                                                │
│             ▼                                                │
│  ┌────────────────────────────┐                             │
│  │   SwiftData Models         │                             │
│  │                            │                             │
│  │  - GameStatistics          │ ← @Model classes           │
│  │  - SavedGameState          │                             │
│  │  - UserSettings            │                             │
│  └──────────┬─────────────────┘                             │
│             │                                                │
│             ▼                                                │
│  ┌────────────────────────────┐                             │
│  │     ModelContext           │ ← SwiftData context        │
│  │    ModelContainer          │                             │
│  └──────────┬─────────────────┘                             │
└─────────────┼──────────────────────────────────────────────┘
              │
              │ Automatic Sync ⚡
              │
              ▼
   ┌─────────────────────────┐
   │      iCloud             │
   │   CloudKit Private DB   │ ← Secure, encrypted storage
   │                         │
   │  - CD_GameStatistics    │   Record types created
   │  - CD_SavedGameState    │   automatically by SwiftData
   │  - CD_UserSettings      │
   └─────────┬───────────────┘
             │
             │ Automatic Sync ⚡
             │
             ▼
   ┌─────────────────────────┐
   │   Other Devices         │
   │   (iPad, Mac, etc.)     │ ← Same iCloud account
   │                         │
   │   SwiftData Models      │   Data appears automatically
   │   & SudokuGame          │
   └─────────────────────────┘
```

## Key Components

### 1. PersistenceService
- Single source of truth for data operations
- Handles automatic migration from UserDefaults
- Manages SwiftData CRUD operations
- Triggers CloudKit sync automatically

### 2. Adapters (StatsAdapter, SettingsAdapter)
- Bridge between old struct-based code and new SwiftData models
- Allows gradual migration without rewriting entire codebase
- Converts data bidirectionally

### 3. SwiftData Models (@Model classes)
- GameStatistics: Stores game performance metrics
- SavedGameState: Stores in-progress games
- UserSettings: Stores user preferences
- Automatically synced to CloudKit when using `.cloudKitDatabase: .automatic`

### 4. CloudKit Integration
- Configured in SydokuApp.swift via ModelConfiguration
- Uses private database (user's iCloud account)
- Automatic conflict resolution
- Efficient delta syncing

## Data Flow Examples

### Saving Game Statistics

```
User completes game
       ↓
SudokuGame.recordWin() updates stats struct
       ↓
SudokuGame.saveStats() calls PersistenceService
       ↓
StatsAdapter.updateModel() copies data to GameStatistics model
       ↓
PersistenceService.saveStatistics() saves to ModelContext
       ↓
ModelContext.save() persists to local database
       ↓
CloudKit automatically syncs to iCloud
       ↓
Other devices receive push notification
       ↓
Other devices automatically fetch and update data
```

### Loading Data on App Launch

```
App launches
       ↓
MainView creates SudokuGame
       ↓
MainView calls game.configurePersistence()
       ↓
PersistenceService.fetchOrCreateStatistics()
       ↓
Check if SwiftData model exists
       │
       ├─ YES → Return existing model
       │
       └─ NO  → Check UserDefaults (legacy data)
              │
              ├─ Found → Migrate to SwiftData, delete from UserDefaults
              │
              └─ Not Found → Create new empty model
       ↓
StatsAdapter.toStruct() converts to GameStats
       ↓
SudokuGame.stats = converted struct
       ↓
UI displays statistics
```

## CloudKit Sync Timeline

```
Device A                    iCloud                      Device B
────────                    ──────                      ────────

[User plays game]
      │
      ├─ Save to SwiftData
      │
      └─ Trigger sync ──────────►
                                  │
                                  ├─ Receive changes
                                  │
                                  ├─ Store in CloudKit DB
                                  │
                                  ├─ Send push notification ────►
                                                                  │
                                                                  ├─ Receive notification
                                                                  │
                                                                  ├─ Fetch changes
                                                                  │
                                                                  └─ Update SwiftData
                                                                      │
                                                                      └─ UI auto-updates

Time: ~5-30 seconds for typical sync
```

## Migration Process (First Launch)

```
                    App Launch
                        │
                        ▼
        ┌───────────────────────────┐
        │  Check SwiftData Models   │
        └───────────┬───────────────┘
                    │
          ┌─────────┴─────────┐
          │                   │
    Models Exist?        Models Don't Exist
          │                   │
          ▼                   ▼
   Use existing      Check UserDefaults
                             │
                    ┌────────┴────────┐
                    │                 │
              Data Found?        No Data Found
                    │                 │
                    ▼                 ▼
        ┌────────────────────┐   Create new
        │  MIGRATE DATA      │   empty models
        │                    │
        │ 1. Read UserDefaults│
        │ 2. Create Models   │
        │ 3. Insert to SD    │
        │ 4. Delete from UD  │
        │ 5. Save to SD      │
        └────────────────────┘
                    │
                    ▼
         ┌──────────────────────┐
         │ CloudKit syncs data  │
         │ to user's iCloud     │
         └──────────────────────┘
                    │
                    ▼
              All devices
              receive data!
```

## Privacy & Security

```
User's Device                     Apple's Servers
─────────────                     ───────────────

[Game Data] ─────Encrypted────► [CloudKit Private DB]
                                         │
                   End-to-End           │
                    Encrypted           │
                                         │
                                         │
                                   Only accessible
                                   by this user's
                                   iCloud account
```

- Data stored in **private** CloudKit database
- Encrypted in transit and at rest
- Only accessible with user's iCloud credentials
- Not visible to other users or developers
- Complies with Apple's privacy guidelines

## Benefits Summary

### For Users:
- ✅ Data syncs across iPhone, iPad, Mac
- ✅ Automatic backup to iCloud
- ✅ No manual export/import needed
- ✅ Works offline, syncs later
- ✅ Free with iCloud account

### For Developers:
- ✅ SwiftData handles database operations
- ✅ CloudKit handles sync logic
- ✅ Automatic conflict resolution
- ✅ Push notifications for changes
- ✅ Minimal code to maintain
