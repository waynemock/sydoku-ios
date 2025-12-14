import SwiftUI

/// A structure that defines the width of borders on each edge of a view.
///
/// Use `BorderWidths` to specify different border widths for each side of a view,
/// allowing for asymmetric border styling in Sudoku grid cells or other UI elements.
struct BorderWidths {
    /// The width of the leading edge border (left in LTR, right in RTL layouts).
    let leading: CGFloat
    
    /// The width of the top edge border.
    let top: CGFloat
    
    /// The width of the trailing edge border (right in LTR, left in RTL layouts).
    let trailing: CGFloat
    
    /// The width of the bottom edge border.
    let bottom: CGFloat
}
