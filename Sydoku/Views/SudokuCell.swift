import SwiftUI

struct SudokuCell: View {
    let value: Int
    let cellNotes: Set<Int>
    let isInitial: Bool
    let isSelected: Bool
    let hasConflict: Bool
    let isHighlighted: Bool
    let isLastPlaced: Bool
    let isHintCell: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            ZStack {
                Rectangle()
                    .fill(isSelected ? Color.blue.opacity(0.5) :
                          isHintCell ? Color.green.opacity(0.4) :
                          isHighlighted ? Color.yellow.opacity(0.3) :
                          Color(red: 0.25, green: 0.25, blue: 0.27))
                
                if value != 0 {
                    Text("\(value)")
                        .font(.system(size: 24, weight: isInitial ? .bold : .regular))
                        .foregroundColor(hasConflict ? .red : (isInitial ? .white : Color.cyan))
                        .scaleEffect(isLastPlaced ? 1.3 : 1.0)
                        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isLastPlaced)
                } else if !cellNotes.isEmpty {
                    NotesGrid(notes: cellNotes)
                }
            }
        }
        .aspectRatio(1, contentMode: .fit)
    }
}

struct NotesGrid: View {
    let notes: Set<Int>
    
    var body: some View {
        VStack(spacing: 1) {
            ForEach(0..<3, id: \.self) { row in
                HStack(spacing: 1) {
                    ForEach(1...3, id: \.self) { col in
                        let num = row * 3 + col
                        Text(notes.contains(num) ? "\(num)" : "")
                            .font(.system(size: 9))
                            .foregroundColor(.white.opacity(0.6))
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                }
            }
        }
        .padding(2)
    }
}
