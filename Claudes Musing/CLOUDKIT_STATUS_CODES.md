# CloudKit Account Status Codes

## Quick Reference

When you see `accountStatus=4` in the logs, here's what it means:

| Code | Status | Description |
|------|--------|-------------|
| **0** | `couldNotDetermine` | The system couldn't determine the iCloud account status. This is the initial state before checking. |
| **1** | `available` | ✅ **iCloud is working!** The user is signed in and CloudKit is ready to sync. |
| **2** | `restricted` | ⚠️ iCloud access is restricted (parental controls, MDM profile, etc.) |
| **3** | `noAccount` | ⚠️ User is not signed into iCloud on this device |
| **4** | `temporarilyUnavailable` | ⚠️ iCloud is temporarily unavailable (network issues, Apple service outage, etc.) |

## What You're Seeing

```
CloudKitStatus.requestAccountStatus(): accountStatus=4
```

This means: **`temporarilyUnavailable`** - iCloud is temporarily unavailable.

### Common Causes

1. **No internet connection** - Device is offline
2. **Apple service issues** - Rare, but iCloud can have outages
3. **Transitioning states** - Just signed in/out of iCloud
4. **VPN or network restrictions** - Corporate network blocking iCloud

### What Happens in the App

When status is `temporarilyUnavailable` (code 4):
- ✅ App continues to work with **local data**
- ✅ Changes are saved locally
- ✅ When connection returns, data syncs automatically
- ℹ️ User sees "Playing offline with local data" banner

## Updated Logging

The logging now shows human-readable status:

**Before:**
```
CloudKitStatus.requestAccountStatus(): accountStatus=4
```

**After:**
```
CloudKitStatus.requestAccountStatus(): accountStatus=temporarilyUnavailable (code: 4)
```

## Testing Different States

### Simulate `noAccount` (code 3)
1. Settings → Apple ID
2. Sign out of iCloud

### Simulate `temporarilyUnavailable` (code 4)
1. Enable Airplane Mode
2. Or disconnect from WiFi/cellular

### Simulate `available` (code 1)
1. Ensure signed into iCloud
2. Ensure network connection
3. Wait a moment for status to update

## In Your Code

You can access the friendly description in SwiftUI:

```swift
@EnvironmentObject var cloudKitStatus: CloudKitStatus

var body: some View {
    Text(cloudKitStatus.statusDescription)
    // Shows: "iCloud is temporarily unavailable"
}
```

Or check availability:

```swift
if cloudKitStatus.isAvailable {
    // Code 1 - good to sync
} else {
    // Codes 0, 2, 3, or 4 - handle gracefully
}
```

## Related Files

- `CloudKitStatus.swift` - Status monitoring
- `PersistenceService.swift` - Handles offline fallback
- `MainView.swift` - Shows sync status banner to user
