import SwiftUI

struct PauseOverlay: View {
    @ObservedObject var game: SudokuGame
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.9)
                .edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 30) {
                Image(systemName: "pause.circle.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.white)
                
                Text("Game Paused")
                    .font(.system(size: 36, weight: .bold))
                    .foregroundColor(.white)
                
                Text(game.formattedTime)
                    .font(.system(size: 28, weight: .medium, design: .monospaced))
                    .foregroundColor(.white.opacity(0.8))
                
                Button(action: {
                    game.resumeTimer()
                }) {
                    HStack {
                        Image(systemName: "play.fill")
                        Text("Resume")
                    }
                    .font(.system(size: 24, weight: .semibold))
                    .padding(.horizontal, 40)
                    .padding(.vertical, 16)
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
            }
        }
    }
}
