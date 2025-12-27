import SwiftUI

// MARK: - Color Luminance Extension

extension Color {
    /// Determines if the color is light or dark based on its luminance.
    var isLight: Bool {
        // Try to extract RGB components from the color
        guard let components = cgColor?.components else {
            // If we can't determine, assume it's light
            return true
        }
        
        // Handle different color spaces
        let red: CGFloat
        let green: CGFloat
        let blue: CGFloat
        
        if components.count >= 3 {
            // RGB or RGBA color space
            red = components[0]
            green = components[1]
            blue = components[2]
        } else if components.count >= 1 {
            // Grayscale color space
            red = components[0]
            green = components[0]
            blue = components[0]
        } else {
            // Unknown format, assume light
            return true
        }
        
        // Calculate relative luminance using the sRGB formula
        // https://www.w3.org/TR/WCAG20/#relativeluminancedef
        let luminance = 0.2126 * red + 0.7152 * green + 0.0722 * blue
        
        // Threshold: > 0.5 is considered light, <= 0.5 is dark
        return luminance > 0.5
    }
    
    /// Returns the CGColor representation of this Color (if available).
    private var cgColor: CGColor? {
        #if os(iOS) || os(watchOS) || os(tvOS)
        return UIColor(self).cgColor
        #elseif os(macOS)
        return NSColor(self).cgColor
        #else
        return nil
        #endif
    }
}
