import SwiftUI

// MARK: - Onboarding Permission Step

struct OnboardingPermissionStep: View {
    @EnvironmentObject private var onboardingManager: OnboardingManager
    @EnvironmentObject private var languageSettings: LanguageSettings

    @State private var showingInstructions = false

    private var permissionManager: AccessibilityPermissionManager {
        onboardingManager.permissionManagerInstance
    }

    var body: some View {
        VStack(spacing: DesignTokens.Spacing.xl) {
            Spacer()

            // Icon
            ZStack {
                Circle()
                    .fill(permissionManager.hasPermission
                        ? DesignTokens.Colors.success.opacity(0.1)
                        : DesignTokens.Colors.warning.opacity(0.1))
                    .frame(width: 88, height: 88)

                Image(systemName: permissionManager.hasPermission
                    ? "checkmark.shield.fill"
                    : "lock.shield")
                    .font(.system(size: 40))
                    .foregroundColor(permissionManager.hasPermission
                        ? DesignTokens.Colors.success
                        : DesignTokens.Colors.warning)
            }
            .animation(DesignTokens.Animation.normal, value: permissionManager.hasPermission)

            // Title & Subtitle
            VStack(spacing: DesignTokens.Spacing.sm) {
                Text(languageSettings.localized("onboarding.permission.title"))
                    .font(DesignTokens.Typography.display(24, weight: .bold))
                    .foregroundColor(DesignTokens.Colors.foregroundPrimary)

                Text(languageSettings.localized("onboarding.permission.subtitle"))
                    .font(DesignTokens.Typography.body(15))
                    .foregroundColor(DesignTokens.Colors.foregroundSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, DesignTokens.Spacing.xl)
            }

            // Permission Status
            PermissionStatusBadge(hasPermission: permissionManager.hasPermission)

            Spacer()

            // Instructions Toggle
            if !permissionManager.hasPermission {
                Button {
                    withAnimation(DesignTokens.Animation.normal) {
                        showingInstructions.toggle()
                    }
                } label: {
                    HStack(spacing: DesignTokens.Spacing.xs) {
                        Text(languageSettings.localized("onboarding.permission.show_instructions"))
                            .font(DesignTokens.Typography.caption())
                            .foregroundColor(DesignTokens.Colors.foregroundSecondary)

                        Image(systemName: showingInstructions ? "chevron.up" : "chevron.down")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(DesignTokens.Colors.foregroundTertiary)
                    }
                }
                .buttonStyle(.plain)

                if showingInstructions {
                    InstructionsList()
                        .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }

            Spacer()

            // Action Buttons
            VStack(spacing: DesignTokens.Spacing.sm) {
                if permissionManager.hasPermission {
                    ActionButton(
                        languageSettings.localized("onboarding.permission.continue"),
                        variant: .primary
                    ) {
                        onboardingManager.nextStep()
                    }
                    .frame(width: 200)
                } else {
                    ActionButton(
                        languageSettings.localized("onboarding.permission.open_settings"),
                        variant: .primary
                    ) {
                        permissionManager.openSystemSettings()
                    }
                    .frame(width: 220)

                    if permissionManager.isPolling {
                        HStack(spacing: DesignTokens.Spacing.xs) {
                            ProgressView()
                                .scaleEffect(0.7)

                            Text(languageSettings.localized("onboarding.permission.checking"))
                                .font(DesignTokens.Typography.caption())
                                .foregroundColor(DesignTokens.Colors.foregroundTertiary)
                        }
                    }

                    // Skip button for users who can't confirm permission status
                    Button {
                        // Skip directly completes onboarding (no need to show complete step)
                        onboardingManager.completeOnboarding()
                    } label: {
                        Text(languageSettings.localized("onboarding.permission.skip"))
                            .font(DesignTokens.Typography.caption())
                            .foregroundColor(DesignTokens.Colors.foregroundTertiary)
                    }
                    .buttonStyle(.plain)
                    .padding(.top, DesignTokens.Spacing.xs)
                }
            }

            Spacer()
                .frame(height: DesignTokens.Spacing.lg)
        }
        .padding(.horizontal, DesignTokens.Spacing.xl)
        .onAppear {
            permissionManager.startPollingForPermission()
        }
        .onDisappear {
            permissionManager.stopPolling()
        }
    }
}

// MARK: - Permission Status Badge

private struct PermissionStatusBadge: View {
    let hasPermission: Bool
    @EnvironmentObject private var languageSettings: LanguageSettings

    var body: some View {
        HStack(spacing: DesignTokens.Spacing.sm) {
            Circle()
                .fill(hasPermission ? DesignTokens.Colors.success : DesignTokens.Colors.warning)
                .frame(width: 8, height: 8)

            Text(hasPermission
                ? languageSettings.localized("onboarding.permission.status.granted")
                : languageSettings.localized("onboarding.permission.status.pending"))
                .font(DesignTokens.Typography.label(weight: .medium))
                .foregroundColor(hasPermission
                    ? DesignTokens.Colors.success
                    : DesignTokens.Colors.warning)
        }
        .padding(.horizontal, DesignTokens.Spacing.md)
        .padding(.vertical, DesignTokens.Spacing.sm)
        .background(
            RoundedRectangle(cornerRadius: DesignTokens.Radius.full, style: .continuous)
                .fill(hasPermission
                    ? DesignTokens.Colors.success.opacity(0.1)
                    : DesignTokens.Colors.warning.opacity(0.1))
        )
        .animation(DesignTokens.Animation.normal, value: hasPermission)
    }
}

// MARK: - Instructions List

private struct InstructionsList: View {
    @EnvironmentObject private var languageSettings: LanguageSettings

    private let steps: [(key: String, number: String)] = [
        ("onboarding.permission.step1", "1"),
        ("onboarding.permission.step2", "2"),
        ("onboarding.permission.step3", "3"),
        ("onboarding.permission.step4", "4")
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
            ForEach(steps, id: \.number) { step in
                HStack(alignment: .top, spacing: DesignTokens.Spacing.sm) {
                    Text(step.number)
                        .font(DesignTokens.Typography.caption(weight: .semibold))
                        .foregroundColor(DesignTokens.Colors.accentPrimary)
                        .frame(width: 18, height: 18)
                        .background(
                            Circle()
                                .fill(DesignTokens.Colors.accentPrimary.opacity(0.1))
                        )

                    Text(languageSettings.localized(step.key))
                        .font(DesignTokens.Typography.caption())
                        .foregroundColor(DesignTokens.Colors.foregroundSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .padding(DesignTokens.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: DesignTokens.Radius.md, style: .continuous)
                .fill(DesignTokens.Colors.backgroundSecondary)
        )
        .padding(.horizontal, DesignTokens.Spacing.lg)
    }
}

// MARK: - Preview

#Preview {
    OnboardingPermissionStep()
        .frame(width: 520, height: 480)
        .background(DesignTokens.Colors.backgroundElevated)
        .environmentObject(OnboardingManager())
        .environmentObject(LanguageSettings())
}
