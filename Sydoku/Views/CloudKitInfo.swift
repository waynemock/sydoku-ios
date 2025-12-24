//
//  CloudKitInfo.swift
//  Sydoku
//
//  Created by Wayne Mock on 11/24/20.
//

internal import CloudKit
import SwiftUI
import Combine

/// A view that explains iCloud integration and helps users set up their iCloud account.
struct CloudKitInfo: View {
	@Environment(\.dismiss) var dismiss
    
    /// Environment theme.
    @Environment(\.theme) var theme
    
    /// The shared CloudKit status manager from the app environment.
    @EnvironmentObject private var cloudKitStatus: CloudKitStatus

	@State private var showSuccessAnimation = false
	@State private var showingDebugView = false

	private let becameActivePublisher = NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)

	var body: some View {
		NavigationStack {
			ScrollView {
				VStack(spacing: 20) {
					// Hero section
					VStack(spacing: 16) {
						ZStack {
							// Background circle for icon
							Circle()
								.fill(theme.primaryAccent.opacity(0.1))
								.frame(width: 120, height: 120)
							
							Image(systemName: cloudKitStatus.isAvailable ? "icloud.fill" : "icloud.slash.fill")
								.font(.system(size: 60))
								.foregroundColor(theme.primaryAccent)
								.symbolEffect(.bounce, value: showSuccessAnimation)
						}
						
						Text("Sydoku + iCloud")
							.font(.title.bold())
							.foregroundColor(theme.primaryText)
						
						Text(cloudKitStatus.statusDescription)
							.font(.subheadline)
							.foregroundColor(theme.secondaryText)
					}
					.padding(.top, -50)
					
					// Content based on status
					Group {
						if cloudKitStatus.accountStatus == .available {
							successView
						} else if cloudKitStatus.accountStatus == .couldNotDetermine {
							loadingView
						} else {
							setupView
						}
					}
					.animation(.easeInOut(duration: 0.3), value: cloudKitStatus.accountStatus)
					
					// Benefits section (always shown when not loading)
					if cloudKitStatus.accountStatus != .couldNotDetermine {
						benefitsView
					}
				}
				.padding()
			}
			.frame(maxWidth: .infinity, maxHeight: .infinity)
			.background(theme.backgroundColor)
			.navigationBarTitleDisplayMode(.inline)
			.toolbar {
				ToolbarItem(placement: .navigationBarLeading) {
					Button {
						showingDebugView = true
					} label: {
						Image(systemName: "ladybug.fill")
							.foregroundColor(theme.secondaryText)
					}
				}
				
				ToolbarItem(placement: .navigationBarTrailing) {
					Button("Done") {
						dismiss()
					}
					.fontWeight(.semibold)
					.foregroundColor(theme.primaryAccent)
				}
			}
			.sheet(isPresented: $showingDebugView) {
				CloudKitDebugView()
					.environmentObject(cloudKitStatus)
			}
			.onAppear {
				cloudKitStatus.initialize() { status in
					if status == .available {
						showSuccessAnimation.toggle()
					}
				}
			}
			.onReceive(becameActivePublisher) { _ in
				cloudKitStatus.requestAccountStatus()
			}
		}
	}
	
	// MARK: - Subviews
	
	private var successView: some View {
		VStack(spacing: 16) {
			Image(systemName: "checkmark.circle.fill")
				.font(.system(size: 60))
				.foregroundColor(.green)
				.symbolEffect(.bounce, value: showSuccessAnimation)
			
			Text("You're All Set!")
				.font(.title2.bold())
				.foregroundColor(theme.primaryText)
			
			Text("Your Sudoku progress and statistics are now syncing across all your devices using iCloud.")
				.font(.body)
				.foregroundColor(theme.secondaryText)
				.multilineTextAlignment(.center)
				.padding(.horizontal)
		}
		.padding(.vertical)
	}
	
	private var loadingView: some View {
		VStack(spacing: 16) {
			ProgressView()
				.progressViewStyle(CircularProgressViewStyle(tint: theme.primaryAccent))
				.scaleEffect(1.5)
				.padding()
			
			Text("Checking your iCloud status...")
				.font(.body)
				.foregroundColor(theme.secondaryText)
		}
		.padding(.vertical)
	}
	
	private var setupView: some View {
		VStack(spacing: 20) {
			// Value proposition callout
			VStack(spacing: 12) {
				HStack(spacing: 8) {
					Image(systemName: "exclamationmark.triangle.fill")
						.foregroundColor(.orange)
					Text("Your Progress Isn't Being Saved")
						.font(.subheadline.bold())
						.foregroundColor(theme.primaryText)
				}
				
				Text("Without iCloud, if you delete the app or get a new device, you'll lose all your game history, statistics, and daily challenge streaks.")
					.font(.caption)
					.foregroundColor(theme.secondaryText)
					.multilineTextAlignment(.center)
			}
			.padding()
			.frame(maxWidth: .infinity)
			.background(
				RoundedRectangle(cornerRadius: 12)
					.fill(Color.orange.opacity(0.1))
                    .overlay {
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.orange.opacity(0.3), lineWidth: 1)
                    }
			)
			
			VStack(alignment: .leading, spacing: 12) {
				Text("To enable iCloud sync:")
					.font(.headline)
					.foregroundColor(theme.primaryText)
				
				setupStep(number: "1", text: "Open the Settings app on your device")
				setupStep(number: "2", text: "Tap your name at the top")
				setupStep(number: "3", text: "Sign in to your Apple Account if you haven't already")
				setupStep(number: "4", text: "Ensure iCloud is turned on")
			}
			.frame(maxWidth: .infinity, alignment: .leading)
			.padding()
			.background(
				RoundedRectangle(cornerRadius: 12)
					.fill(theme.primaryAccent.opacity(0.05))
			)
			
			Button(action: openSettings) {
				HStack {
					Image(systemName: "gear")
					Text("Open Settings")
				}
				.fontWeight(.semibold)
				.foregroundColor(.white)
				.frame(maxWidth: .infinity)
				.frame(height: 50)
				.background(theme.primaryAccent)
				.cornerRadius(12)
			}
			.buttonStyle(.plain)
			
			// Only show "Don't show this again" if user hasn't already dismissed it
			if !UserDefaults.standard.isSkipCloudKitCheck {
				Button(action: dismissPermanently) {
					Text("Don't show this again")
						.font(.subheadline)
						.foregroundColor(theme.secondaryText)
				}
				.buttonStyle(.plain)
				.padding(.top, 8)
			}
		}
	}
	
	private var benefitsView: some View {
		VStack(alignment: .leading, spacing: 16) {
			Text("Why use iCloud with Sydoku?")
				.font(.headline)
				.foregroundColor(theme.primaryText)
			
			VStack(spacing: 16) {
				benefitRow(
					icon: "arrow.left.arrow.right.circle.fill", 
					title: "Play Anywhere", 
					description: "Start a puzzle on your iPhone and finish it on your iPad. Your progress syncs automatically."
				)
				benefitRow(
					icon: "clock.badge.checkmark", 
					title: "Sync Takes Time", 
					description: "iCloud sync typically takes 30-60 seconds. Changes save locally right away, then sync in the background."
				)
				benefitRow(
					icon: "chart.line.uptrend.xyaxis", 
					title: "Keep Your Stats", 
					description: "Track your solve times, win streaks, and daily challenge progress across all devices."
				)
				benefitRow(
					icon: "calendar.badge.clock", 
					title: "Never Miss Daily Challenges", 
					description: "Your daily challenge streak and history are preserved, even if you switch devices."
				)
				benefitRow(
					icon: "arrow.counterclockwise.circle.fill", 
					title: "Automatic Backup", 
					description: "Your saved games and settings are backed up automatically. Upgrade to a new device worry-free."
				)
				benefitRow(
					icon: "lock.shield.fill", 
					title: "Private & Secure", 
					description: "All your data is encrypted and only accessible to you. Apple can't read your game data."
				)
				benefitRow(
					icon: "wifi.slash", 
					title: "Works Offline", 
					description: "Play without internet. Your progress syncs automatically when you're back online."
				)
			}
		}
		.padding()
		.background(
			RoundedRectangle(cornerRadius: 12)
				.fill(theme.primaryAccent.opacity(0.05))
		)
	}
	
	private func setupStep(number: String, text: String) -> some View {
		HStack(alignment: .center, spacing: 12) {
			Text(number)
				.font(.headline)
				.foregroundColor(.white)
				.frame(width: 28, height: 28)
				.background(
					Circle()
						.fill(theme.primaryAccent)
				)
			
			Text(text)
				.font(.body)
				.foregroundColor(theme.secondaryText)
				.frame(maxWidth: .infinity, alignment: .leading)
		}
	}
	
	private func benefitRow(icon: String, title: String, description: String) -> some View {
		HStack(alignment: .top, spacing: 12) {
			// Fixed-width container for icon to ensure alignment
			ZStack {
				Image(systemName: icon)
					.font(.title2)
					.foregroundColor(theme.primaryAccent)
			}
			.frame(width: 32, height: 32)
			
			VStack(alignment: .leading, spacing: 4) {
				Text(title)
					.font(.subheadline.bold())
					.foregroundColor(theme.primaryText)
				Text(description)
					.font(.caption)
					.foregroundColor(theme.secondaryText)
					.fixedSize(horizontal: false, vertical: true)
			}
			.frame(maxWidth: .infinity, alignment: .leading)
		}
	}
	
	// MARK: - Actions

	private func openSettings() {
		guard let settingsUrl = URL(string: UIApplication.openSettingsURLString) else { return }
		if UIApplication.shared.canOpenURL(settingsUrl) {
			UIApplication.shared.open(settingsUrl)
		}
	}

	private func dismissPermanently() {
		UserDefaults.standard.isSkipCloudKitCheck = true
		dismiss()
	}
}

#Preview {
	CloudKitInfo()
		.environment(\.theme, Theme())
		.environmentObject(CloudKitStatus())
}
