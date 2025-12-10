import SwiftUI
import Combine

/// Controls launcher display settings including sorting and sections.
@MainActor
final class LauncherSettings: ObservableObject {
    static let shared = LauncherSettings()

    private enum Keys {
        static let autoSortByUsage = "LauncherSettings.autoSortByUsage"
        static let showRecentSection = "LauncherSettings.showRecentSection"
        static let showFrequentSection = "LauncherSettings.showFrequentSection"
        static let recentSectionCount = "LauncherSettings.recentSectionCount"
    }

    private enum Defaults {
        static let autoSortByUsage = true
        static let showRecentSection = true
        static let showFrequentSection = true
        static let recentSectionCount = 5
    }

    @Published var autoSortByUsage: Bool {
        didSet {
            userDefaults.set(autoSortByUsage, forKey: Keys.autoSortByUsage)
        }
    }

    @Published var showRecentSection: Bool {
        didSet {
            userDefaults.set(showRecentSection, forKey: Keys.showRecentSection)
        }
    }

    @Published var showFrequentSection: Bool {
        didSet {
            userDefaults.set(showFrequentSection, forKey: Keys.showFrequentSection)
        }
    }

    @Published var recentSectionCount: Int {
        didSet {
            userDefaults.set(recentSectionCount, forKey: Keys.recentSectionCount)
        }
    }

    private let userDefaults: UserDefaults

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults

        // Load stored values or use defaults
        // Note: UserDefaults returns false/0 for missing keys, so we check if key exists
        if userDefaults.object(forKey: Keys.autoSortByUsage) != nil {
            self.autoSortByUsage = userDefaults.bool(forKey: Keys.autoSortByUsage)
        } else {
            self.autoSortByUsage = Defaults.autoSortByUsage
        }

        if userDefaults.object(forKey: Keys.showRecentSection) != nil {
            self.showRecentSection = userDefaults.bool(forKey: Keys.showRecentSection)
        } else {
            self.showRecentSection = Defaults.showRecentSection
        }

        if userDefaults.object(forKey: Keys.showFrequentSection) != nil {
            self.showFrequentSection = userDefaults.bool(forKey: Keys.showFrequentSection)
        } else {
            self.showFrequentSection = Defaults.showFrequentSection
        }

        let storedCount = userDefaults.integer(forKey: Keys.recentSectionCount)
        if storedCount > 0 {
            self.recentSectionCount = storedCount
        } else {
            self.recentSectionCount = Defaults.recentSectionCount
        }
    }
}
