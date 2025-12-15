import SwiftUI

/// A row displaying a feature with an icon and description.
struct FeatureRow: View {
    let icon: String
    let text: String
    let color: Color
    
    /// Environment theme.
    @Environment(\.theme) var theme
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
                .frame(width: 32)
            
            Text(text)
                .font(.body)
                .foregroundColor(theme.primaryText)
            
            Spacer()
        }
    }
}
