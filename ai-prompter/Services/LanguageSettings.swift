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
            updateBundle()
        }
    }

    private let userDefaults: UserDefaults
    private(set) var bundle: Bundle = .main

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
        let storedValue = userDefaults.string(forKey: Keys.selection)
        selectedLanguage = AppLanguage(rawValue: storedValue ?? "") ?? .system
        updateBundle()
    }

    var locale: Locale {
        selectedLanguage.locale ?? .autoupdatingCurrent
    }

    private func updateBundle() {
        bundle = selectedLanguage.bundle
    }

    /// Helper function to get localized string with current language settings
    func localized(_ key: String) -> String {
        bundle.localizedString(forKey: key, value: nil, table: nil)
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

    /// Returns the appropriate bundle for this language
    var bundle: Bundle {
        let languageCode: String?
        switch self {
        case .system:
            languageCode = nil
        case .english:
            languageCode = "en"
        case .korean:
            languageCode = "ko"
        }

        guard let languageCode = languageCode,
              let path = Bundle.main.path(forResource: languageCode, ofType: "lproj"),
              let bundle = Bundle(path: path) else {
            return .main
        }
        return bundle
    }

    var localizationKey: String {
        switch self {
        case .system:
            return "settings.language.option.system"
        case .english:
            return "settings.language.option.english"
        case .korean:
            return "settings.language.option.korean"
        }
    }

    private var fallbackLabel: String {
        switch self {
        case .system:
            return "System default"
        case .english:
            return "English"
        case .korean:
            return "Korean"
        }
    }

    func localizedLabel(using bundle: Bundle) -> String {
        let localized = bundle.localizedString(forKey: localizationKey, value: nil, table: nil)
        // If the translation is missing return an English fallback value.
        return localized == localizationKey ? fallbackLabel : localized
    }
}
