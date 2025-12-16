import SwiftUI

/// A realistic confetti animation view inspired by iOS Messages.
///
/// Creates falling confetti pieces with various shapes, colors, rotation,
/// and physics-based animation for a celebratory effect.
struct ConfettiView: View {
    @State private var confettiPieces: [ConfettiPieceModel] = []
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(confettiPieces) { piece in
                    ConfettiPieceView(piece: piece)
                }
            }
            .onAppear {
                generateConfetti(in: geometry.size)
            }
        }
        .ignoresSafeArea()
    }
    
    /// Generates confetti pieces across the screen.
    private func generateConfetti(in size: CGSize) {
        let pieceCount = 150
        
        for i in 0..<pieceCount {
            let piece = ConfettiPieceModel(
                id: i,
                x: CGFloat.random(in: 0...size.width),
                y: -50,
                shape: ConfettiShape.allCases.randomElement()!,
                color: ConfettiColor.allCases.randomElement()!.color,
                size: CGFloat.random(in: 8...16),
                rotationSpeed: Double.random(in: -4...4),
                fallSpeed: Double.random(in: 2...5),
                swing: Double.random(in: -30...30),
                screenHeight: size.height
            )
            confettiPieces.append(piece)
        }
    }
}

/// A single confetti piece with animation state.
struct ConfettiPieceModel: Identifiable {
    let id: Int
    let x: CGFloat
    let y: CGFloat
    let shape: ConfettiShape
    let color: Color
    let size: CGFloat
    let rotationSpeed: Double
    let fallSpeed: Double
    let swing: Double
    let screenHeight: CGFloat
}

/// Individual confetti piece view with animation.
struct ConfettiPieceView: View {
    let piece: ConfettiPieceModel
    
    @State private var offsetY: CGFloat = 0
    @State private var offsetX: CGFloat = 0
    @State private var rotation: Double = 0
    @State private var opacity: Double = 1
    
    var body: some View {
        let (width, height) = piece.shape == .rectangle ? (piece.size * 0.4, piece.size) : (piece.size, piece.size)
        
        piece.shape.shape
            .fill(piece.color)
            .frame(width: width, height: height)
            .rotationEffect(Angle.degrees(rotation))
            .offset(x: piece.x + offsetX, y: piece.y + offsetY)
            .opacity(opacity)
            .onAppear {
                animate()
            }
    }
    
    /// Animates the confetti piece falling with rotation and swing.
    private func animate() {
        // Rotation animation
        withAnimation(
            .linear(duration: 1 / abs(piece.rotationSpeed))
            .repeatForever(autoreverses: false)
        ) {
            rotation = piece.rotationSpeed > 0 ? 360 : -360
        }
        
        // Falling animation with swing
        let duration = Double(piece.screenHeight + 100) / (piece.fallSpeed * 100)
        
        withAnimation(
            .linear(duration: duration)
        ) {
            offsetY = piece.screenHeight + 100
        }
        
        // Swing animation (side-to-side motion)
        withAnimation(
            .easeInOut(duration: duration / 4)
            .repeatForever(autoreverses: true)
        ) {
            offsetX = piece.swing
        }
        
        // Fade out near the bottom
        DispatchQueue.main.asyncAfter(deadline: .now() + duration * 0.8) {
            withAnimation(.easeOut(duration: duration * 0.2)) {
                opacity = 0
            }
        }
    }
}

/// Confetti piece shapes.
enum ConfettiShape: CaseIterable {
    case circle
    case square
    case triangle
    case diamond
    case rectangle
    case star
    
    var shape: AnyShape {
        switch self {
        case .circle:
            AnyShape(Circle())
        case .square:
            AnyShape(Rectangle())
        case .triangle:
            AnyShape(TriangleShape())
        case .diamond:
            AnyShape(DiamondShape())
        case .rectangle:
            AnyShape(RoundedRectangle(cornerRadius: 2))
        case .star:
            AnyShape(StarShape())
        }
    }
}

/// Confetti colors matching iOS vibrant palette.
enum ConfettiColor: CaseIterable {
    case red, orange, yellow, green, blue, purple, pink, teal
    
    var color: Color {
        switch self {
        case .red: return Color(red: 1.0, green: 0.3, blue: 0.3)
        case .orange: return Color(red: 1.0, green: 0.6, blue: 0.2)
        case .yellow: return Color(red: 1.0, green: 0.9, blue: 0.2)
        case .green: return Color(red: 0.3, green: 0.9, blue: 0.4)
        case .blue: return Color(red: 0.2, green: 0.6, blue: 1.0)
        case .purple: return Color(red: 0.7, green: 0.3, blue: 1.0)
        case .pink: return Color(red: 1.0, green: 0.4, blue: 0.7)
        case .teal: return Color(red: 0.2, green: 0.9, blue: 0.9)
        }
    }
}

/// Triangle shape for confetti.
struct TriangleShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

/// Diamond shape for confetti.
struct DiamondShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.midY))
        path.closeSubpath()
        return path
    }
}

/// Star shape for confetti.
struct StarShape: Shape {
    func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let outerRadius = min(rect.width, rect.height) / 2
        let innerRadius = outerRadius * 0.4
        let angleIncrement = Double.pi / 5
        
        var path = Path()
        
        for i in 0..<10 {
            let angle = Double(i) * angleIncrement - Double.pi / 2
            let radius = i.isMultiple(of: 2) ? outerRadius : innerRadius
            let x = center.x + CGFloat(cos(angle)) * radius
            let y = center.y + CGFloat(sin(angle)) * radius
            
            if i == 0 {
                path.move(to: CGPoint(x: x, y: y))
            } else {
                path.addLine(to: CGPoint(x: x, y: y))
            }
        }
        
        path.closeSubpath()
        return path
    }
}

// MARK: - Preview
#Preview("Confetti Celebration") {
    ZStack {
        Color.black.opacity(0.3)
            .ignoresSafeArea()
        
        ConfettiView()
    }
}


