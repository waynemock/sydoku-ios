import SwiftUI

/// A menu button isolated to prevent flashing when timer updates.
struct MenuButtonView: View {
    @ObservedObject var game: SudokuGame
    let theme: Theme
    @Binding var showingStats: Bool
    @Binding var showingSettings: Bool
    @Binding var showingAbout: Bool
    @Binding var showingErrorCheckingToast: Bool
    
    var body: some View {
        Menu {
            Button(action: { game.giveHint() }) {
                Label("Show Hint", systemImage: "lightbulb")
            }
            .disabled(game.isGenerating || game.isComplete || game.isPaused || game.isGameOver)
            
            Button(action: { game.autoFillNotes() }) {
                Label("Auto Notes", systemImage: "wand.and.stars")
            }
            .disabled(game.isGenerating || game.isPaused || game.isGameOver)
            
            Button(action: { game.clearAllNotes() }) {
                Label("Clear Notes", systemImage: "trash")
            }
            .disabled(game.isGenerating || game.isPaused || game.isGameOver)

            Divider()
            
            Button(action: {
                game.settings.autoErrorChecking.toggle()
                game.saveSettings()
                
                // Show toast feedback
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    showingErrorCheckingToast = true
                }
            }) {
                Label("Auto Error Checking", systemImage: game.settings.autoErrorChecking ? "checkmark.circle.fill" : "circle")
            }
            
            Divider()
            
            Button(action: { showingStats = true }) {
                Label("Statistics", systemImage: "chart.bar.fill")
            }
            
            Button(action: { showingSettings = true }) {
                Label("Settings", systemImage: "gearshape.fill")
            }
            
            Divider()
            
            Button(action: { showingAbout = true }) {
                Label("About Sydoku", systemImage: "info.circle")
            }
            
        } label: {
            Image(systemName: "ellipsis.circle")
                .font(.system(size: 40))
                .foregroundColor(theme.primaryAccent)
                .frame(width: 44, height: 44)
        }
        .menuStyle(.button)
        .fixedSize()
        .transaction { transaction in
            transaction.animation = nil
        }
    }
}
