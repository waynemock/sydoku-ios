//
//  SwipeToDeleteModifier.swift
//  Sydoku
//
//  Created by Wayne Mock on 12/24/25.
//

import SwiftUI

/// A view modifier that adds swipe-to-delete functionality to any view.
///
/// Provides a native iOS-style swipe gesture that reveals a delete button
/// when swiping left. Works with ScrollView and LazyVStack, unlike List's
/// swipe actions which require List containers.
struct SwipeToDelete: ViewModifier {
    /// The theme for styling the delete button.
    let theme: Theme
    
    /// Callback when the delete button is tapped.
    let onDelete: () -> Void
    
    /// Current swipe offset.
    @State private var offset: CGFloat = 0
    
    /// Whether the delete button is revealed.
    @State private var isRevealed: Bool = false
    
    /// Whether deletion is in progress.
    @State private var isDeleting: Bool = false
    
    /// Rotation angle for the spinning indicator.
    @State private var spinnerRotation: Double = 0
    
    /// Width of the delete button.
    private let deleteButtonWidth: CGFloat = 80
    
    /// Threshold for visual "ready to delete" feedback.
    private let readyThreshold: CGFloat = -120

    /// Threshold for triggering auto-delete on full swipe.
    private let deleteThreshold: CGFloat = -200

    func body(content: Content) -> some View {
        ZStack(alignment: .trailing) {
            deleteButton

            // Main content
            content
                .background(Color.clear) // Ensure content has a background to cover delete button
                .offset(x: offset)
                .gesture(
                    DragGesture(minimumDistance: 20)
                        .onChanged { gesture in
                            let translation = gesture.translation.width
                            let verticalTranslation = gesture.translation.height
                            
                            // Only handle horizontal swipes (not vertical scrolls)
                            guard abs(translation) > abs(verticalTranslation) else {
                                return
                            }
                            
                            // Only allow left swipe (negative translation)
                            if translation < 0 {
                                offset = translation
                            } else if isRevealed {
                                // Allow swiping back right when revealed
                                offset = max(translation - deleteButtonWidth, -deleteButtonWidth)
                            }
                        }
                        .onEnded { gesture in
                            let translation = gesture.translation.width
                            let verticalTranslation = gesture.translation.height
                            let velocity = gesture.predictedEndTranslation.width - gesture.translation.width
                            
                            // If this was primarily a vertical gesture, don't handle it
                            guard abs(translation) > abs(verticalTranslation) else {
                                return
                            }
                            
                            // Check for full swipe delete
                            if translation < deleteThreshold || velocity < -500 {
                                // Full swipe - delete immediately
                                isDeleting = true
                                withAnimation(.easeOut(duration: 0.3)) {
                                    offset = -UIScreen.main.bounds.width
                                }
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                    onDelete()
                                    isDeleting = false
                                }
                            } else if translation < -deleteButtonWidth / 2 {
                                // Reveal delete button
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                    offset = -deleteButtonWidth
                                    isRevealed = true
                                }
                            } else {
                                // Snap back
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                    offset = 0
                                    isRevealed = false
                                }
                            }
                        }
                )
        }
        .clipped()
    }
    
    /// The delete button that appears when swiping left.
    private var deleteButton: some View {
        // Calculate states based on thresholds
        let pastReadyThreshold = offset < readyThreshold
        let pastDeleteThreshold = offset < deleteThreshold
        
        // Calculate dynamic width (expands when past ready threshold)
        let buttonWidth: CGFloat = {
            if pastDeleteThreshold {
                return deleteButtonWidth * 1.5
            } else if pastReadyThreshold {
                // Interpolate between normal and expanded
                let progress = min(abs(offset - readyThreshold) / abs(deleteThreshold - readyThreshold), 1.0)
                return deleteButtonWidth * (1.0 + progress * 0.5)
            } else {
                return deleteButtonWidth
            }
        }()
        
        return HStack(spacing: 0) {
            Spacer()
            
            Button(action: {
                isDeleting = true
                withAnimation(.easeOut(duration: 0.3)) {
                    offset = -UIScreen.main.bounds.width
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    onDelete()
                    isDeleting = false
                }
            }) {
                VStack(spacing: 4) {
                    // Always show trash icon inside progress circle
                    ZStack {
                        // Progress circles - shown when past ready threshold or deleting
                        if pastReadyThreshold || isDeleting {
                            Circle()
                                .stroke(Color.white.opacity(0.3), lineWidth: 3)
                                .frame(width: circleSize, height: circleSize)
                                .scaleEffect(circleScale)
                                .opacity(circleOpacity)
                            
                            if isDeleting {
                                // Spinning progress ring during deletion
                                Circle()
                                    .trim(from: 0, to: 0.7)
                                    .stroke(Color.white, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                                    .frame(width: circleSize, height: circleSize)
                                    .scaleEffect(circleScale)
                                    .opacity(circleOpacity)
                                    .rotationEffect(.degrees(-90))
                                    .rotationEffect(.degrees(spinnerRotation))
                                    .onAppear {
                                        withAnimation(.linear(duration: 0.8).repeatForever(autoreverses: false)) {
                                            spinnerRotation = 360
                                        }
                                    }
                            } else {
                                // Progress fill circle
                                Circle()
                                    .trim(from: 0, to: swipeProgress)
                                    .stroke(Color.white, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                                    .frame(width: circleSize, height: circleSize)
                                    .scaleEffect(circleScale)
                                    .opacity(circleOpacity)
                                    .rotationEffect(.degrees(-90))
                            }
                        }
                        
                        // Trash icon - always visible, smoothly scales
                        Image(systemName: "trash.fill")
                            .font(.system(size: iconSize))
                            .foregroundColor(.white)
                    }
                    .animation(.spring(response: 0.35, dampingFraction: 0.7), value: offset)
                    .animation(.spring(response: 0.35, dampingFraction: 0.7), value: isDeleting)
                    
                    Text(isDeleting ? "Deleting..." : "Delete")
                        .font(.caption.weight(.semibold))
                        .opacity(isDeleting ? 0.7 : 1.0)
                        .animation(.easeInOut(duration: 0.2), value: isDeleting)
                }
                .foregroundColor(.white)
                .frame(width: buttonWidth)
                .frame(maxHeight: .infinity)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.red)
                )
            }
            .offset(x: deleteButtonSlideOffset)
        }
        .padding(.leading, 16)
    }
    
    /// Calculate the progress from ready threshold to delete threshold for the progress indicator.
    private var swipeProgress: CGFloat {
        // Progress starts at readyThreshold and completes at deleteThreshold
        guard offset < readyThreshold else { return 0 }
        
        let progressRange = deleteThreshold - readyThreshold
        let currentProgress = offset - readyThreshold
        
        return min(abs(currentProgress) / abs(progressRange), 1.0)
    }
    
    /// Smoothly interpolate icon size based on swipe distance.
    private var iconSize: CGFloat {
        let normalSize: CGFloat = 22 // Roughly title2 size
        let smallSize: CGFloat = 14
        
        // Create a transition zone before the ready threshold
        let transitionZone: CGFloat = 30
        let transitionStart = readyThreshold + transitionZone
        
        if offset >= transitionStart {
            // Haven't entered transition zone yet - normal size
            return normalSize
        } else if offset <= readyThreshold {
            // Past threshold - small size
            return smallSize
        } else {
            // In transition zone - smoothly interpolate
            let progress = (transitionStart - offset) / transitionZone
            return normalSize - (normalSize - smallSize) * progress
        }
    }
    
    /// Circle size for the progress indicator.
    private var circleSize: CGFloat {
        return 36
    }
    
    /// Scale effect for the circles appearing/disappearing.
    private var circleScale: CGFloat {
        let transitionZone: CGFloat = 30
        let transitionStart = readyThreshold + transitionZone
        
        if offset >= transitionStart {
            // Before transition - no circle
            return 0.3
        } else if offset <= readyThreshold {
            // Past threshold - full circle
            return 1.0
        } else {
            // In transition zone - smoothly scale in
            let progress = (transitionStart - offset) / transitionZone
            return 0.3 + (0.7 * progress)
        }
    }
    
    /// Opacity for the circles appearing/disappearing.
    private var circleOpacity: Double {
        let transitionZone: CGFloat = 30
        let transitionStart = readyThreshold + transitionZone
        
        if offset >= transitionStart {
            // Before transition - no circle
            return 0.0
        } else if offset <= readyThreshold {
            // Past threshold - full opacity
            return 1.0
        } else {
            // In transition zone - fade in
            let progress = (transitionStart - offset) / transitionZone
            return Double(progress)
        }
    }
    
    /// Calculate the slide-in offset for the delete button.
    /// The button slides in from the right as the card is swiped left.
    private var deleteButtonSlideOffset: CGFloat {
        // When offset is 0, button should be off-screen to the right (+deleteButtonWidth)
        // When offset is -deleteButtonWidth, button should be at position 0
        // Linear interpolation between these states
        let progress = min(abs(offset) / deleteButtonWidth, 1.0)
        return deleteButtonWidth * (1 - progress)
    }
}

/// View extension for easy swipe-to-delete addition.
extension View {
    /// Adds swipe-to-delete functionality to any view.
    ///
    /// - Parameters:
    ///   - theme: The theme for styling.
    ///   - onDelete: Callback when delete is triggered.
    /// - Returns: A view with swipe-to-delete gesture.
    func swipeToDelete(theme: Theme, onDelete: @escaping () -> Void) -> some View {
        self.modifier(SwipeToDelete(theme: theme, onDelete: onDelete))
    }
}
