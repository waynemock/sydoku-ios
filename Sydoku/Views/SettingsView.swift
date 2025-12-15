import SwiftUI

/// A view for configuring game settings and preferences.
///
/// Provides options for gameplay features (error checking, mistake limits, highlighting),
/// feedback settings (haptics, sound), theme customization, and app information.
struct SettingsView: View {
    /// The Sudoku game instance that manages settings.
    @ObservedObject var game: SudokuGame
    
    /// Binding to the app theme.
    @Binding var theme: Theme
    
    /// Environment value for dismissing the settings sheet.
    @Environment(\.presentationMode) var presentationMode
    
    /// Environment color scheme.
    @Environment(\.colorScheme) var systemColorScheme
    
    var body: some View {
        NavigationView {
            Form {
                // MARK: - Appearance Settings
                Section(header: Text("Appearance")) {
                    Picker("Theme", selection: Binding(
                        get: { theme.type },
                        set: { newValue in
                            theme = Theme(type: newValue, colorScheme: theme.colorScheme)
                            game.settings.themeType = newValue.rawValue
                            game.saveSettings()
                        }
                    )) {
                        ForEach(Theme.ThemeType.allCases, id: \.self) { themeType in
                            Text(themeType.displayName).tag(themeType)
                        }
                    }
                    
                    Picker("Color Scheme", selection: Binding(
                        get: { game.settings.preferredColorScheme },
                        set: { newValue in
                            game.settings.preferredColorScheme = newValue
                            let colorScheme: ColorScheme
                            switch newValue {
                            case "light":
                                colorScheme = .light
                            case "dark":
                                colorScheme = .dark
                            default:
                                colorScheme = systemColorScheme
                            }
                            theme = Theme(type: theme.type, colorScheme: colorScheme)
                            game.saveSettings()
                        }
                    )) {
                        Text("System").tag("system")
                        Text("Light").tag("light")
                        Text("Dark").tag("dark")
                    }
                    
                    // Theme Preview
                    HStack(spacing: 12) {
                        ThemePreviewBox(color: theme.primaryAccent, label: "Primary")
                        ThemePreviewBox(color: theme.secondaryAccent, label: "Secondary")
                        ThemePreviewBox(color: theme.cellBackgroundColor, label: "Cells")
                    }
                    .padding(.vertical, 8)
                }
                
                // MARK: - Gameplay Settings
                Section(header: Text("Gameplay")) {
                    Toggle("Auto Error Checking", isOn: $game.settings.autoErrorChecking)
                        .onChange(of: game.settings.autoErrorChecking) {
                            game.saveSettings()
                        }
                    
                    Picker("Mistake Limit", selection: $game.settings.mistakeLimit) {
                        Text("Unlimited").tag(0)
                        Text("3 Mistakes").tag(3)
                        Text("5 Mistakes").tag(5)
                        Text("10 Mistakes").tag(10)
                    }
                    .onChange(of: game.settings.mistakeLimit) {
                        game.saveSettings()
                    }
                    
                    Toggle("Highlight Same Numbers", isOn: $game.settings.highlightSameNumbers)
                        .onChange(of: game.settings.highlightSameNumbers) {
                            game.saveSettings()
                        }
                }
                
                // MARK: - Feedback Settings
                Section(header: Text("Feedback")) {
                    Toggle("Haptic Feedback", isOn: $game.settings.hapticFeedback)
                        .onChange(of: game.settings.hapticFeedback) {
                            game.saveSettings()
                        }
                    
                    Toggle("Sound Effects", isOn: $game.settings.soundEffects)
                        .onChange(of: game.settings.soundEffects) {
                            game.saveSettings()
                        }
                }
                
                // MARK: - About Section
                Section(header: Text("About")) {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Settings")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
        #if os(macOS)
        .frame(minWidth: 500, minHeight: 500)
        #endif
    }
}
/// A preview box showing a theme color with label.
struct ThemePreviewBox: View {
    let color: Color
    let label: String
    
    var body: some View {
        VStack(spacing: 4) {
            RoundedRectangle(cornerRadius: 8)
                .fill(color)
                .frame(height: 50)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.primary.opacity(0.2), lineWidth: 1)
                )
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

