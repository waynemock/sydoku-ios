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
    
    /// Environment theme.
    @Environment(\.theme) var theme
    
    /// Animation state for the overlay appearance.
    @State private var isAnimating = false
    
    func body(content: Content) -> some View {
        content
            .overlay {
                if isPresented {
                    ZStack {
                        // Blurred background
                        Color.black.opacity(0.7)
                            .blur(radius: isAnimating ? 0 : 20)
                            .onTapGesture {
                                dismissAlert()
                            }
                        
                        // Alert card container
                        VStack(spacing: 24) {
                            // Icon
                            Image(systemName: "calendar.badge.clock")
                                .font(.system(size: 50))
                                .foregroundStyle(
                                    .linearGradient(
                                        colors: [theme.primaryAccent, theme.secondaryAccent],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .shadow(color: theme.primaryAccent.opacity(0.5), radius: 15)
                            
                            VStack(spacing: 12) {
                                // Title
                                Text("New Day")
                                    .font(.title2.weight(.bold))
                                    .foregroundColor(theme.primaryText)
                                
                                // Message
                                Text("You have an unfinished daily challenge from a previous day.")
                                    .font(.body)
                                    .foregroundColor(theme.secondaryText)
                                    .multilineTextAlignment(.center)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            
                            // Buttons
                            VStack(spacing: 12) {
                                // Primary button - Start Today
                                Button(action: {
                                    dismissAlert()
                                    onStartToday()
                                }) {
                                    Text("Start Today")
                                        .font(.body.weight(.semibold))
                                        .foregroundColor(.white)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 14)
                                        .background(
                                            RoundedRectangle(cornerRadius: 12)
                                                .fill(
                                                    LinearGradient(
                                                        colors: [theme.primaryAccent, theme.primaryAccent.opacity(0.8)],
                                                        startPoint: .topLeading,
                                                        endPoint: .bottomTrailing
                                                    )
                                                )
                                        )
                                        .shadow(color: theme.primaryAccent.opacity(0.4), radius: 8, y: 4)
                                }
                                .buttonStyle(ScaleButtonStyle())
                                
                                // Secondary button - Finish Previous
                                Button(action: {
                                    dismissAlert()
                                    // Game was already loaded, timer already started if not paused
                                    // User just chose to continue playing the expired challenge
                                }) {
                                    Text("Finish Previous")
                                        .font(.body.weight(.medium))
                                        .foregroundColor(theme.secondaryText)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 14)
                                        .background(
                                            RoundedRectangle(cornerRadius: 12)
                                                .fill(theme.cellBackgroundColor.opacity(0.5))
                                        )
                                }
                                .buttonStyle(ScaleButtonStyle())
                            }
                        }
                        .padding(28)
                        .frame(maxWidth: 340)
                        .background(
                            RoundedRectangle(cornerRadius: 24)
                                .fill(.ultraThinMaterial)
                                .shadow(color: Color.black.opacity(0.3), radius: 30, y: 10)
                        )
                        .scaleEffect(isAnimating ? 1.0 : 0.8)
                        .opacity(isAnimating ? 1.0 : 0.0)
                    }
                    .ignoresSafeArea()
                    .transition(.opacity)
                    .onAppear {
                        withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                            isAnimating = true
                        }
                    }
                }
            }
    }
    
    /// Dismisses the alert with animation.
    private func dismissAlert() {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
            isAnimating = false
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            isPresented = false
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
