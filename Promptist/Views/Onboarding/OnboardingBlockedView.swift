import SwiftUI

// MARK: - Onboarding Blocked View

/// Displayed in MenuBarExtra and Manager window when onboarding is not completed
struct OnboardingBlockedView: View {
    @EnvironmentObject private var languageSettings: LanguageSettings
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "gearshape.circle")
                .font(.system(size: 40))
                .foregroundStyle(.tertiary)

            VStack(spacing: 4) {
                Text(languageSettings.localized("onboarding.blocked.title"))
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.primary)

                Text(languageSettings.localized("onboarding.blocked.description"))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            ActionButton(
                languageSettings.localized("onboarding.blocked.button"),
                variant: .primary
            ) {
                openOnboardingWindow()
            }
        }
        .padding(24)
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
        VStack(spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 14))
                    .foregroundStyle(.orange)

                Text(languageSettings.localized("onboarding.blocked.title"))
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.primary)
            }

            Text(languageSettings.localized("onboarding.blocked.description"))
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Button(action: openOnboardingWindow) {
                Text(languageSettings.localized("onboarding.blocked.button"))
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .fill(Color.accentColor)
                    )
            }
            .buttonStyle(.plain)
        }
        .padding(20)
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
        .background(Color(nsColor: .windowBackgroundColor))
        .environmentObject(LanguageSettings())
}

#Preview("Compact Blocked View") {
    OnboardingBlockedCompactView()
        .background(Color(nsColor: .windowBackgroundColor))
        .environmentObject(LanguageSettings())
}
