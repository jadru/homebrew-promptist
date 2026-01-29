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
        VStack(spacing: 24) {
            Spacer()

            ZStack {
                Circle()
                    .fill(permissionManager.hasPermission
                        ? Color.green.opacity(0.1)
                        : Color.orange.opacity(0.1))
                    .frame(width: 88, height: 88)

                Image(systemName: permissionManager.hasPermission
                    ? "checkmark.shield.fill"
                    : "lock.shield")
                    .font(.system(size: 40))
                    .foregroundStyle(permissionManager.hasPermission ? .green : .orange)
            }
            .animation(.easeInOut(duration: 0.3), value: permissionManager.hasPermission)

            VStack(spacing: 8) {
                Text(languageSettings.localized("onboarding.permission.title"))
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(.primary)

                Text(languageSettings.localized("onboarding.permission.subtitle"))
                    .font(.system(size: 15))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
            }

            PermissionStatusBadge(hasPermission: permissionManager.hasPermission)

            Spacer()

            if !permissionManager.hasPermission {
                Button {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        showingInstructions.toggle()
                    }
                } label: {
                    HStack(spacing: 4) {
                        Text(languageSettings.localized("onboarding.permission.show_instructions"))
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        Image(systemName: showingInstructions ? "chevron.up" : "chevron.down")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(.tertiary)
                    }
                }
                .buttonStyle(.plain)

                if showingInstructions {
                    InstructionsList()
                        .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }

            Spacer()

            VStack(spacing: 8) {
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
                        HStack(spacing: 4) {
                            ProgressView()
                                .scaleEffect(0.7)

                            Text(languageSettings.localized("onboarding.permission.checking"))
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                    }

                    Button {
                        onboardingManager.nextStep()
                    } label: {
                        Text(languageSettings.localized("onboarding.permission.skip"))
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                    .buttonStyle(.plain)
                    .padding(.top, 4)
                }
            }

            Spacer()
                .frame(height: 20)
        }
        .padding(.horizontal, 24)
        .onAppear {
            permissionManager.startPollingForPermission()
        }
        .onDisappear {
            permissionManager.stopPolling()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
            permissionManager.checkPermission()
        }
    }
}

// MARK: - Permission Status Badge

private struct PermissionStatusBadge: View {
    let hasPermission: Bool
    @EnvironmentObject private var languageSettings: LanguageSettings

    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(hasPermission ? Color.green : Color.orange)
                .frame(width: 8, height: 8)

            Text(hasPermission
                ? languageSettings.localized("onboarding.permission.status.granted")
                : languageSettings.localized("onboarding.permission.status.pending"))
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(hasPermission ? .green : .orange)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            Capsule()
                .fill(hasPermission
                    ? Color.green.opacity(0.1)
                    : Color.orange.opacity(0.1))
        )
        .animation(.easeInOut(duration: 0.3), value: hasPermission)
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
        VStack(alignment: .leading, spacing: 8) {
            ForEach(steps, id: \.number) { step in
                HStack(alignment: .top, spacing: 8) {
                    Text(step.number)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.accent)
                        .frame(width: 18, height: 18)
                        .background(
                            Circle()
                                .fill(Color.accentColor.opacity(0.1))
                        )

                    Text(languageSettings.localized(step.key))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(.quaternary)
        )
        .padding(.horizontal, 20)
    }
}

// MARK: - Preview

#Preview {
    OnboardingPermissionStep()
        .frame(width: 520, height: 480)
        .background(Color(nsColor: .windowBackgroundColor))
        .environmentObject(OnboardingManager())
        .environmentObject(LanguageSettings())
}
