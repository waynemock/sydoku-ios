//
//  FooterView.swift
//  Sydoku
//
//  Created by Wayne Mock on 12/23/25.
//

import SwiftUI

/// Footer section containing input controls, number pad, and game status indicators.
///
/// `FooterView` displays the input controls (Pen/Notes/Undo/Redo), the number pad
/// for inputting numbers, along with the mistakes counter and timer at the bottom
/// of the game interface.
struct FooterView: View {
    /// The game instance managing puzzle state and logic.
    @ObservedObject var game: SudokuGame
    
    /// The current theme for styling.
    let theme: Theme
    
    /// Binding to control showing the new game picker.
    @Binding var showingNewGamePicker: Bool
    
    var body: some View {
        VStack {
            if (!game.isComplete) {
                // Input controls (Pen/Notes/Undo/Redo) - always above number pad
                InputControls(game: game, theme: theme)

                // Number Pad
                NumberPad(game: game, showingNewGamePicker: $showingNewGamePicker)
            }


            // Mistakes and Timer, always reserve space for it
            HStack(spacing: 16) {
                MistakesCounter(game: game, theme: theme)
                Spacer()
                TimerButtonView(game: game, theme: theme)
            }
            .padding(.horizontal)
            .frame(maxWidth: 600, minHeight: 36)  // Limit to portrait-like width
        }
    }
}
