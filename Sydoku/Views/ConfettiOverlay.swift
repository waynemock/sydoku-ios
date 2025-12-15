import SwiftUI

/// A celebratory confetti animation displayed when completing a puzzle.
///
/// `ConfettiView` creates an animated burst of colorful confetti pieces with
/// various shapes that fall and fade out, providing visual feedback for successful
/// game completion.
struct ConfettiView: View {
    /// Controls the animation state of the confetti pieces.
    @State private var animate = false
    
    /// The colors used for confetti pieces, randomly selected for each piece.
    let colors: [Color] = [.red, .blue, .green, .yellow, .orange, .purple, .pink, .cyan, .mint, .indigo]
    
    var body: some View {
        ZStack {
            ForEach(0..<60, id: \.self) { index in
                ConfettiPiece(
                    color: colors.randomElement() ?? .blue,
                    shape: ConfettiShape.allCases.randomElement() ?? .circle
                )
                .offset(
                    x: animate ? CGFloat.random(in: -300...300) : CGFloat.random(in: -50...50),
                    y: animate ? CGFloat.random(in: -200...1000) : -100
                )
                .opacity(animate ? 0 : 1)
                .rotationEffect(.degrees(animate ? Double.random(in: 360...1080) : 0))
                .scaleEffect(animate ? CGFloat.random(in: 0.3...0.8) : 1.0)
                .animation(
                    .easeOut(duration: Double.random(in: 1.5...3.0))
                    .delay(Double.random(in: 0...0.3)),
                    value: animate
                )
            }
        }
        .onAppear {
            animate = true
        }
    }
}

/// The shape of a confetti piece.
enum ConfettiShape: CaseIterable {
    case circle
    case square
    case triangle
    case star
}

/// A single piece of confetti with customizable shape and color.
struct ConfettiPiece: View {
    /// The color of this confetti piece.
    let color: Color
    
    /// The shape of this confetti piece.
    let shape: ConfettiShape
    
    /// Random size for variation.
    private let size: CGFloat = CGFloat.random(in: 8...16)
    
    var body: some View {
        Group {
            switch shape {
            case .circle:
                Circle()
                    .fill(color)
                    .frame(width: size, height: size)
            case .square:
                RoundedRectangle(cornerRadius: 2)
                    .fill(color)
                    .frame(width: size, height: size)
            case .triangle:
                Triangle()
                    .fill(color)
                    .frame(width: size, height: size)
            case .star:
                Star()
                    .fill(color)
                    .frame(width: size, height: size)
            }
        }
        .shadow(color: color.opacity(0.5), radius: 2)
    }
}
/// A triangle shape for confetti.
struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

/// A star shape for confetti.
struct Star: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2
        let pointCount = 5
        let angle = .pi / Double(pointCount)
        
        for i in 0..<(pointCount * 2) {
            let r = i % 2 == 0 ? radius : radius * 0.4
            let currentAngle = angle * Double(i) - .pi / 2
            let point = CGPoint(
                x: center.x + r * CGFloat(cos(currentAngle)),
                y: center.y + r * CGFloat(sin(currentAngle))
            )
            if i == 0 {
                path.move(to: point)
            } else {
                path.addLine(to: point)
            }
        }
        path.closeSubpath()
        return path
    }
}

