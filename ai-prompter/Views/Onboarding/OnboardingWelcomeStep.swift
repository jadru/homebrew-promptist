import SwiftUI

// MARK: - Onboarding Welcome Step

struct OnboardingWelcomeStep: View {
    @EnvironmentObject private var onboardingManager: OnboardingManager
    @EnvironmentObject private var languageSettings: LanguageSettings

    var body: some View {
        VStack(spacing: DesignTokens.Spacing.xxl) {
            Spacer()

            // App Icon
            Image(nsImage: NSApp.applicationIconImage)
                .resizable()
                .scaledToFit()
                .frame(width: 96, height: 96)
                .shadow(
                    color: DesignTokens.Shadow.lg.color,
                    radius: DesignTokens.Shadow.lg.radius,
                    x: DesignTokens.Shadow.lg.x,
                    y: DesignTokens.Shadow.lg.y
                )

            // Title & Subtitle
            VStack(spacing: DesignTokens.Spacing.sm) {
                Text(languageSettings.localized("onboarding.welcome.title"))
                    .font(DesignTokens.Typography.display(28, weight: .bold))
                    .foregroundColor(DesignTokens.Colors.foregroundPrimary)

                Text(languageSettings.localized("onboarding.welcome.subtitle"))
                    .font(DesignTokens.Typography.body(15))
                    .foregroundColor(DesignTokens.Colors.foregroundSecondary)
                    .multilineTextAlignment(.center)
            }

            Spacer()

            // Language Selector
            VStack(spacing: DesignTokens.Spacing.xs) {
                Text(languageSettings.localized("onboarding.welcome.language"))
                    .font(DesignTokens.Typography.caption())
                    .foregroundColor(DesignTokens.Colors.foregroundTertiary)

                LanguageSegmentedControl()
            }

            // Get Started Button
            ActionButton(
                languageSettings.localized("onboarding.welcome.get_started"),
                variant: .primary
            ) {
                onboardingManager.nextStep()
            }
            .frame(width: 200)

            Spacer()
                .frame(height: DesignTokens.Spacing.lg)
        }
        .padding(.horizontal, DesignTokens.Spacing.xxxl)
    }
}

// MARK: - Language Segmented Control

private struct LanguageSegmentedControl: View {
    @EnvironmentObject private var languageSettings: LanguageSettings

    var body: some View {
        Picker("", selection: $languageSettings.selectedLanguage) {
            ForEach(AppLanguage.allCases) { language in
                Text(language.localizedLabel(using: languageSettings.bundle))
                    .tag(language)
            }
        }
        .pickerStyle(.segmented)
        .frame(width: 280)
    }
}

// MARK: - Preview

#Preview {
    OnboardingWelcomeStep()
        .frame(width: 520, height: 480)
        .background(DesignTokens.Colors.backgroundElevated)
        .environmentObject(OnboardingManager())
        .environmentObject(LanguageSettings())
}
