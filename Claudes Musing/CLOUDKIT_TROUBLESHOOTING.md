# CloudKit Sync Troubleshooting Guide

## Understanding CloudKit Sync Speed

### Why is sync slow?

CloudKit sync with SwiftData is **not instant**. Here's what to expect:

- **First sync**: Can take 30 seconds to several minutes
- **Subsequent syncs**: Usually 10-30 seconds
- **Background syncs**: Happen automatically when app is in background, can be slower
- **Network dependent**: Slow internet = slow sync

### SwiftData + CloudKit Architecture

Your app uses SwiftData with CloudKit sync, which means:

1. **Local-first**: All changes are saved locally immediately
2. **Background sync**: CloudKit syncs in the background automatically
3. **System-managed**: iOS decides when to sync based on network, battery, and usage patterns
4. **Conflict resolution**: CloudKit automatically resolves conflicts (last-write-wins)

## Common Issues and Solutions

### Issue 1: Data not syncing between devices

**Symptoms:**
- Play a game on iPhone, stats don't appear on iPad
- Complete a puzzle on iPad, progress missing on iPhone

**Solutions:**

1. **Check iCloud account**
   - Settings → [Your Name] → iCloud
   - Verify same Apple Account on both devices
   - Ensure iCloud Drive is enabled

2. **Check network connectivity**
   - Both devices must be online
   - Try switching between WiFi and cellular
   - Check if other iCloud services are syncing (Photos, Notes)

3. **Force a sync**
   - Open CloudKit Info screen
   - Tap the bug icon (🐞) in the top left
   - Tap "Force CloudKit Sync"
   - Wait 30 seconds, then check other device

4. **Refresh data on receiving device**
   - Close and reopen the app
   - Pull to refresh if available
   - Check the debug screen to see last sync time

### Issue 2: Old data showing on new device

**Symptoms:**
- Set up new device, seeing stale data
- Game state from yesterday, not current state

**Solutions:**

1. **Wait for sync**
   - Initial sync can take 2-3 minutes
   - Keep app open and in foreground
   - Both devices should be plugged in (iOS prioritizes sync when charging)

2. **Verify data is current on source device**
   - Go to debug screen on source device
   - Check "Last Updated" timestamps
   - If old, play a game to trigger a save

3. **Trigger a fresh sync**
   - On source device: Force CloudKit sync
   - Wait 30 seconds
   - On receiving device: Close and reopen app
   - Check debug screen for updated timestamps

### Issue 3: Conflicts causing data loss

**Symptoms:**
- Stats reset to lower numbers
- Game progress disappeared
- Settings keep reverting

**Root cause:** Both devices modified data while offline, CloudKit resolved conflict incorrectly

**Solutions:**

1. **Prevention (best approach)**
   - Try to use one device at a time for active play
   - Let one device finish syncing before using another
   - Check debug screen to verify sync completed

2. **Recovery**
   - Unfortunately, CloudKit uses "last write wins" - lost data can't be recovered
   - Going forward, be more careful about letting sync complete

### Issue 4: Sync completely broken

**Symptoms:**
- No sync events in debug screen
- "Last Sync" shows "Never"
- Data never appears on second device

**Solutions:**

1. **Verify CloudKit is configured in Xcode**
   - Open project in Xcode
   - Select target → Signing & Capabilities
   - Verify iCloud capability is enabled
   - Verify CloudKit is checked
   - Verify container exists: `iCloud.com.yourcompany.Sydoku`

2. **Check CloudKit Dashboard**
   - Go to https://icloud.developer.apple.com
   - Sign in with your Apple Developer account
   - Select your app's container
   - Check for errors in the logs

3. **Verify entitlements**
   - Make sure your app is properly signed
   - Check that entitlements file includes iCloud/CloudKit

4. **Reset CloudKit Development Environment** (if in development)
   - CloudKit Dashboard → Development → Reset
   - **WARNING**: This deletes ALL development data
   - Reinstall app on all devices

## Best Practices for Reliable Sync

### 1. Give sync time to complete
- After important actions (completing a game, updating stats), stay in app for 30 seconds
- Check debug screen to verify "Last Sync" updated

### 2. Keep app updated
- Sync happens more reliably when app is running
- Keep app open for a minute after major changes
- Background sync is less reliable

### 3. Use one device at a time (when possible)
- Start game on iPhone → finish on iPhone → let sync complete
- Then switch to iPad
- Reduces conflict potential

### 4. Monitor sync status
- Use the debug screen (bug icon 🐞)
- Check "Last Sync" times match your expectations
- Watch for error messages in sync events

### 5. Stay connected
- Sync requires internet
- WiFi is more reliable than cellular for large syncs
- Both devices need to be online simultaneously (or within a reasonable time window)

## Debug Screen Reference

### CloudKit Status Section
- **Account Status**: Shows if iCloud account is available
- **Last Sync**: When the last sync operation completed
- **Syncing**: Shows if sync is currently in progress

### Data Status Section
- **Statistics**: Shows if game stats are loaded and when they were last updated
- **Saved Game**: Shows if there's a saved game and when it was last saved
- **Settings**: Shows if settings are loaded and when they were last updated

### Recent Sync Events
- Lists the last 20 sync operations
- Look for:
  - 💾 Save events: When data was saved locally
  - 📥 Fetch events: When data was loaded
  - ☁️ Sync events: When CloudKit sync was triggered
  - ❌ Error events: When something went wrong

### Actions
- **Refresh Data**: Reload data from SwiftData (local database)
- **Force CloudKit Sync**: Manually trigger a sync to iCloud
- **Check Account Status**: Re-check your iCloud account status

## Testing Sync

### Step-by-step testing procedure:

1. **Setup**
   - Install app on Device A and Device B
   - Sign into same iCloud account on both
   - Open app on both devices
   - Verify CloudKit Status shows "Connected" on both

2. **Test Device A → Device B**
   - On Device A: Start a new game
   - Play for a bit, make some moves
   - Pause the game (it auto-saves)
   - Open debug screen, tap "Force CloudKit Sync"
   - Wait for "Last Sync" to update (should be < 10 seconds ago)
   - **Wait 30 seconds**
   - On Device B: Close and reopen the app
   - On Device B: Open debug screen
   - Check "Saved Game" - should show "Saved: X seconds ago"
   - Go to main screen - should see "Continue Game" option

3. **Test Device B → Device A**
   - Repeat above process in reverse
   - This confirms bidirectional sync works

4. **Test Statistics Sync**
   - On Device A: Complete a puzzle
   - Force sync, wait 30 seconds
   - On Device B: Reopen app, check stats screen
   - Stats should match Device A

## Still Having Issues?

### Check Console Logs
In Xcode, you can view detailed logs:
1. Window → Devices and Simulators
2. Select your device
3. View device logs
4. Filter for "CloudKit" or "SwiftData"
5. Look for errors or warnings

### Things to verify:
- [ ] Same iCloud account on both devices
- [ ] iCloud Drive enabled in Settings
- [ ] App has iCloud capability in Xcode
- [ ] CloudKit container configured properly
- [ ] Both devices connected to internet
- [ ] Waited at least 30 seconds after force sync
- [ ] Closed and reopened receiving app
- [ ] Timestamps in debug screen are recent

### Known Limitations
1. **Sync is not real-time** - Expect delays of 10-30+ seconds
2. **Background sync is unreliable** - Keep app open when possible
3. **No merge conflicts** - Last write wins, can cause data loss if both devices modify simultaneously
4. **System controlled** - iOS decides when to sync, you can't fully control it
5. **Network dependent** - Poor internet = slow/failed sync

## Advanced: Manual Conflict Resolution

If you need more control over conflicts (future enhancement), you would need to:

1. Add version numbers or timestamps to all models
2. Implement custom merge logic in PersistenceService
3. Use CloudKit's `CKFetchRecordChangesOperation` for more control
4. Handle conflicts explicitly instead of relying on automatic resolution

This is not currently implemented, but could be added if needed.

---

**Remember**: CloudKit sync is designed for convenience, not real-time collaboration. It works great for syncing data over time between devices, but it's not instant messaging. Be patient, give it time, and use the debug tools to monitor what's happening!
