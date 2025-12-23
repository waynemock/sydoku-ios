//
//  SettingsAdapter.swift
//  Sydoku
//
//  Created by Wayne Mock on 12/18/25.
//

import Foundation

/// Adapter to convert between SwiftData UserSettings model and GameSettings struct.
///
/// This adapter helps bridge the gap during migration, allowing existing code
/// to continue using `GameSettings` struct while persisting to SwiftData's
/// `UserSettings` model.
struct SettingsAdapter {
    
    /// Converts a SwiftData UserSettings model to a GameSettings struct.
    ///
    /// - Parameter model: The SwiftData model to convert.
    /// - Returns: A GameSettings struct with the same data.
    static func toStruct(from model: UserSettings) -> GameSettings {
        var settings = GameSettings()
        settings.autoErrorChecking = model.autoErrorChecking
        settings.mistakeLimit = model.mistakeLimit
        settings.hapticFeedback = model.hapticFeedback
        settings.soundEffects = model.soundEffects
        settings.highlightSameNumbers = model.highlightSameNumbers
        settings.completedDailyChallenges = model.completedDailyChallenges
        
        // Convert raw values back to enums
        if let themeType = Theme.ThemeType(rawValue: model.themeTypeRawValue) {
            settings.themeType = themeType
        }
        if let colorScheme = GameSettings.ColorSchemePreference(rawValue: model.preferredColorSchemeRawValue) {
            settings.preferredColorScheme = colorScheme
        }
        
        return settings
    }
    
    /// Updates a SwiftData UserSettings model with data from a GameSettings struct.
    ///
    /// - Parameters:
    ///   - model: The SwiftData model to update.
    ///   - settings: The GameSettings struct to copy data from.
    static func updateModel(_ model: UserSettings, from settings: GameSettings) {
        model.autoErrorChecking = settings.autoErrorChecking
        model.mistakeLimit = settings.mistakeLimit
        model.hapticFeedback = settings.hapticFeedback
        model.soundEffects = settings.soundEffects
        model.highlightSameNumbers = settings.highlightSameNumbers
        model.completedDailyChallenges = settings.completedDailyChallenges
        model.themeTypeRawValue = settings.themeType.rawValue
        model.preferredColorSchemeRawValue = settings.preferredColorScheme.rawValue
        model.lastUpdated = Date()
    }
}
