import SwiftUI

// MARK: - Onboarding Features Step

struct OnboardingFeaturesStep: View {
    @EnvironmentObject private var onboardingManager: OnboardingManager
    @EnvironmentObject private var languageSettings: LanguageSettings

    private let features: [Feature] = [
        Feature(
            icon: "doc.on.clipboard",
            titleKey: "onboarding.features.clipboard.title",
            descriptionKey: "onboarding.features.clipboard.description"
        ),
        Feature(
            icon: "app.badge",
            titleKey: "onboarding.features.apps.title",
            descriptionKey: "onboarding.features.apps.description"
        ),
        Feature(
            icon: "keyboard",
            titleKey: "onboarding.features.shortcuts.title",
            descriptionKey: "onboarding.features.shortcuts.description"
        ),
        Feature(
            icon: "menubar.rectangle",
            titleKey: "onboarding.features.menubar.title",
            descriptionKey: "onboarding.features.menubar.description"
        )
    ]

    var body: some View {
        VStack(spacing: 24) {
            Text(languageSettings.localized("onboarding.features.title"))
                .font(.system(size: 24, weight: .bold))
                .foregroundStyle(.primary)
                .padding(.top, 24)

            VStack(spacing: 12) {
                ForEach(features) { feature in
                    FeatureCard(feature: feature)
                }
            }
            .padding(.horizontal, 20)

            Spacer()

            ActionButton(
                languageSettings.localized("onboarding.features.continue"),
                variant: .primary
            ) {
                onboardingManager.nextStep()
            }
            .frame(width: 200)

            Spacer()
                .frame(height: 20)
        }
        .padding(.horizontal, 20)
    }
}

// MARK: - Feature Model

private struct Feature: Identifiable {
    let id = UUID()
    let icon: String
    let titleKey: String
    let descriptionKey: String
}

// MARK: - Feature Card

private struct FeatureCard: View {
    let feature: Feature
    @EnvironmentObject private var languageSettings: LanguageSettings

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: feature.icon)
                .font(.system(size: 20))
                .foregroundStyle(.accent)
                .glassCircleBackground(size: 40, tint: .accentColor)

            VStack(alignment: .leading, spacing: 2) {
                Text(languageSettings.localized(feature.titleKey))
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.primary)

                Text(languageSettings.localized(feature.descriptionKey))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            Spacer()
        }
        .padding(12)
        .background {
            if #available(macOS 26.0, *) {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(.clear)
                    .glassEffect(.clear, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            } else {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(.quaternary)
            }
        }
    }
}

// MARK: - Preview

#Preview {
    OnboardingFeaturesStep()
        .frame(width: 520, height: 480)
        .background(Color(nsColor: .windowBackgroundColor))
        .environmentObject(OnboardingManager())
        .environmentObject(LanguageSettings())
}
