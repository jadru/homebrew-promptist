import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var languageSettings: LanguageSettings
    @StateObject private var launchAtLoginManager = LaunchAtLoginManager.shared
    @StateObject private var launcherSettings = LauncherSettings.shared
    @StateObject private var appearanceSettings = AppearanceSettings.shared

    var body: some View {
        Form {
            // Appearance
            Section(languageSettings.localized("settings.appearance.title")) {
                Picker(languageSettings.localized("settings.appearance.mode"), selection: $appearanceSettings.mode) {
                    ForEach(AppearanceMode.allCases) { mode in
                        Label(mode.localizedLabel(using: languageSettings.bundle), systemImage: mode.icon)
                            .tag(mode)
                    }
                }
            }

            // Language
            Section(languageSettings.localized("settings.language.title")) {
                Picker(languageSettings.localized("settings.language.select"), selection: $languageSettings.selectedLanguage) {
                    ForEach(AppLanguage.allCases) { language in
                        Text(language.localizedLabel(using: languageSettings.bundle))
                            .tag(language)
                    }
                }
            }

            // General
            Section(languageSettings.localized("settings.general.title")) {
                Toggle(
                    languageSettings.localized("settings.launchAtLogin.title"),
                    isOn: $launchAtLoginManager.isEnabled
                )
            }

            // Launcher Behavior
            Section(languageSettings.localized("settings.launcher.title")) {
                Toggle(
                    languageSettings.localized("settings.launcher.autoSort"),
                    isOn: $launcherSettings.autoSortByUsage
                )

                Toggle(
                    languageSettings.localized("settings.launcher.showRecent"),
                    isOn: $launcherSettings.showRecentSection
                )

                if launcherSettings.showRecentSection {
                    Stepper(
                        value: $launcherSettings.recentSectionCount,
                        in: 1...10
                    ) {
                        HStack {
                            Text(languageSettings.localized("settings.launcher.recentCount"))
                            Spacer()
                            Text("\(launcherSettings.recentSectionCount)")
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                Toggle(
                    languageSettings.localized("settings.launcher.showFrequent"),
                    isOn: $launcherSettings.showFrequentSection
                )
            }

            // Quit
            Section {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(languageSettings.localized("settings.quit.title"))
                        Text(languageSettings.localized("settings.quit.subtitle"))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Button(languageSettings.localized("settings.quit.button"), role: .destructive) {
                        NSApplication.shared.terminate(nil)
                    }
                }
            }
        }
        .formStyle(.grouped)
        .withAppearance(appearanceSettings)
    }
}

#Preview {
    SettingsView()
        .environmentObject(LanguageSettings())
}
