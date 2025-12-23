//
//  Font+App.swift
//  Sydoku
//
//  Created by Wayne Mock on 12/20/25.
//

import SwiftUI

extension Font {
    /// The app's primary font family.
    ///
    /// This provides a centralized location for the app's font choice.
    /// Change this value to update the font throughout the entire app.
    private static let appFontName = "Optima-Regular"
    
    /// Returns a custom font sized for the app with Dynamic Type support.
    ///
    /// - Parameters:
    ///   - size: The base point size for the font.
    ///   - relativeTo: The text style to scale relative to for Dynamic Type (default: .body).
    /// - Returns: A custom font that scales with accessibility settings.
    static func app(size: CGFloat, relativeTo textStyle: TextStyle = .body) -> Font {
        return .custom(appFontName, size: size, relativeTo: textStyle)
    }
    
    // MARK: - Standard Text Styles
    
    /// Returns the app font at standard body text size.
    static var appBody: Font {
        return .app(size: 17, relativeTo: .body)
    }
    
    /// Returns the app font at headline size.
    static var appHeadline: Font {
        return .app(size: 17, relativeTo: .headline)
    }
    
    /// Returns the app font at title size.
    static var appTitle: Font {
        return .app(size: 28, relativeTo: .title)
    }
    
    /// Returns the app font at title2 size.
    static var appTitle2: Font {
        return .app(size: 22, relativeTo: .title2)
    }
    
    /// Returns the app font at title3 size.
    static var appTitle3: Font {
        return .app(size: 20, relativeTo: .title3)
    }
    
    /// Returns the app font at large title size.
    static var appLargeTitle: Font {
        return .app(size: 34, relativeTo: .largeTitle)
    }
    
    /// Returns the app font at caption size.
    static var appCaption: Font {
        return .app(size: 12, relativeTo: .caption)
    }
    
    /// Returns the app font at caption2 size.
    static var appCaption2: Font {
        return .app(size: 11, relativeTo: .caption2)
    }
    
    /// Returns the app font at subheadline size.
    static var appSubheadline: Font {
        return .app(size: 15, relativeTo: .subheadline)
    }
    
    /// Returns the app font at footnote size.
    static var appFootnote: Font {
        return .app(size: 13, relativeTo: .footnote)
    }
    
    /// Returns the app font at callout size.
    static var appCallout: Font {
        return .app(size: 16, relativeTo: .callout)
    }
    
    // MARK: - Special Variants
    
    /// Returns a monospaced variant of the app font at body size.
    ///
    /// Useful for timers and numeric displays where consistent character width is important.
    /// Falls back to system monospaced font to ensure proper digit alignment.
    static var appMonospaced: Font {
        return .system(.body, design: .monospaced)
    }
    
    /// Returns a small app font for constrained spaces like notes grids.
    ///
    /// Uses a custom size with caption scaling to ensure it doesn't get too large
    /// in accessibility mode, since space is very limited in Sudoku cell notes.
    ///
    /// - Parameter size: The base point size (should be small, e.g., 8-12pt).
    /// - Returns: A custom font that scales conservatively with accessibility settings.
    static func appTiny(size: CGFloat) -> Font {
        // Use caption2 for scaling to keep it small even with larger text settings
        return .custom("Optima-Regular", size: size, relativeTo: .caption2)
    }
    
    /// Returns a constrained app font for game elements that must fit in fixed spaces.
    ///
    /// Sudoku cells have fixed sizes, so we scale conservatively using caption2
    /// to prevent clipping while still respecting accessibility preferences.
    ///
    /// - Parameter size: The base point size calculated from cell dimensions.
    /// - Returns: A custom font that scales minimally with accessibility settings.
    static func appConstrained(size: CGFloat) -> Font {
        // Use caption2 for minimal scaling in constrained game board spaces
        return .custom("Optima-Regular", size: size, relativeTo: .caption2)
    }
}
