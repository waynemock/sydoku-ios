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
                        if let appIcon = Bundle.main.icon {
                            Image(uiImage: appIcon)
                                .resizable()
                                .frame(width: 150, height: 150)
                                .cornerRadius(22.5)
                                .shadow(radius: 5)
                        }
                        
                        Text("Sydoku")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(theme.primaryText)
                        
                        Text("Version \(Bundle.main.appVersion)")
                            .font(.subheadline)
                            .foregroundColor(theme.secondaryText)
                    }
                    .padding(.top, 30)

                    // Description
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Sydoku is a clean, thoughtfully designed Sudoku app.")
                            .font(.body)
                            .foregroundColor(theme.secondaryText)
                        VStack(alignment: .leading, spacing: 8) {
                            HStack(alignment: .top, spacing: 8) {
                                Text("•")
                                    .font(.body)
                                    .foregroundColor(theme.secondaryText)
                                Text("No ads. No tracking. No distractions.")
                                    .font(.body)
                                    .foregroundColor(theme.secondaryText)
                            }
                            HStack(alignment: .top, spacing: 8) {
                                Text("•")
                                    .font(.body)
                                    .foregroundColor(theme.secondaryText)
                                Text("Just puzzles, done right.")
                                    .font(.body)
                                    .foregroundColor(theme.secondaryText)
                            }
                        }
                        Text("Designed to stay out of your way so you can focus on solving, whether you’re playing a quick game or settling in for a longer session.")
                            .font(.body)
                            .foregroundColor(theme.secondaryText)
                    }
                    .padding(.horizontal, 20)

                    // Features
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Features")
                            .font(.headline)
                            .foregroundColor(theme.primaryText)
                            .frame(maxWidth: .infinity, alignment: .center)
                        
                        FeatureRow(icon: "icloud.fill", text: "Seamless iCloud sync across your devices", color: theme.primaryAccent)
                        FeatureRow(icon: "paintpalette.fill", text: "Multiple themes, including Blossom, Midnight, and Classic Paper", color: theme.primaryAccent)
                        FeatureRow(icon: "pencil.and.outline", text: "Notes, highlights, and error checking that respect your focus", color: theme.primaryAccent)
                        FeatureRow(icon: "fossil.shell.fill", text: "Complete game history and statistics", color: theme.primaryAccent)
                        FeatureRow(icon: "ipad.landscape.and.iphone", text: "Scales beautifully on iPhone and iPad", color: theme.primaryAccent)
                        FeatureRow(icon: "textformat.size", text: "Respects Dynamic Type and accessibility settings", color: theme.primaryAccent)

                    }
                    .padding(.horizontal, 30)
                                        
                    // Copyright
                    VStack(spacing: 8) {
                        Text("© 2026 Syzygy Softwerks LLC")
                            .font(.caption)
                            .foregroundColor(theme.secondaryText)
                        
                        Text("Built by someone who just wanted a better Sudoku app.")
                            .font(.caption)
                            .foregroundColor(theme.secondaryText)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 30)


                        Text("Arvada, Colorado, USA, Earth.")
                            .font(.caption)
                            .foregroundColor(theme.secondaryText)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 30)
                    }
                    .padding(.bottom, 10)
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


