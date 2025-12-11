//
//  AppearanceSettings.swift
//  Promptist
//
//  Manages app appearance (light/dark mode) with system preference support.
//

import SwiftUI
import AppKit
import Combine

// MARK: - Appearance Mode

enum AppearanceMode: String, CaseIterable, Identifiable, Codable {
    case system
    case light
    case dark

    var id: String { rawValue }

    func localizedLabel(using bundle: Bundle) -> String {
        let key: String
        switch self {
        case .system: key = "settings.appearance.option.system"
        case .light: key = "settings.appearance.option.light"
        case .dark: key = "settings.appearance.option.dark"
        }
        return NSLocalizedString(key, bundle: bundle, comment: "")
    }

    var icon: String {
        switch self {
        case .system: return "circle.lefthalf.filled"
        case .light: return "sun.max.fill"
        case .dark: return "moon.fill"
        }
    }
}

// MARK: - Appearance Settings

@MainActor
final class AppearanceSettings: ObservableObject {
    static let shared = AppearanceSettings()

    private static let appearanceModeKey = "AppearanceSettings.mode"

    @Published var mode: AppearanceMode {
        didSet {
            UserDefaults.standard.set(mode.rawValue, forKey: Self.appearanceModeKey)
            applyAppearance()
        }
    }

    /// Returns the effective color scheme based on current mode
    @Published private(set) var effectiveColorScheme: ColorScheme

    /// Whether we're currently in dark mode (either system or manual)
    var isDarkMode: Bool {
        effectiveColorScheme == .dark
    }

    private var systemAppearanceObserver: NSObjectProtocol?

    private init() {
        // Load saved preference
        let savedMode: AppearanceMode
        if let modeString = UserDefaults.standard.string(forKey: Self.appearanceModeKey),
           let mode = AppearanceMode(rawValue: modeString) {
            savedMode = mode
        } else {
            savedMode = .system
        }

        // Initialize all stored properties first
        self.mode = savedMode
        self.effectiveColorScheme = Self.resolveColorScheme(for: savedMode)

        // Observe system appearance changes
        setupSystemAppearanceObserver()
    }

    deinit {
        if let observer = systemAppearanceObserver {
            DistributedNotificationCenter.default().removeObserver(observer)
        }
    }

    private func setupSystemAppearanceObserver() {
        systemAppearanceObserver = DistributedNotificationCenter.default().addObserver(
            forName: NSNotification.Name("AppleInterfaceThemeChangedNotification"),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.updateEffectiveColorScheme()
            }
        }
    }

    private func applyAppearance() {
        updateEffectiveColorScheme()

        // Apply to all windows
        for window in NSApplication.shared.windows {
            switch mode {
            case .system:
                window.appearance = nil
            case .light:
                window.appearance = NSAppearance(named: .aqua)
            case .dark:
                window.appearance = NSAppearance(named: .darkAqua)
            }
        }
    }

    private func updateEffectiveColorScheme() {
        effectiveColorScheme = Self.resolveColorScheme(for: mode)
    }

    private static func resolveColorScheme(for mode: AppearanceMode) -> ColorScheme {
        switch mode {
        case .system:
            let systemAppearance = NSApplication.shared.effectiveAppearance
            return systemAppearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua ? .dark : .light
        case .light:
            return .light
        case .dark:
            return .dark
        }
    }

    /// Call this when a new window is created to apply the current appearance
    func applyToWindow(_ window: NSWindow) {
        switch mode {
        case .system:
            window.appearance = nil
        case .light:
            window.appearance = NSAppearance(named: .aqua)
        case .dark:
            window.appearance = NSAppearance(named: .darkAqua)
        }
    }
}

// MARK: - View Modifier for Appearance

struct AppearanceModifier: ViewModifier {
    @ObservedObject var settings: AppearanceSettings

    func body(content: Content) -> some View {
        content
            .preferredColorScheme(colorScheme)
    }

    private var colorScheme: ColorScheme? {
        switch settings.mode {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}

extension View {
    func withAppearance(_ settings: AppearanceSettings) -> some View {
        modifier(AppearanceModifier(settings: settings))
    }
}
