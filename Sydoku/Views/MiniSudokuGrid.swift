import SwiftUI

/// A miniature 3x3 Sudoku grid icon with numbers for the About screen.
struct MiniSudokuGrid: View {
    /// Environment theme.
    @Environment(\.theme) var theme
    
    var body: some View {
        GeometryReader { geometry in
            let cellSize = min(geometry.size.width, geometry.size.height) / 3
            
            ZStack {
                // Background
                RoundedRectangle(cornerRadius: 12)
                    .fill(theme.cellBackgroundColor)
                
                // Grid lines and numbers
                VStack(spacing: 0) {
                    // Row 0
                    HStack(spacing: 0) {
                        gridCell(number: 5, cellSize: cellSize, corners: [.topLeft])
                        gridCell(number: 3, cellSize: cellSize, corners: [])
                        gridCell(number: nil, cellSize: cellSize, corners: [.topRight])
                    }
                    // Row 1
                    HStack(spacing: 0) {
                        gridCell(number: 6, cellSize: cellSize, corners: [])
                        gridCell(number: nil, cellSize: cellSize, corners: [])
                        gridCell(number: 9, cellSize: cellSize, corners: [])
                    }
                    // Row 2
                    HStack(spacing: 0) {
                        gridCell(number: nil, cellSize: cellSize, corners: [.bottomLeft])
                        gridCell(number: 1, cellSize: cellSize, corners: [])
                        gridCell(number: 8, cellSize: cellSize, corners: [.bottomRight])
                    }
                }
                
                // Outer border
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        .linearGradient(
                            colors: [theme.primaryAccent, theme.secondaryAccent],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 3
                    )
            }
        }
    }
    
    @ViewBuilder
    private func gridCell(number: Int?, cellSize: CGFloat, corners: UIRectCorner) -> some View {
        ZStack {
            // Cell background with conditional rounded corners
            if corners.isEmpty {
                Rectangle()
                    .fill(theme.cellBackgroundColor)
            } else {
                UnevenRoundedRectangle(
                    topLeadingRadius: corners.contains(.topLeft) ? 12 : 0,
                    bottomLeadingRadius: corners.contains(.bottomLeft) ? 12 : 0,
                    bottomTrailingRadius: corners.contains(.bottomRight) ? 12 : 0,
                    topTrailingRadius: corners.contains(.topRight) ? 12 : 0
                )
                .fill(theme.cellBackgroundColor)
            }
            
            // Number
            if let number = number {
                Text("\(number)")
                    .font(.system(size: cellSize * 0.55, weight: .bold))
                    .foregroundStyle(
                        .linearGradient(
                            colors: [theme.primaryAccent, theme.secondaryAccent],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            
            // Cell border with conditional rounded corners
            if corners.isEmpty {
                Rectangle()
                    .stroke(theme.secondaryText.opacity(0.3), lineWidth: 1)
            } else {
                UnevenRoundedRectangle(
                    topLeadingRadius: corners.contains(.topLeft) ? 12 : 0,
                    bottomLeadingRadius: corners.contains(.bottomLeft) ? 12 : 0,
                    bottomTrailingRadius: corners.contains(.bottomRight) ? 12 : 0,
                    topTrailingRadius: corners.contains(.topRight) ? 12 : 0
                )
                .stroke(theme.secondaryText.opacity(0.3), lineWidth: 1)
            }
        }
        .frame(width: cellSize, height: cellSize)
    }
}
