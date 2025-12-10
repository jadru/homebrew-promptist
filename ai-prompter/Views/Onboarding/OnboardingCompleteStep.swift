import SwiftUI

// MARK: - Onboarding Complete Step

struct OnboardingCompleteStep: View {
    @EnvironmentObject private var onboardingManager: OnboardingManager
    @EnvironmentObject private var languageSettings: LanguageSettings

    @State private var showCheckmark = false

    var body: some View {
        VStack(spacing: DesignTokens.Spacing.xxl) {
            Spacer()

            // Success Icon
            ZStack {
                Circle()
                    .fill(DesignTokens.Colors.success.opacity(0.1))
                    .frame(width: 96, height: 96)

                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 56))
                    .foregroundColor(DesignTokens.Colors.success)
                    .scaleEffect(showCheckmark ? 1.0 : 0.5)
                    .opacity(showCheckmark ? 1.0 : 0.0)
            }
            .onAppear {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
                    showCheckmark = true
                }
            }

            // Title & Subtitle
            VStack(spacing: DesignTokens.Spacing.sm) {
                Text(languageSettings.localized("onboarding.complete.title"))
                    .font(DesignTokens.Typography.display(28, weight: .bold))
                    .foregroundColor(DesignTokens.Colors.foregroundPrimary)

                Text(languageSettings.localized("onboarding.complete.subtitle"))
                    .font(DesignTokens.Typography.body(15))
                    .foregroundColor(DesignTokens.Colors.foregroundSecondary)
                    .multilineTextAlignment(.center)
            }

            // Tip Card
            TipCard()
                .padding(.horizontal, DesignTokens.Spacing.xl)

            Spacer()

            // Start Button
            ActionButton(
                languageSettings.localized("onboarding.complete.start"),
                variant: .primary
            ) {
                onboardingManager.completeOnboarding()
            }
            .frame(width: 240)

            Spacer()
                .frame(height: DesignTokens.Spacing.xl)
        }
        .padding(.horizontal, DesignTokens.Spacing.xl)
    }
}

// MARK: - Tip Card

private struct TipCard: View {
    @EnvironmentObject private var languageSettings: LanguageSettings

    var body: some View {
        HStack(spacing: DesignTokens.Spacing.md) {
            Image(systemName: "lightbulb.fill")
                .font(.system(size: DesignTokens.IconSize.md))
                .foregroundColor(DesignTokens.Colors.warning)

            Text(languageSettings.localized("onboarding.complete.tip"))
                .font(DesignTokens.Typography.caption())
                .foregroundColor(DesignTokens.Colors.foregroundSecondary)
                .fixedSize(horizontal: false, vertical: true)

            Spacer()
        }
        .padding(DesignTokens.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: DesignTokens.Radius.md, style: .continuous)
                .fill(DesignTokens.Colors.warning.opacity(0.08))
        )
        .overlay(
            RoundedRectangle(cornerRadius: DesignTokens.Radius.md, style: .continuous)
                .stroke(DesignTokens.Colors.warning.opacity(0.2), lineWidth: 1)
        )
    }
}

// MARK: - Preview

#Preview {
    OnboardingCompleteStep()
        .frame(width: 520, height: 480)
        .background(DesignTokens.Colors.backgroundElevated)
        .environmentObject(OnboardingManager())
        .environmentObject(LanguageSettings())
}
