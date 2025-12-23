import SwiftUI

/// A toast notification that appears when auto error checking is toggled.
///
/// Displays the current state of auto error checking (on/off) with an appropriate
/// icon and message. Uses the app's theme for styling.
struct AutoErrorCheckingToast: View {
    /// Whether auto error checking is enabled.
    let isEnabled: Bool
    
    /// The theme for styling.
    let theme: Theme
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: isEnabled ? "checkmark.circle.fill" : "circle")
                .font(.title3)
            Text(isEnabled ? "Auto Error Checking On" : "Auto Error Checking Off")
                .font(.subheadline.weight(.semibold))
        }
        .foregroundColor(.white)
        .padding(.horizontal, 16)
        .frame(height: 44)
        .background(
            Capsule()
                .fill(theme.primaryAccent)
        )
        .shadow(radius: 8)
    }
}
