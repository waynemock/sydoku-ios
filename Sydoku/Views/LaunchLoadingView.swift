//
//  LaunchLoadingView.swift
//  Sydoku
//
//  Created by Wayne Mock on 12/20/25.
//

import SwiftUI

/// An overlay shown during app launch while syncing from CloudKit.
struct LaunchLoadingView: View {
    @Environment(\.theme) private var theme
    @State private var dotScale: [CGFloat] = [1.0, 1.0, 1.0]
    @State private var opacity: Double = 0
    
    /// Whether the sync is taking longer than expected.
    var isSlowConnection: Bool = false
    
    /// Action to perform when user taps cancel.
    var onCancel: (() -> Void)?
    
    var body: some View {
        ZStack {
            // Semi-transparent background
            Color.black.opacity(0.5)
                .ignoresSafeArea()
            
            // Loading card
            VStack(spacing: 16) {
                // Syncing message
                Text("Syncing with iCloud...")
                    .font(.appHeadline)
                    .fontWeight(.semibold)
                    .foregroundColor(theme.primaryText)
                
                // Loading indicator
                HStack(spacing: 8) {
                    ForEach(0..<3) { index in
                        Circle()
                            .fill(theme.primaryAccent)
                            .frame(width: 10, height: 10)
                            .scaleEffect(dotScale[index])
                    }
                }
                
                // Slow connection warning
                if isSlowConnection {
                    VStack(spacing: 12) {
                        HStack(spacing: 8) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.caption)
                                .foregroundColor(.orange)
                            
                            Text("Slow or no internet connection")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(theme.secondaryText)
                        }
                        .padding(.top, 4)
                        
                        Button {
                            onCancel?()
                        } label: {
                            Text("Let me play!")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 10)
                                .background(
                                    Capsule()
                                        .fill(theme.primaryAccent)
                                )
                        }
                        
                        Text("Syncing continues in the background")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(theme.secondaryText)
                    }
                    .transition(.opacity.combined(with: .scale(scale: 0.9)))
                }
            }
            .padding(24)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(theme.backgroundColor)
                    .shadow(color: Color.black.opacity(0.2), radius: 20, x: 0, y: 10)
            )
            .padding(32)
            .opacity(opacity)
        }
        .task {
            // Fade in immediately
            withAnimation(.easeOut(duration: 0.2)) {
                opacity = 1
            }
            
            // Animate dots in sequence (wave effect)
            animateDots()
        }
    }
    
    /// Animates the loading dots in a wave pattern.
    private func animateDots() {
        for index in 0..<3 {
            withAnimation(
                .easeInOut(duration: 0.6)
                .repeatForever(autoreverses: true)
                .delay(Double(index) * 0.2)
            ) {
                dotScale[index] = 1.5
            }
        }
    }
}

#Preview("Blossom Light") {
    LaunchLoadingView()
        .environment(\.theme, Theme(type: .blossom, colorScheme: .light))
}
#Preview("Slow Connection - Blossom Dark") {
    LaunchLoadingView(isSlowConnection: true)
        .environment(\.theme, Theme(type: .blossom, colorScheme: .dark))
}

#Preview("Slow Connection - Ocean Light") {
    LaunchLoadingView(isSlowConnection: true)
        .environment(\.theme, Theme(type: .ocean, colorScheme: .light))
}

#Preview("Ocean Light") {
    LaunchLoadingView()
        .environment(\.theme, Theme(type: .ocean, colorScheme: .light))
}
#Preview("Midnight Dark") {
    LaunchLoadingView()
        .environment(\.theme, Theme(type: .midnight, colorScheme: .dark))
}

#Preview("Forest Light") {
    LaunchLoadingView()
        .environment(\.theme, Theme(type: .forest, colorScheme: .light))
}

