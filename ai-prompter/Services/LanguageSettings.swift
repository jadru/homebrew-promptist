import SwiftUI
import Combine

/// Controls the UI language for the app, allowing a system-default option or manual overrides.
@MainActor
final class LanguageSettings: ObservableObject {
    private enum Keys {
        static let selection = "LanguageSettings.selectedLanguage"
    }

    @Published var selectedLanguage: AppLanguage {
        didSet {
            userDefaults.set(selectedLanguage.rawValue, forKey: Keys.selection)
        }
    }

    private let userDefaults: UserDefaults

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
        let storedValue = userDefaults.string(forKey: Keys.selection)
        selectedLanguage = AppLanguage(rawValue: storedValue ?? "") ?? .system
    }

    var locale: Locale {
        selectedLanguage.locale ?? .autoupdatingCurrent
    }
}

enum AppLanguage: String, CaseIterable, Identifiable {
    case system
    case english
    case korean

    var id: String { rawValue }

    var locale: Locale? {
        switch self {
        case .system:
            return nil
        case .english:
            return Locale(identifier: "en")
        case .korean:
            return Locale(identifier: "ko")
        }
    }

    var labelKey: LocalizedStringKey {
        switch self {
        case .system:
            return "settings.language.option.system"
        case .english:
            return "settings.language.option.english"
        case .korean:
            return "settings.language.option.korean"
        }
    }
}
