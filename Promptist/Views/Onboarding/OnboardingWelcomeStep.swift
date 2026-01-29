import SwiftUI

// MARK: - Onboarding Welcome Step

struct OnboardingWelcomeStep: View {
    @EnvironmentObject private var onboardingManager: OnboardingManager
    @EnvironmentObject private var languageSettings: LanguageSettings

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            Image(nsImage: NSApp.applicationIconImage)
                .resizable()
                .scaledToFit()
                .frame(width: 96, height: 96)

            VStack(spacing: 8) {
                Text(languageSettings.localized("onboarding.welcome.title"))
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(.primary)

                Text(languageSettings.localized("onboarding.welcome.subtitle"))
                    .font(.system(size: 15))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            Spacer()

            VStack(spacing: 4) {
                Text(languageSettings.localized("onboarding.welcome.language"))
                    .font(.caption)
                    .foregroundStyle(.tertiary)

                LanguageSegmentedControl()
            }

            ActionButton(
                languageSettings.localized("onboarding.welcome.get_started"),
                variant: .primary
            ) {
                onboardingManager.nextStep()
            }
            .frame(width: 200)

            Spacer()
                .frame(height: 20)
        }
        .padding(.horizontal, 48)
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
        .background(Color(nsColor: .windowBackgroundColor))
        .environmentObject(OnboardingManager())
        .environmentObject(LanguageSettings())
}
