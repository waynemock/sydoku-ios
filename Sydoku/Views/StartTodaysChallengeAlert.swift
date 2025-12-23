import SwiftUI

/// An alert that prompts the user when they have an expired daily challenge.
///
/// Appears when a saved daily challenge is from a previous day. Gives the user
/// the option to start today's challenge or continue playing the expired one
/// (which won't count toward statistics or streak).
struct StartTodaysChallengeAlert: ViewModifier {
    /// Whether to show the alert.
    @Binding var isPresented: Bool
    
    /// The game instance.
    let game: SudokuGame
    
    /// Closure to call when user wants to start today's challenge.
    let onStartToday: () -> Void
    
    func body(content: Content) -> some View {
        content
            .alert(isPresented: $isPresented) {
                Alert(
                    title: Text("Yesterday's Daily Challenge"),
                    message: Text("This daily challenge is from a previous day. You can continue playing, but it won't count toward your statistics or streak. Start today's challenge instead?"),
                    primaryButton: .default(Text("Today's Challenge")) {
                        onStartToday()
                    },
                    secondaryButton: .cancel(Text("Continue Anyway")) {
                        game.postLoadSetup()
                    }
                )
            }
    }
}

extension View {
    /// Presents an alert for expired daily challenges.
    ///
    /// - Parameters:
    ///   - isPresented: Binding to control alert presentation.
    ///   - game: The game instance managing puzzle state.
    ///   - onStartToday: Closure to call when user chooses to start today's challenge.
    func startTodaysChallengeAlert(
        isPresented: Binding<Bool>,
        game: SudokuGame,
        onStartToday: @escaping () -> Void
    ) -> some View {
        modifier(StartTodaysChallengeAlert(
            isPresented: isPresented,
            game: game,
            onStartToday: onStartToday
        ))
    }
}
