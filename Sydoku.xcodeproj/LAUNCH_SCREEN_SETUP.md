# Launch Screen Configuration

## Manual Setup Required

Since Info.plist can't be fully managed through code, you'll need to add these settings manually:

### Option A: Using Xcode UI (Easiest)

1. **Go to Target Settings**
   - Select your app target
   - Go to **Info** tab
   - Find **Launch Screen** section

2. **Configure Launch Screen**
   - **Background Color**: Select `LaunchBackgroundColor` (from Assets)
   - **Show App Icon**: ✅ Enable
   - **Show App Name**: ❌ Disable (we'll show it in SwiftUI)

### Option B: Editing Info.plist Source Code

Add this to your `Info.plist`:

```xml
<key>UILaunchScreen</key>
<dict>
    <key>UIColorName</key>
    <string>LaunchBackgroundColor</string>
    <key>UIImageRespectsSafeAreaInsets</key>
    <true/>
    <key>UILaunchScreen</key>
    <dict>
        <key>UIImageName</key>
        <string>AppIcon</string>
    </dict>
</dict>
```

## What This Does

- **Light Mode**: Shows cream/beige background (matches Blossom theme)
- **Dark Mode**: Shows dark gray background (matches dark themes)
- **App Icon**: Centered on screen
- **Smooth Transition**: Fades to your SwiftUI `LaunchLoadingView`

## Color Values Used

### Light Mode (RGB)
- Red: 0.953 (243)
- Green: 0.945 (241)  
- Blue: 0.953 (243)
- Result: Warm light gray/cream

### Dark Mode (RGB)
- Red: 0.102 (26)
- Green: 0.110 (28)
- Blue: 0.118 (30)
- Result: Dark charcoal gray

These match the default theme backgrounds for a seamless transition!

## Testing

After adding this:
1. Clean build folder (Shift+Cmd+K)
2. Delete app from simulator/device
3. Build and run
4. You should see: System Launch Screen → SwiftUI Launch Loading View → Main App

The transition should be smooth with no white flash!
