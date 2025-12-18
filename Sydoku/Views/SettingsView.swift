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
                Section(header: Text("Appearance")
                    .foregroundColor(theme.primaryAccent)
                    .fontWeight(.semibold)) {
                    Picker("Theme", selection: Binding(
                        get: { theme.type },
                        set: { newValue in
                            theme = Theme(type: newValue, colorScheme: theme.colorScheme)
                            game.settings.themeType = newValue
                            game.saveSettings()
                        }
                    )) {
                        ForEach(Theme.ThemeType.allCases, id: \.self) { themeType in
                            Text(themeType.displayName).tag(themeType)
                        }
                    }
                    .foregroundColor(theme.primaryText)
                    .tint(theme.primaryAccent)
                    .accentColor(theme.primaryAccent)
                    .listRowBackground(theme.cellBackgroundColor)
                    
                    Picker("Color Scheme", selection: Binding(
                        get: { game.settings.preferredColorScheme },
                        set: { newValue in
                            game.settings.preferredColorScheme = newValue
                            let colorScheme = newValue.toColorScheme(system: systemColorScheme)
                            theme = Theme(type: theme.type, colorScheme: colorScheme)
                            game.saveSettings()
                        }
                    )) {
                        ForEach(GameSettings.ColorSchemePreference.allCases, id: \.self) { preference in
                            Text(preference.displayName).tag(preference)
                        }
                    }
                    .foregroundColor(theme.primaryText)
                    .tint(theme.primaryAccent)
                    .accentColor(theme.primaryAccent)
                    .listRowBackground(theme.cellBackgroundColor)
                    
                    // Theme Preview
                    HStack(spacing: 12) {
                        ThemePreviewBox(color: theme.primaryAccent, label: "Primary", theme: theme)
                        ThemePreviewBox(color: theme.secondaryAccent, label: "Secondary", theme: theme)
                        ThemePreviewBox(color: theme.cellBackgroundColor, label: "Cells", theme: theme)
                    }
                    .padding(.vertical, 8)
                    .listRowBackground(theme.cellBackgroundColor)
                }
                
                // MARK: - Gameplay Settings
                Section(header: Text("Gameplay")
                    .foregroundColor(theme.primaryAccent)
                    .fontWeight(.semibold)) {
                    Toggle("Auto Error Checking", isOn: $game.settings.autoErrorChecking)
                        .onChange(of: game.settings.autoErrorChecking) {
                            game.saveSettings()
                        }
                        .foregroundColor(theme.primaryText)
                        .tint(theme.primaryAccent)
                        .toggleStyle(BorderedToggleStyle(accentColor: theme.primaryAccent))
                        .listRowBackground(theme.cellBackgroundColor)
                    
                    Picker("Mistake Limit", selection: $game.settings.mistakeLimit) {
                        Text("Unlimited").tag(0)
                        Text("3 Mistakes").tag(3)
                        Text("5 Mistakes").tag(5)
                        Text("10 Mistakes").tag(10)
                    }
                    .onChange(of: game.settings.mistakeLimit) {
                        game.saveSettings()
                    }
                    .foregroundColor(theme.primaryText)
                    .tint(theme.primaryAccent)
                    .accentColor(theme.primaryAccent)
                    .listRowBackground(theme.cellBackgroundColor)
                    
                    Toggle("Highlight Same Numbers", isOn: $game.settings.highlightSameNumbers)
                        .onChange(of: game.settings.highlightSameNumbers) {
                            game.saveSettings()
                        }
                        .foregroundColor(theme.primaryText)
                        .tint(theme.primaryAccent)
                        .toggleStyle(BorderedToggleStyle(accentColor: theme.primaryAccent))
                        .listRowBackground(theme.cellBackgroundColor)
                }
                
                // MARK: - Feedback Settings
                Section(header: Text("Feedback")
                    .foregroundColor(theme.primaryAccent)
                    .fontWeight(.semibold)) {
                    Toggle("Haptic Feedback", isOn: $game.settings.hapticFeedback)
                        .onChange(of: game.settings.hapticFeedback) {
                            game.saveSettings()
                        }
                        .foregroundColor(theme.primaryText)
                        .tint(theme.primaryAccent)
                        .toggleStyle(BorderedToggleStyle(accentColor: theme.primaryAccent))
                        .listRowBackground(theme.cellBackgroundColor)
                    
                    Toggle("Sound Effects", isOn: $game.settings.soundEffects)
                        .onChange(of: game.settings.soundEffects) {
                            game.saveSettings()
                        }
                        .foregroundColor(theme.primaryText)
                        .tint(theme.primaryAccent)
                        .toggleStyle(BorderedToggleStyle(accentColor: theme.primaryAccent))
                        .listRowBackground(theme.cellBackgroundColor)
                }
            }
            .scrollContentBackground(.hidden)
            .background(theme.backgroundColor)
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(theme.primaryAccent, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .foregroundColor(.white)
                }
            }
            .tint(theme.primaryAccent)
        }
        .id(theme.type) // Force rebuild when theme changes
        .tint(theme.primaryAccent)
    }
}

// MARK: - Preview

#Preview {
    SettingsView(game: SudokuGame(), theme: .constant(Theme(type: .ocean, colorScheme: .dark)))
}

/// A custom toggle style that adds a border when off.
struct BorderedToggleStyle: ToggleStyle {
    let accentColor: Color
    
    func makeBody(configuration: Configuration) -> some View {
        HStack {
            configuration.label
            Spacer()
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .stroke(accentColor, lineWidth: 2)
                    .frame(width: 62, height: 29)
                
                Toggle("", isOn: configuration.$isOn)
                    .labelsHidden()
            }
        }
    }
}

/// A preview box showing a theme color with label.
struct ThemePreviewBox: View {
    let color: Color
    let label: String
    let theme: Theme
    
    var body: some View {
        VStack(spacing: 4) {
            RoundedRectangle(cornerRadius: 8)
                .fill(color)
                .frame(height: 50)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(theme.primaryText.opacity(0.2), lineWidth: 1)
                )
            Text(label)
                .font(.caption)
                .foregroundColor(theme.secondaryText)
        }
    }
}

