import SwiftUI

/// Settings surface that follows the shared design system so it can live alongside other
/// Promptist Manager tools.
struct SettingsView: View {
    @EnvironmentObject private var languageSettings: LanguageSettings
    @StateObject private var launchAtLoginManager = LaunchAtLoginManager.shared
    @StateObject private var launcherSettings = LauncherSettings.shared
    @StateObject private var appearanceSettings = AppearanceSettings.shared

    private let supportedLanguages = AppLanguage.allCases

    var body: some View {
        VStack(spacing: 0) {
            header

            Separator()

            ScrollView {
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.xl) {
                    appearanceSection
                    languageSection
                    launchAtLoginSection
                    launcherSection
                }
                .frame(maxWidth: DesignTokens.Layout.contentWidthNarrow, alignment: .leading)
                .padding(DesignTokens.Spacing.lg)
            }
        }
        .frame(minWidth: 520)
        .background(DesignTokens.Colors.backgroundPrimary)
        .withAppearance(appearanceSettings)
    }

    private var header: some View {
        HStack {
            Text(languageSettings.localized("settings.title"))
                .font(DesignTokens.Typography.headline(18))
                .foregroundColor(DesignTokens.Colors.foregroundPrimary)

            Spacer()
        }
        .padding(DesignTokens.Spacing.md)
        .background(DesignTokens.Colors.backgroundElevated)
    }

    // MARK: - Appearance Section

    private var appearanceSection: some View {
        CardBackground(padding: DesignTokens.Layout.edgeInsetComfortable, elevation: .sm) {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                    Text(languageSettings.localized("settings.appearance.title"))
                        .font(DesignTokens.Typography.headline())
                        .foregroundColor(DesignTokens.Colors.foregroundPrimary)

                    Text(languageSettings.localized("settings.appearance.subtitle"))
                        .font(DesignTokens.Typography.body())
                        .foregroundColor(DesignTokens.Colors.foregroundSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                AppearanceModeSelector(
                    modes: AppearanceMode.allCases,
                    selectedMode: $appearanceSettings.mode,
                    bundle: languageSettings.bundle
                )
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var languageSection: some View {
        CardBackground(padding: DesignTokens.Layout.edgeInsetComfortable, elevation: .sm) {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                    Text(languageSettings.localized("settings.language.title"))
                        .font(DesignTokens.Typography.headline())
                        .foregroundColor(DesignTokens.Colors.foregroundPrimary)

                    Text(languageSettings.localized("settings.language.subtitle"))
                        .font(DesignTokens.Typography.body())
                        .foregroundColor(DesignTokens.Colors.foregroundSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                LanguageSegmentedControl(
                    languages: supportedLanguages,
                    selectedLanguage: $languageSettings.selectedLanguage,
                    bundle: languageSettings.bundle
                )
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var launchAtLoginSection: some View {
        CardBackground(padding: DesignTokens.Layout.edgeInsetComfortable, elevation: .sm) {
            HStack(alignment: .top, spacing: DesignTokens.Spacing.md) {
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                    Text(languageSettings.localized("settings.launchAtLogin.title"))
                        .font(DesignTokens.Typography.headline())
                        .foregroundColor(DesignTokens.Colors.foregroundPrimary)

                    Text(languageSettings.localized("settings.launchAtLogin.subtitle"))
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

    private var launcherSection: some View {
        CardBackground(padding: DesignTokens.Layout.edgeInsetComfortable, elevation: .sm) {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
                Text(languageSettings.localized("settings.launcher.title"))
                    .font(DesignTokens.Typography.headline())
                    .foregroundColor(DesignTokens.Colors.foregroundPrimary)

                Divider()

                // Auto sort by usage
                settingsToggleRow(
                    title: languageSettings.localized("settings.launcher.autoSort"),
                    isOn: $launcherSettings.autoSortByUsage
                )

                Divider()

                // Show recent section
                settingsToggleRow(
                    title: languageSettings.localized("settings.launcher.showRecent"),
                    isOn: $launcherSettings.showRecentSection
                )

                // Recent count stepper (only when showRecent is on)
                if launcherSettings.showRecentSection {
                    HStack {
                        Text(languageSettings.localized("settings.launcher.recentCount"))
                            .font(DesignTokens.Typography.body())
                            .foregroundColor(DesignTokens.Colors.foregroundSecondary)
                        Spacer()
                        Stepper(
                            "\(launcherSettings.recentSectionCount)",
                            value: $launcherSettings.recentSectionCount,
                            in: 1...10
                        )
                        .labelsHidden()
                        Text("\(launcherSettings.recentSectionCount)")
                            .font(DesignTokens.Typography.body())
                            .foregroundColor(DesignTokens.Colors.foregroundPrimary)
                            .frame(width: 20)
                    }
                    .padding(.leading, DesignTokens.Spacing.lg)
                }

                Divider()

                // Show frequent section
                settingsToggleRow(
                    title: languageSettings.localized("settings.launcher.showFrequent"),
                    isOn: $launcherSettings.showFrequentSection
                )
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func settingsToggleRow(title: String, isOn: Binding<Bool>) -> some View {
        HStack {
            Text(title)
                .font(DesignTokens.Typography.body())
                .foregroundColor(DesignTokens.Colors.foregroundPrimary)
            Spacer()
            Toggle("", isOn: isOn)
                .labelsHidden()
                .toggleStyle(.switch)
        }
    }
}

// MARK: - Appearance Mode Selector

private struct AppearanceModeSelector: View {
    let modes: [AppearanceMode]
    @Binding var selectedMode: AppearanceMode
    let bundle: Bundle

    @State private var hoveredMode: AppearanceMode?

    var body: some View {
        HStack(spacing: DesignTokens.Spacing.sm) {
            ForEach(modes) { mode in
                modeButton(for: mode)
            }
        }
    }

    private func modeButton(for mode: AppearanceMode) -> some View {
        let isSelected = selectedMode == mode
        let isHovering = hoveredMode == mode

        return Button {
            withAnimation(DesignTokens.Animation.normal) {
                selectedMode = mode
            }
        } label: {
            VStack(spacing: DesignTokens.Spacing.xs) {
                Image(systemName: mode.icon)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(
                        isSelected
                            ? DesignTokens.Colors.accentPrimary
                            : DesignTokens.Colors.foregroundSecondary
                    )

                Text(mode.localizedLabel(using: bundle))
                    .font(DesignTokens.Typography.label(weight: .medium))
                    .foregroundColor(
                        isSelected
                            ? DesignTokens.Colors.foregroundPrimary
                            : DesignTokens.Colors.foregroundSecondary
                    )
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, DesignTokens.Spacing.md)
            .padding(.horizontal, DesignTokens.Spacing.sm)
            .background(
                RoundedRectangle(cornerRadius: DesignTokens.Radius.md, style: .continuous)
                    .fill(
                        isSelected
                            ? DesignTokens.Colors.selectedBackground
                            : (isHovering ? DesignTokens.Colors.hoverBackground : DesignTokens.Colors.backgroundTertiary)
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: DesignTokens.Radius.md, style: .continuous)
                    .stroke(
                        isSelected
                            ? DesignTokens.Colors.selectedBorder
                            : (isHovering ? DesignTokens.Colors.borderDefault : Color.clear),
                        lineWidth: isSelected ? 1.5 : 1
                    )
            )
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            withAnimation(DesignTokens.Animation.fast) {
                if hovering {
                    hoveredMode = mode
                } else if hoveredMode == mode {
                    hoveredMode = nil
                }
            }
        }
    }
}

// MARK: - Language Control

private struct LanguageSegmentedControl: View {
    let languages: [AppLanguage]
    @Binding var selectedLanguage: AppLanguage
    let bundle: Bundle

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
                .fill(DesignTokens.Colors.backgroundTertiary)
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
            Text(language.localizedLabel(using: bundle))
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
