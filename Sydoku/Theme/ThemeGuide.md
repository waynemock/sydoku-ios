# Theme System Quick Reference

## Using Themes in Your Views

### Basic Usage

```swift
struct MyView: View {
    @Environment(\.theme) var theme
    
    var body: some View {
        Text("Hello")
            .foregroundColor(theme.primaryText)
            .background(theme.backgroundColor)
    }
}
```

### Available Theme Colors

| Property | Usage |
|----------|-------|
| `primaryAccent` | Main interactive elements (buttons, links) |
| `secondaryAccent` | Complementary highlights |
| `backgroundColor` | Main app background |
| `cellBackgroundColor` | Grid cell backgrounds |
| `primaryText` | Main readable text |
| `secondaryText` | Subtle, less important text |
| `initialCellText` | Given numbers in puzzle |
| `userCellText` | User-entered numbers |
| `errorColor` | Error states, conflicts |
| `successColor` | Success states, completion |
| `warningColor` | Warnings, hints |
| `selectedCellColor` | Selected cell background |
| `highlightedCellColor` | Highlighted cell background |
| `hintCellColor` | Hint cell background |

### Creating Themed Buttons

```swift
Button("Tap Me") {
    // action
}
.padding()
.background(
    RoundedRectangle(cornerRadius: 12)
        .fill(theme.primaryAccent)
)
.foregroundColor(.white)
```

### Using Gradients

```swift
Text("Gradient Text")
    .foregroundStyle(
        .linearGradient(
            colors: [theme.primaryAccent, theme.secondaryAccent],
            startPoint: .leading,
            endPoint: .trailing
        )
    )
```

### Material Effects

```swift
VStack {
    // content
}
.background(.ultraThinMaterial) // Glass effect
```

## Theme Types

1. **Ocean** - Blues and teals
2. **Sunset** - Oranges and pinks  
3. **Forest** - Greens and earth tones
4. **Midnight** - Purples and deep blues
5. **Classic** - Traditional blue/cyan

## Adding a New Theme

1. Add case to `Theme.ThemeType`:
```swift
enum ThemeType: String, Codable, CaseIterable {
    case myNewTheme = "My Theme"
}
```

2. Add color cases in Theme properties:
```swift
var primaryAccent: Color {
    switch type {
    case .myNewTheme:
        return Color(red: 0.5, green: 0.2, blue: 0.8)
    // ... other cases
    }
}
```

3. Theme automatically appears in Settings!

## Best Practices

✅ **Do:**
- Use theme colors for all UI elements
- Test themes in both light and dark modes
- Maintain contrast ratios for accessibility
- Use semantic color names (primaryAccent, not blueColor)

❌ **Don't:**
- Hardcode color values
- Use system colors (Color.blue) for themed elements
- Create colors that don't adapt to color scheme
- Ignore accessibility guidelines

## Animation with Themes

```swift
Button("Animated") {
    withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
        // animated change
    }
}
.buttonStyle(ScaleButtonStyle())
```

## Testing Themes

Test each theme with:
- Light mode
- Dark mode  
- Different screen sizes
- Accessibility settings (contrast, text size)
- Color blindness simulators

---

Happy theming! 🎨
