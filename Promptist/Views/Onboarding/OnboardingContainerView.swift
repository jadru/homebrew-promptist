import SwiftUI

// MARK: - Onboarding Container View

struct OnboardingContainerView: View {
    @EnvironmentObject private var onboardingManager: OnboardingManager
    @EnvironmentObject private var languageSettings: LanguageSettings

    var body: some View {
        Group {
            if onboardingManager.hasCompletedOnboarding {
                // Show empty view and close window when onboarding is already completed
                Color.clear
                    .frame(width: 1, height: 1)
                    .onAppear {
                        closeOnboardingWindow()
                    }
            } else {
                VStack(spacing: 0) {
                    contentView
                        .frame(maxWidth: .infinity, maxHeight: .infinity)

                    if onboardingManager.currentStep != .complete {
                        OnboardingProgressIndicator(
                            currentStep: onboardingManager.currentStep.rawValue,
                            totalSteps: onboardingManager.totalSteps - 1
                        )
                        .padding(.bottom, 24)
                    }
                }
                .frame(width: 520, height: 480)
                .environment(\.locale, languageSettings.locale)
            }
        }
    }

    private func closeOnboardingWindow() {
        DispatchQueue.main.async {
            // Find and close the onboarding window by identifier only
            for window in NSApp.windows {
                if window.identifier?.rawValue == "onboarding" {
                    window.close()
                    break
                }
            }
        }
    }

    @ViewBuilder
    private var contentView: some View {
        switch onboardingManager.currentStep {
        case .welcome:
            OnboardingWelcomeStep()
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .leading).combined(with: .opacity)
                ))

        case .features:
            OnboardingFeaturesStep()
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .leading).combined(with: .opacity)
                ))

        case .permission:
            OnboardingPermissionStep()
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .leading).combined(with: .opacity)
                ))

        case .complete:
            OnboardingCompleteStep()
                .transition(.asymmetric(
                    insertion: .scale(scale: 0.9).combined(with: .opacity),
                    removal: .opacity
                ))
        }
    }
}

// MARK: - Progress Indicator

struct OnboardingProgressIndicator: View {
    let currentStep: Int
    let totalSteps: Int

    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<totalSteps, id: \.self) { index in
                Circle()
                    .fill(index <= currentStep
                        ? Color.accentColor
                        : Color.primary.opacity(0.15))
                    .frame(width: 8, height: 8)
                    .animation(.easeInOut(duration: 0.3), value: currentStep)
            }
        }
    }
}

// MARK: - Preview

#Preview {
    OnboardingContainerView()
        .environmentObject(OnboardingManager())
        .environmentObject(LanguageSettings())
}
