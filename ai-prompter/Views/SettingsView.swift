import SwiftUI

/// Settings surface that follows the shared design system so it can live alongside other
/// Promptist Manager tools.
struct SettingsView: View {
    @EnvironmentObject private var languageSettings: LanguageSettings
    @StateObject private var launchAtLoginManager = LaunchAtLoginManager.shared

    private let supportedLanguages = AppLanguage.allCases

    var body: some View {
        VStack(spacing: 0) {
            header

            Separator()

            ScrollView {
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.xl) {
                    languageSection
                    launchAtLoginSection
                }
                .frame(maxWidth: DesignTokens.Layout.contentWidthNarrow, alignment: .leading)
                .padding(DesignTokens.Spacing.lg)
            }
        }
        .frame(minWidth: 520)
        .background(DesignTokens.Colors.backgroundPrimary)
    }

    private var header: some View {
        HStack {
            Text(localized("settings.title", fallback: "Settings"))
                .font(DesignTokens.Typography.headline(18))
                .foregroundColor(DesignTokens.Colors.foregroundPrimary)

            Spacer()
        }
        .padding(DesignTokens.Spacing.md)
        .background(DesignTokens.Colors.backgroundElevated)
    }

    private var languageSection: some View {
        CardBackground(padding: DesignTokens.Layout.edgeInsetComfortable, elevation: .sm) {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                    Text(localized("settings.language.title", fallback: "Language"))
                        .font(DesignTokens.Typography.headline())
                        .foregroundColor(DesignTokens.Colors.foregroundPrimary)

                    Text(localized("settings.language.subtitle", fallback: "Choose which language to show in the app."))
                        .font(DesignTokens.Typography.body())
                        .foregroundColor(DesignTokens.Colors.foregroundSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                LanguageSegmentedControl(
                    languages: supportedLanguages,
                    selectedLanguage: $languageSettings.selectedLanguage,
                    locale: languageSettings.locale
                )
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var launchAtLoginSection: some View {
        CardBackground(padding: DesignTokens.Layout.edgeInsetComfortable, elevation: .sm) {
            HStack(alignment: .top, spacing: DesignTokens.Spacing.md) {
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                    Text(localized("settings.launchAtLogin.title", fallback: "Launch at Login"))
                        .font(DesignTokens.Typography.headline())
                        .foregroundColor(DesignTokens.Colors.foregroundPrimary)

                    Text(localized("settings.launchAtLogin.subtitle", fallback: "Automatically open the app when you log in to your Mac."))
                        .font(DesignTokens.Typography.body())
                        .foregroundColor(DesignTokens.Colors.foregroundSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer()

                Toggle("", isOn: $launchAtLoginManager.isEnabled)
                    .labelsHidden()
                    .toggleStyle(.switch)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func localized(_ key: String, fallback: String) -> String {
        let localizedValue = String(
            localized: String.LocalizationValue(key),
            locale: languageSettings.locale
        )
        return localizedValue == key ? fallback : localizedValue
    }
}

// MARK: - Language Control

private struct LanguageSegmentedControl: View {
    let languages: [AppLanguage]
    @Binding var selectedLanguage: AppLanguage
    let locale: Locale

    @State private var hoveredLanguage: AppLanguage?

    var body: some View {
        HStack(spacing: DesignTokens.Spacing.xxs) {
            ForEach(languages) { language in
                segmentButton(for: language)
            }
        }
        .padding(DesignTokens.Spacing.xxs)
        .background(
            RoundedRectangle(cornerRadius: DesignTokens.Radius.md, style: .continuous)
                .fill(DesignTokens.Colors.backgroundSecondary)
        )
    }

    private func segmentButton(for language: AppLanguage) -> some View {
        let isSelected = selectedLanguage == language
        let isHovering = hoveredLanguage == language

        return Button {
            withAnimation(DesignTokens.Animation.normal) {
                selectedLanguage = language
            }
        } label: {
            Text(language.localizedLabel(in: locale))
                .font(DesignTokens.Typography.label(weight: .medium))
                .foregroundColor(
                    isSelected
                        ? DesignTokens.Colors.foregroundPrimary
                        : DesignTokens.Colors.foregroundSecondary
                )
                .padding(.horizontal, DesignTokens.Spacing.md)
                .padding(.vertical, DesignTokens.Spacing.xs)
                .background(
                    RoundedRectangle(cornerRadius: DesignTokens.Radius.sm, style: .continuous)
                        .fill(
                            isSelected
                                ? DesignTokens.Colors.backgroundElevated
                                : (isHovering ? DesignTokens.Colors.hoverBackground : Color.clear)
                        )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: DesignTokens.Radius.sm, style: .continuous)
                        .stroke(
                            isSelected
                                ? DesignTokens.Colors.borderDefault
                                : (isHovering ? DesignTokens.Colors.borderDefault.opacity(0.7) : Color.clear),
                            lineWidth: isSelected ? 1 : 0.5
                        )
                )
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            if hovering {
                hoveredLanguage = language
            } else if hoveredLanguage == language {
                hoveredLanguage = nil
            }
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(LanguageSettings())
}
