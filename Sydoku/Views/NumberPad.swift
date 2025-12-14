import SwiftUI

struct NumberPad: View {
    @ObservedObject var game: SudokuGame
    
    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                ForEach(1...5, id: \.self) { num in
                    NumberButton(
                        number: num,
                        count: game.getNumberCount(num),
                        isHighlighted: game.highlightedNumber == num,
                        action: {
                            game.setNumber(num)
                            game.highlightedNumber = num
                        }
                    )
                }
            }
            
            HStack(spacing: 12) {
                ForEach(6...9, id: \.self) { num in
                    NumberButton(
                        number: num,
                        count: game.getNumberCount(num),
                        isHighlighted: game.highlightedNumber == num,
                        action: {
                            game.setNumber(num)
                            game.highlightedNumber = num
                        }
                    )
                }
                
                Button(action: {
                    game.clearCell()
                    game.highlightedNumber = nil
                }) {
                    Image(systemName: "delete.left")
                        .font(.system(size: 28))
                        .frame(maxWidth: .infinity)
                        .frame(height: 60)
                        .background(Color.red)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
            }
        }
        .padding()
    }
}

struct NumberButton: View {
    let number: Int
    let count: Int
    let isHighlighted: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 2) {
                Text("\(number)")
                    .font(.system(size: 28, weight: .semibold))
                if count > 0 {
                    Text("\(count)/9")
                        .font(.system(size: 10))
                        .opacity(0.7)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 60)
            .background(count == 9 ? Color.gray : (isHighlighted ? Color.blue.opacity(0.8) : Color.blue))
            .foregroundColor(.white)
            .cornerRadius(10)
        }
        .disabled(count == 9)
    }
}
