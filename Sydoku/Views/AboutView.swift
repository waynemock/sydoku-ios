import SwiftUI

/// A view displaying information about the Sydoku app.
///
/// Shows app version, description, and credits.
struct AboutView: View {
    /// Environment value for dismissing the about sheet.
    @Environment(\.presentationMode) var presentationMode
    
    /// Environment theme.
    @Environment(\.theme) var theme
    

    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // App Icon and Name
                    VStack(spacing: 16) {
                        // App Icon or fallback to custom grid
                        if let appIcon = Bundle.main.icon {
                            Image(uiImage: appIcon)
                                .resizable()
                                .frame(width: 150, height: 150)
                                .cornerRadius(22.5)
                                .shadow(radius: 5)
                        } else {
                            MiniSudokuGrid()
                                .frame(width: 150, height: 150)
                        }
                        
                        Text("Sydoku")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(theme.primaryText)
                        
                        Text("Version \(Bundle.main.appVersion)")
                            .font(.subheadline)
                            .foregroundColor(theme.secondaryText)
                    }
                    .padding(.top, 40)
                    
                    Divider()
                        .padding(.horizontal)
                    
                    // Description
                    VStack(spacing: 12) {
                        Text("About Sydoku")
                            .font(.headline)
                            .foregroundColor(theme.primaryText)
                        
                        Text("A beautifully designed Sudoku puzzle game featuring elegant themes, smart hints, and daily challenges. Master your logic skills with puzzles across multiple difficulty levels.")
                            .font(.body)
                            .foregroundColor(theme.secondaryText)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 30)
                    }
                    
                    Divider()
                        .padding(.horizontal)
                    
                    // Features
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Features")
                            .font(.headline)
                            .foregroundColor(theme.primaryText)
                            .frame(maxWidth: .infinity, alignment: .center)
                        
                        FeatureRow(icon: "lightbulb.fill", text: "Progressive hint system", color: theme.warningColor)
                        FeatureRow(icon: "calendar", text: "Daily challenges with streaks", color: theme.primaryAccent)
                        FeatureRow(icon: "paintbrush.fill", text: "Customizable themes", color: theme.secondaryAccent)
                        FeatureRow(icon: "chart.bar.fill", text: "Comprehensive statistics", color: theme.successColor)
                        FeatureRow(icon: "pencil.circle", text: "Smart pencil notes", color: theme.primaryAccent)
                        FeatureRow(icon: "exclamationmark.triangle", text: "Auto error checking", color: theme.errorColor)
                        FeatureRow(icon: "arrow.uturn.backward", text: "Unlimited undo/redo", color: theme.secondaryAccent)
                        FeatureRow(icon: "hand.tap.fill", text: "Haptic feedback", color: theme.warningColor)
                    }
                    .padding(.horizontal, 30)
                    
                    Divider()
                        .padding(.horizontal)
                    
                    // Copyright
                    VStack(spacing: 8) {
                        Text("© 2025 Syzygy Softwerks LLC")
                            .font(.caption)
                            .foregroundColor(theme.secondaryText)
                        
                        Text("Made by humans and AI for puzzle lovers in Arvada, Colorado, USA, Earth.")
                            .font(.caption)
                            .foregroundColor(theme.secondaryText)
                            .multilineTextAlignment(.center)
                            .padding(.vertical, 8)
                    }
                    .padding(.bottom, 40)
                }
            }
            .background(theme.backgroundColor)
            .navigationTitle("About")
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
        }
    }
}

// MARK: - Preview

#Preview {
    AboutView()
        .environment(\.theme, Theme(type: .sunset, colorScheme: .dark))
}


