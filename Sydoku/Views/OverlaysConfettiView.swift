import SwiftUI

struct ConfettiView: View {
    @State private var animate = false
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

struct ConfettiPiece: View {
    let color: Color
    
    var body: some View {
        Circle()
            .fill(color)
            .frame(width: 10, height: 10)
    }
}
