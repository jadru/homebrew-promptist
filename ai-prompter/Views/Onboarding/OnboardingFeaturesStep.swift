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
        VStack(spacing: DesignTokens.Spacing.xl) {
            // Title
            Text(languageSettings.localized("onboarding.features.title"))
                .font(DesignTokens.Typography.display(24, weight: .bold))
                .foregroundColor(DesignTokens.Colors.foregroundPrimary)
                .padding(.top, DesignTokens.Spacing.xl)

            // Feature Cards
            VStack(spacing: DesignTokens.Spacing.md) {
                ForEach(features) { feature in
                    FeatureCard(feature: feature)
                }
            }
            .padding(.horizontal, DesignTokens.Spacing.lg)

            Spacer()

            // Continue Button
            ActionButton(
                languageSettings.localized("onboarding.features.continue"),
                variant: .primary
            ) {
                onboardingManager.nextStep()
            }
            .frame(width: 200)

            Spacer()
                .frame(height: DesignTokens.Spacing.lg)
        }
        .padding(.horizontal, DesignTokens.Spacing.lg)
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
        HStack(spacing: DesignTokens.Spacing.md) {
            // Icon
            Image(systemName: feature.icon)
                .font(.system(size: DesignTokens.IconSize.lg))
                .foregroundColor(DesignTokens.Colors.accentPrimary)
                .frame(width: 40, height: 40)
                .background(
                    RoundedRectangle(cornerRadius: DesignTokens.Radius.md, style: .continuous)
                        .fill(DesignTokens.Colors.accentPrimary.opacity(0.1))
                )

            // Text
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.xxs) {
                Text(languageSettings.localized(feature.titleKey))
                    .font(DesignTokens.Typography.label(weight: .semibold))
                    .foregroundColor(DesignTokens.Colors.foregroundPrimary)

                Text(languageSettings.localized(feature.descriptionKey))
                    .font(DesignTokens.Typography.caption())
                    .foregroundColor(DesignTokens.Colors.foregroundSecondary)
                    .lineLimit(2)
            }

            Spacer()
        }
        .padding(DesignTokens.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: DesignTokens.Radius.md, style: .continuous)
                .fill(DesignTokens.Colors.backgroundSecondary)
        )
    }
}

// MARK: - Preview

#Preview {
    OnboardingFeaturesStep()
        .frame(width: 520, height: 480)
        .background(DesignTokens.Colors.backgroundElevated)
        .environmentObject(OnboardingManager())
        .environmentObject(LanguageSettings())
}
