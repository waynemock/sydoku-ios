//
//  CloudKitStatus.swift
//  Sydoku
//
//  Created by Wayne Mock on 9/3/20.
//  Copyright © 2020 Syzygy Softwerks LLC. All rights reserved.
//

internal import CloudKit
import SwiftUI
import Combine

typealias CloudKitStatusCompletionHandler = (_ accountStatus: CKAccountStatus) -> Void

/// Manages CloudKit account status monitoring and provides user-friendly descriptions.
///
/// This class is created once at the app level and shared throughout the app via `@EnvironmentObject`.
/// It monitors CloudKit account changes and provides reactive updates to the UI.
@MainActor
class CloudKitStatus: ObservableObject {

	// MARK: - Properties
	private let container = CKContainer.default()
	private let logger = AppLogger(category: "CloudKitStatus")
	
	/// The current CloudKit account status.
	@Published private(set) var accountStatus: CKAccountStatus = .couldNotDetermine
	
	private(set) var completionHandler: CloudKitStatusCompletionHandler? = nil
	private var isRequesting = false
	private var accountDidChangeTimer: Timer?
	
	/// Whether the user has a valid iCloud account available.
	var isAvailable: Bool {
		accountStatus == .available
	}
	
	/// User-friendly description of the current status.
	var statusDescription: String {
		switch accountStatus {
		case .available:
			return "iCloud is connected and ready"
		case .noAccount:
			return "No iCloud account found"
		case .restricted:
			return "iCloud access is restricted"
		case .couldNotDetermine:
			return "Checking iCloud status..."
		case .temporarilyUnavailable:
			return "iCloud is temporarily unavailable"
		@unknown default:
			return "Unknown iCloud status"
		}
	}
	
	/// Returns a debug-friendly string with both code and description.
	private func accountStatusString(_ status: CKAccountStatus) -> String {
		let description: String
		switch status {
		case .available:
			description = "available"
		case .noAccount:
			description = "noAccount"
		case .restricted:
			description = "restricted"
		case .couldNotDetermine:
			description = "couldNotDetermine"
		case .temporarilyUnavailable:
			description = "temporarilyUnavailable"
		@unknown default:
			description = "unknown"
		}
		return "\(description) (code: \(status.rawValue))"
	}

	init() {
		NotificationCenter.default.addObserver(self, selector: #selector(accountDidChange(_:)), name: Notification.Name.CKAccountChanged, object: nil)
	}

	// MARK: - Initialization
	/// Initializes CloudKit status monitoring with a completion handler.
	/// - Parameter completionHandler: Called when the status is determined or changes.
	public func initialize(completionHandler: @escaping CloudKitStatusCompletionHandler) {
		self.completionHandler = completionHandler
		requestAccountStatus()
	}

	deinit {
		NotificationCenter.default.removeObserver(self)
	}

	// MARK: - Notification Handling
	@objc private func accountDidChange(_ notification: Notification) {
		/// This notification can fire frequently after iCloud login, so we debounce it
		Task { @MainActor [weak self] in
			guard let self = self else { return }
			guard !self.isRequesting && self.accountDidChangeTimer == nil else { return }
			self.accountDidChangeTimer = Timer.scheduledTimer(withTimeInterval: 0.25, repeats: false) { [weak self] _ in
				guard let self = self else { return }
				Task { @MainActor in
					self.requestAccountStatus()
					self.accountDidChangeTimer = nil
				}
			}
		}
	}

	// MARK: - Helper Methods
	/// Requests the current CloudKit account status.
	public func requestAccountStatus() {
		guard !isRequesting else { return }
		isRequesting = true
		
		Task { @MainActor in
			do {
				let status = try await container.accountStatus()
				
				if self.accountStatus != status {
					logger.info(self, "accountStatus=\(self.accountStatusString(status))")
					self.accountStatus = status
					self.completionHandler?(status)
				}
			} catch {
				logger.error(self, "\(error.localizedDescription)")
			}
			
			self.isRequesting = false
		}
	}
}
