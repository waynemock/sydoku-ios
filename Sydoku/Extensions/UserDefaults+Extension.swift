//
//  UserDefaultsExtension.swift
//  SyWord
//
//  Created by Wayne Mock on 1/25/19.
//  Copyright © 2020 Syzygy Softwerks LLC. All rights reserved.
//

import Foundation

extension UserDefaults {

	private struct Keys	{
		static let skipCloudKitCheck = "SkipCloudKitCheck"
	}

	/// Returns `true` if the user has chosen to permanently dismiss the iCloud setup prompt.
	///
	/// When set to `true`, the app will no longer show the iCloud status indicator or prompt
	/// the user to set up iCloud, even if iCloud is not available.
	public var isSkipCloudKitCheck: Bool {
		get {
			return bool(forKey: Keys.skipCloudKitCheck)
		}
		set	{
			set(newValue, forKey: Keys.skipCloudKitCheck)
		}
	}
}
