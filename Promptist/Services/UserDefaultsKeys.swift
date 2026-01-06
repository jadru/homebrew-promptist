//
//  UserDefaultsKeys.swift
//  Promptist
//
//  Centralized UserDefaults keys to prevent string duplication and typos.
//

import Foundation

/// Centralized storage for all UserDefaults keys used throughout the app.
/// This prevents string duplication and makes it easy to find all persisted settings.
enum UserDefaultsKeys {
    // MARK: - Language Settings
    static let selectedLanguage = "LanguageSettings.selectedLanguage"

    // MARK: - Repository Migration
    static let v2MigrationComplete = "PromptTemplateRepository.v2MigrationComplete"

    // MARK: - Onboarding
    static let hasCompletedOnboarding = "OnboardingManager.hasCompletedOnboarding"

    // MARK: - Search History
    static let recentSearches = "PromptListViewModel.recentSearches"

    // MARK: - Appearance
    static let appearanceMode = "AppearanceSettings.mode"
    static let accentColor = "AppearanceSettings.accentColor"

    // MARK: - Launcher Settings
    static let showPreviewPanel = "LauncherSettings.showPreviewPanel"
    static let maxVisiblePrompts = "LauncherSettings.maxVisiblePrompts"

    // MARK: - Launch at Login
    static let launchAtLogin = "LaunchAtLoginManager.enabled"
}

// MARK: - UserDefaults Extension

extension UserDefaults {
    /// Type-safe getter for string values
    func string(for key: String) -> String? {
        string(forKey: key)
    }

    /// Type-safe getter for bool values with default
    func bool(for key: String, default defaultValue: Bool = false) -> Bool {
        object(forKey: key) != nil ? bool(forKey: key) : defaultValue
    }

    /// Type-safe getter for integer values with default
    func integer(for key: String, default defaultValue: Int = 0) -> Int {
        object(forKey: key) != nil ? integer(forKey: key) : defaultValue
    }

    /// Type-safe setter
    func set(_ value: Any?, for key: String) {
        set(value, forKey: key)
    }
}
