import SwiftUI

struct SettingsView: View {
    @ObservedObject var game: SudokuGame
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            Form {
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
        .frame(minWidth: 500, minHeight: 400)
        #endif
    }
}
