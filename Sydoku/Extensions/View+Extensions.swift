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
            .overlay(alignment: .top) {
                Rectangle()
                    .stroke(color, lineWidth: width.top)
                    .frame(height: width.top)
                    .offset(y: -width.top/2)
            }
            .overlay(alignment: .bottom) {
                Rectangle()
                    .stroke(color, lineWidth: width.bottom)
                    .frame(height: width.bottom)
                    .offset(y: width.bottom/2)
            }
            .overlay(alignment: .leading) {
                Rectangle()
                    .stroke(color, lineWidth: width.leading)
                    .frame(width: width.leading)
                    .offset(x: -width.leading/2)
            }
            .overlay(alignment: .trailing) {
                    Rectangle()
                        .stroke(color, lineWidth: width.trailing)
                        .frame(width: width.trailing)
                        .offset(x: width.trailing/2)
            }

    }

    /// Conditionally applies a modifier to a view.
    /// - Parameters:
    ///   - condition: The condition to evaluate.
    ///   - transform: The transform to apply if the condition is true.
    /// - Returns: The modified view if condition is true, otherwise the original view.
    @ViewBuilder
    func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}
