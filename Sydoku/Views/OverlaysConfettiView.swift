import SwiftUI

/// A celebratory confetti animation displayed when completing a puzzle.
///
/// `ConfettiView` creates an animated burst of colorful circular confetti pieces
/// that fall and fade out, providing visual feedback for successful game completion.
struct ConfettiView: View {
    /// Controls the animation state of the confetti pieces.
    @State private var animate = false
    
    /// The colors used for confetti pieces, randomly selected for each piece.
    let colors: [Color] = [.red, .blue, .green, .yellow, .orange, .purple, .pink]
    
    var body: some View {
        ZStack {
            ForEach(0..<50, id: \.self) { index in
                ConfettiPiece(color: colors.randomElement() ?? .blue)
                    .offset(
                        x: animate ? CGFloat.random(in: -200...200) : 0,
                        y: animate ? CGFloat.random(in: -300...800) : -50
                    )
                    .opacity(animate ? 0 : 1)
                    .rotationEffect(.degrees(animate ? 720 : 0))
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 2.0)) {
                animate = true
            }
        }
    }
}

/// A single piece of confetti represented as a colored circle.
struct ConfettiPiece: View {
    /// The color of this confetti piece.
    let color: Color
    
    var body: some View {
        Circle()
            .fill(color)
            .frame(width: 10, height: 10)
    }
}
