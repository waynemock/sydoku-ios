import SwiftUI

/// A view displaying information about the Sydoku app.
///
/// Shows app version, description, and credits.
struct AboutView: View {
    /// Environment value for dismissing the about sheet.
    @Environment(\.presentationMode) var presentationMode
    
    /// Environment theme.
    @Environment(\.theme) var theme
    
    /// The app version from the bundle.
    private var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String
        
        if let build = build, build != version {
            return "\(version) (\(build))"
        }
        return version
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 30) {
                    // App Icon and Name
                    VStack(spacing: 16) {
                        // Custom 3x3 Sudoku grid with numbers
                        MiniSudokuGrid()
                            .frame(width: 100, height: 100)
                        
                        Text("Sydoku")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(theme.primaryText)
                        
                        Text("Version \(appVersion)")
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
                        
                        Text("A modern Sudoku puzzle game with beautiful themes, progressive hints, and daily challenges. Sharpen your logic skills with puzzles ranging from easy to hard difficulty.")
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
                        FeatureRow(icon: "calendar", text: "Daily challenges", color: theme.primaryAccent)
                        FeatureRow(icon: "paintbrush.fill", text: "Beautiful themes", color: theme.secondaryAccent)
                        FeatureRow(icon: "chart.bar.fill", text: "Statistics tracking", color: theme.successColor)
                        FeatureRow(icon: "pencil.circle", text: "Pencil notes", color: theme.primaryAccent)
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
        #if os(macOS)
        .frame(minWidth: 800, minHeight: 1000)
        #endif
    }
}

// MARK: - Preview

#Preview {
    AboutView()
        .environment(\.theme, Theme(type: .sunset, colorScheme: .dark))
}

