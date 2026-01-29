import SwiftUI

// MARK: - Onboarding Blocked View

/// Displayed in MenuBarExtra and Manager window when onboarding is not completed
struct OnboardingBlockedView: View {
    @EnvironmentObject private var languageSettings: LanguageSettings
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        VStack(spacing: DesignTokens.Spacing.lg) {
            // Icon
            Image(systemName: "gearshape.circle")
                .font(.system(size: 40))
                .foregroundColor(DesignTokens.Colors.foregroundTertiary)

            // Title & Description
            VStack(spacing: DesignTokens.Spacing.xs) {
                Text(languageSettings.localized("onboarding.blocked.title"))
                    .font(DesignTokens.Typography.headline(16, weight: .semibold))
                    .foregroundColor(DesignTokens.Colors.foregroundPrimary)

                Text(languageSettings.localized("onboarding.blocked.description"))
                    .font(DesignTokens.Typography.caption())
                    .foregroundColor(DesignTokens.Colors.foregroundSecondary)
                    .multilineTextAlignment(.center)
            }

            // Setup Button
            ActionButton(
                languageSettings.localized("onboarding.blocked.button"),
                variant: .primary
            ) {
                openOnboardingWindow()
            }
        }
        .padding(DesignTokens.Spacing.xl)
        .frame(width: 280)
        .environment(\.locale, languageSettings.locale)
    }

    private func openOnboardingWindow() {
        openWindow(id: "onboarding")
        NSApp.activate(ignoringOtherApps: true)
    }
}

// MARK: - Compact Blocked View (for menu bar)

struct OnboardingBlockedCompactView: View {
    @EnvironmentObject private var languageSettings: LanguageSettings
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        VStack(spacing: DesignTokens.Spacing.md) {
            HStack(spacing: DesignTokens.Spacing.sm) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: DesignTokens.IconSize.sm))
                    .foregroundColor(DesignTokens.Colors.warning)

                Text(languageSettings.localized("onboarding.blocked.title"))
                    .font(DesignTokens.Typography.label(weight: .medium))
                    .foregroundColor(DesignTokens.Colors.foregroundPrimary)
            }

            Text(languageSettings.localized("onboarding.blocked.description"))
                .font(DesignTokens.Typography.caption())
                .foregroundColor(DesignTokens.Colors.foregroundSecondary)
                .multilineTextAlignment(.center)

            Button(action: openOnboardingWindow) {
                Text(languageSettings.localized("onboarding.blocked.button"))
                    .font(DesignTokens.Typography.label(weight: .medium))
                    .foregroundColor(.white)
                    .padding(.horizontal, DesignTokens.Spacing.md)
                    .padding(.vertical, DesignTokens.Spacing.sm)
                    .background(
                        RoundedRectangle(cornerRadius: DesignTokens.Radius.sm, style: .continuous)
                            .fill(DesignTokens.Colors.accentPrimary)
                    )
            }
            .buttonStyle(.plain)
        }
        .padding(DesignTokens.Spacing.lg)
        .frame(width: 260)
        .environment(\.locale, languageSettings.locale)
    }

    private func openOnboardingWindow() {
        openWindow(id: "onboarding")
        NSApp.activate(ignoringOtherApps: true)
    }
}

// MARK: - Preview

#Preview("Blocked View") {
    OnboardingBlockedView()
        .background(DesignTokens.Colors.backgroundElevated)
        .environmentObject(LanguageSettings())
}

#Preview("Compact Blocked View") {
    OnboardingBlockedCompactView()
        .background(DesignTokens.Colors.backgroundElevated)
        .environmentObject(LanguageSettings())
}
