import SwiftUI

/// Extension providing custom border styling capabilities for SwiftUI views.
extension View {
    /// Applies borders with individually specified widths for each edge.
    ///
    /// This method allows creating asymmetric borders, which is particularly useful
    /// for Sudoku grids where different cells need thicker borders to delineate
    /// 3x3 boxes while maintaining thinner borders between individual cells.
    ///
    /// - Parameters:
    ///   - width: A `BorderWidths` structure specifying the width for each edge.
    ///   - color: The color to apply to all borders.
    /// - Returns: A view with custom borders applied.
    func border(width: BorderWidths, color: Color) -> some View {
        self
            .overlay(
                Rectangle()
                    .stroke(color, lineWidth: width.top)
                    .frame(height: width.top)
                    .offset(y: -width.top/2),
                alignment: .top
            )
            .overlay(
                Rectangle()
                    .stroke(color, lineWidth: width.bottom)
                    .frame(height: width.bottom)
                    .offset(y: width.bottom/2),
                alignment: .bottom
            )
            .overlay(
                Rectangle()
                    .stroke(color, lineWidth: width.leading)
                    .frame(width: width.leading)
                    .offset(x: -width.leading/2),
                alignment: .leading
            )
            .overlay(
                Rectangle()
                    .stroke(color, lineWidth: width.trailing)
                    .frame(width: width.trailing)
                    .offset(x: width.trailing/2),
                alignment: .trailing
            )
    }
}
