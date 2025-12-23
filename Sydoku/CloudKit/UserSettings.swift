//
//  UserSettings.swift
//  Sydoku
//
//  Created by Wayne Mock on 12/18/25.
//

import Foundation
import SwiftData

/// A SwiftData model representing user game settings synced via CloudKit.
///
/// This model stores user preferences and settings that persist
/// across devices through CloudKit sync.
@Model
final class UserSettings {
    /// Whether to automatically check for errors when placing numbers.
    var autoErrorChecking: Bool = false
    
    /// Maximum number of mistakes allowed (0 = unlimited).
    var mistakeLimit: Int = 0
    
    /// Whether haptic feedback is enabled.
    var hapticFeedback: Bool = true
    
    /// Whether sound effects are enabled.
    var soundEffects: Bool = false
    
    /// Whether to highlight cells with the same number.
    var highlightSameNumbers: Bool = true
    
    /// Dates when daily challenges were completed (difficulty -> date string).
    var completedDailyChallenges: [String: String] = [:]
    
    /// The selected theme type (stored as raw value).
    var themeTypeRawValue: String = Theme.ThemeType.blossom.rawValue
    
    /// The preferred color scheme (stored as raw value).
    var preferredColorSchemeRawValue: String = GameSettings.ColorSchemePreference.dark.rawValue
    
    /// When these settings were last updated.
    var lastUpdated: Date = Date()
    
    /// Creates new user settings with default values.
    init(
        autoErrorChecking: Bool = false,
        mistakeLimit: Int = 0,
        hapticFeedback: Bool = true,
        soundEffects: Bool = false,
        highlightSameNumbers: Bool = true,
        completedDailyChallenges: [String: String] = [:],
        themeTypeRawValue: String = Theme.ThemeType.blossom.rawValue,
        preferredColorSchemeRawValue: String = GameSettings.ColorSchemePreference.dark.rawValue,
        lastUpdated: Date = Date()
    ) {
        self.autoErrorChecking = autoErrorChecking
        self.mistakeLimit = mistakeLimit
        self.hapticFeedback = hapticFeedback
        self.soundEffects = soundEffects
        self.highlightSameNumbers = highlightSameNumbers
        self.completedDailyChallenges = completedDailyChallenges
        self.themeTypeRawValue = themeTypeRawValue
        self.preferredColorSchemeRawValue = preferredColorSchemeRawValue
        self.lastUpdated = lastUpdated
    }
}
