import SwiftUI

/// A realistic confetti animation view with explosion effect.
///
/// Creates confetti that explodes upward from the bottom center, then floats
/// down naturally with rotation and physics-based movement before fading away.
struct ConfettiView: View {
    @State private var confettiPieces: [ConfettiPieceModel] = []
    @State private var hasGenerated = false
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(confettiPieces) { piece in
                    ConfettiPieceView(piece: piece)
                }
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
            .onAppear {
                if !hasGenerated {
                    generateConfetti(in: geometry.size)
                    hasGenerated = true
                }
            }
            .task {
                // Alternative trigger that works better with SwiftUI lifecycle
                if confettiPieces.isEmpty {
                    generateConfetti(in: geometry.size)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .ignoresSafeArea()
    }
    
    /// Generates confetti pieces that explode from the bottom center.
    private func generateConfetti(in size: CGSize) {
        let pieceCount = 200 // Doubled from 100
        let explosionPoint = CGPoint(x: size.width / 2, y: size.height - 100) // Start slightly above bottom
        
        // Calculate spread to be 10% wider than screen (55% on each side = 110% total)
        let maxSpreadPercent: CGFloat = 0.55
        let maxHorizontalSpread = size.width * maxSpreadPercent
        
        for i in 0..<pieceCount {
            // Higher velocities for faster, more dramatic effect
            let velocity: CGFloat
            let rand = Double.random(in: 0...1)
            if rand < 0.3 {
                // 30% shoot very high
                velocity = CGFloat.random(in: 1100...1500)
            } else if rand < 0.7 {
                // 40% medium-high (most visible)
                velocity = CGFloat.random(in: 800...1100)
            } else {
                // 30% moderate
                velocity = CGFloat.random(in: 600...800)
            }
            
            // Start with mostly upward direction (-90° = straight up)
            let baseAngle = -90.0 * .pi / 180
            
            // Add a horizontal deviation based on screen width
            let avgPeakHeight: CGFloat = 900
            let maxAngleDeviation = atan(maxHorizontalSpread / avgPeakHeight)
            let angleDeviation = Double.random(in: -maxAngleDeviation...maxAngleDeviation)
            
            let angle = baseAngle + angleDeviation
            
            // Calculate initial velocity components
            // Note: In iOS, Y increases downward, so negative Y velocity = upward motion
            let velocityX = cos(angle) * velocity
            let velocityY = sin(angle) * velocity // This will be negative (upward)
            
            let piece = ConfettiPieceModel(
                id: i,
                startX: explosionPoint.x,
                startY: explosionPoint.y,
                velocityX: velocityX,
                velocityY: velocityY,
                shape: ConfettiShape.allCases.randomElement()!,
                color: ConfettiColor.allCases.randomElement()!.color,
                size: CGFloat.random(in: 10...18),
                rotationSpeed: Double.random(in: -10...10),
                screenSize: size
            )
            confettiPieces.append(piece)
        }
    }
}

/// A single confetti piece with animation state.
struct ConfettiPieceModel: Identifiable {
    let id: Int
    let startX: CGFloat
    let startY: CGFloat
    let velocityX: CGFloat
    let velocityY: CGFloat
    let shape: ConfettiShape
    let color: Color
    let size: CGFloat
    let rotationSpeed: Double
    let screenSize: CGSize
}

/// Individual confetti piece view with physics-based animation.
struct ConfettiPieceView: View {
    let piece: ConfettiPieceModel
    
    @State private var offsetX: CGFloat = 0
    @State private var offsetY: CGFloat = 0
    @State private var rotation: Double = 0
    @State private var opacity: Double = 1
    
    var body: some View {
        let (width, height) = piece.shape == .rectangle ? (piece.size * 0.4, piece.size) : (piece.size, piece.size)
        
        piece.shape.shape
            .fill(piece.color)
            .frame(width: width, height: height)
            .rotationEffect(Angle.degrees(rotation))
            .position(
                x: piece.startX + offsetX,
                y: piece.startY + offsetY
            )
            .opacity(opacity)
            .onAppear {
                animate()
            }
    }
    
    /// Animates the confetti with explosion physics and floating fall.
    private func animate() {
        // Faster rotation animation
        withAnimation(
            .linear(duration: abs(1.0 / piece.rotationSpeed))
            .repeatForever(autoreverses: false)
        ) {
            rotation = piece.rotationSpeed > 0 ? 360 : -360
        }
        
        // Animation timing
        let speedFactor = piece.velocityY / 1000.0 // Normalize to higher velocity
        let launchDuration: Double = 0.6 * abs(speedFactor) // Quick launch
        let fallDuration: Double = 2.0 + Double.random(in: 0...1.0) // Longer fall time
        let fadeDuration: Double = 0.5 // Quick fade only at the end
        
        // Calculate peak position (where velocity becomes zero)
        let gravity: CGFloat = 800
        let peakY = -(piece.velocityY * piece.velocityY) / (2 * gravity)
        let peakX = piece.velocityX * CGFloat(launchDuration)
        
        // Quick launch to peak
        withAnimation(.easeOut(duration: launchDuration)) {
            self.offsetX = peakX
            self.offsetY = peakY
        }
        
        // Fall back down with full opacity
        DispatchQueue.main.asyncAfter(deadline: .now() + launchDuration) {
            // Fall to varied positions
            let finalY = CGFloat.random(in: -200...100)
            // More horizontal drift for wider spread
            let horizontalDrift = piece.velocityX * 0.2 * CGFloat(fallDuration)
            let finalX = peakX + horizontalDrift
            
            withAnimation(.easeIn(duration: fallDuration)) {
                self.offsetY = finalY
                self.offsetX = finalX
            }
            
            // Only start fading AFTER the confetti has stopped moving
            DispatchQueue.main.asyncAfter(deadline: .now() + fallDuration) {
                withAnimation(.easeOut(duration: fadeDuration)) {
                    self.opacity = 0
                }
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
    struct ConfettiPreviewWrapper: View {
        @State private var showConfetti = false
        @State private var confettiID = UUID()
        
        var body: some View {
            ZStack {
                // Dark mode background
                Color.black
                    .ignoresSafeArea()
                
                // Sample game board or content
                VStack {
                    Text("Top of Screen")
                        .font(.caption)
                        .foregroundStyle(.green)
                        .padding(.top, 50)
                    
                    Spacer()
                    
                    Text("Sudoku Complete!")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                    
                    Spacer()
                    
                    Button {
                        showConfetti = true
                        confettiID = UUID() // Force recreation of confetti
                        // Reset after animation completes
                        DispatchQueue.main.asyncAfter(deadline: .now() + 5.5) {
                            showConfetti = false
                        }
                    } label: {
                        Text("Show Confetti 🎉")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 32)
                            .padding(.vertical, 16)
                            .background(
                                Capsule()
                                    .fill(Color.blue)
                            )
                    }
                    .padding(.bottom, 60)
                    
                    Text("Bottom of Screen")
                        .font(.caption)
                        .foregroundStyle(.green)
                        .padding(.bottom, 20)
                }
                
                // Confetti overlay
                if showConfetti {
                    ConfettiView()
                        .id(confettiID) // Force recreation with new ID
                        .allowsHitTesting(false)
                        .background(Color.red.opacity(0.1)) // Debug: see the confetti view bounds
                }
            }
            .preferredColorScheme(.dark)
        }
    }
    
    return ConfettiPreviewWrapper()
}


