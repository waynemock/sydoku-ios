import SwiftUI

extension View {
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
