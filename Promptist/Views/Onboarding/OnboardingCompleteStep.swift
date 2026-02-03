import SwiftUI

// MARK: - Onboarding Complete Step

struct OnboardingCompleteStep: View {
    @EnvironmentObject private var onboardingManager: OnboardingManager
    @EnvironmentObject private var languageSettings: LanguageSettings

    @State private var showCheckmark = false

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            ZStack {
                Group {
                    if #available(macOS 26.0, *) {
                        Circle()
                            .fill(.clear)
                            .frame(width: 96, height: 96)
                            .glassEffect(.regular.tint(.green), in: Circle())
                    } else {
                        Circle()
                            .fill(Color.green.opacity(0.1))
                            .frame(width: 96, height: 96)
                    }
                }

                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 56))
                    .foregroundStyle(.green)
                    .scaleEffect(showCheckmark ? 1.0 : 0.5)
                    .opacity(showCheckmark ? 1.0 : 0.0)
            }
            .onAppear {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
                    showCheckmark = true
                }
            }

            VStack(spacing: 8) {
                Text(languageSettings.localized("onboarding.complete.title"))
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(.primary)

                Text(languageSettings.localized("onboarding.complete.subtitle"))
                    .font(.system(size: 15))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            TipCard()
                .padding(.horizontal, 24)

            Spacer()

            ActionButton(
                languageSettings.localized("onboarding.complete.start"),
                variant: .primary
            ) {
                onboardingManager.completeOnboarding()
            }
            .frame(width: 240)

            Spacer()
                .frame(height: 24)
        }
        .padding(.horizontal, 24)
    }
}

// MARK: - Tip Card

private struct TipCard: View {
    @EnvironmentObject private var languageSettings: LanguageSettings

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "lightbulb.fill")
                .font(.system(size: 16))
                .foregroundStyle(.orange)

            Text(languageSettings.localized("onboarding.complete.tip"))
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            Spacer()
        }
        .padding(12)
        .background {
            if #available(macOS 26.0, *) {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(.clear)
                    .glassEffect(.regular.tint(.orange), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            } else {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(Color.orange.opacity(0.08))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .stroke(Color.orange.opacity(0.2), lineWidth: 1)
                    )
            }
        }
    }
}

// MARK: - Preview

#Preview {
    OnboardingCompleteStep()
        .frame(width: 520, height: 480)
        .background(Color(nsColor: .windowBackgroundColor))
        .environmentObject(OnboardingManager())
        .environmentObject(LanguageSettings())
}
