import Foundation
import AppKit
import Combine
import SwiftUI

// MARK: - Accessibility Permission Manager

@MainActor
final class AccessibilityPermissionManager: ObservableObject {
    @Published var hasPermission: Bool = false
    @Published var shouldShowAlert: Bool = false
    @Published var isPolling: Bool = false

    private var pollingTimer: Timer?

    init() {
        checkPermission()
    }

    deinit {
        pollingTimer?.invalidate()
    }

    // MARK: - Permission Polling

    /// Start polling for permission status at regular intervals
    func startPollingForPermission(interval: TimeInterval = 1.0) {
        stopPolling()
        isPolling = true

        pollingTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.checkPermission()
                // Auto-stop if permission is granted
                if self?.hasPermission == true {
                    self?.stopPolling()
                }
            }
        }
    }

    /// Stop polling for permission status
    func stopPolling() {
        pollingTimer?.invalidate()
        pollingTimer = nil
        isPolling = false
    }

    /// Check if app has Accessibility permissions
    func checkPermission(promptIfNeeded: Bool = false) {
        let options: NSDictionary = [
            kAXTrustedCheckOptionPrompt.takeRetainedValue() as String: promptIfNeeded
        ]
        hasPermission = AXIsProcessTrustedWithOptions(options)
    }

    /// Request permission with system prompt
    func requestPermission() {
        let options: NSDictionary = [
            kAXTrustedCheckOptionPrompt.takeRetainedValue() as String: true
        ]
        hasPermission = AXIsProcessTrustedWithOptions(options)

        // If permission is granted, no need to show alert
        if hasPermission {
            shouldShowAlert = false
        }
    }

    /// Open System Settings directly to Accessibility pane
    func openSystemSettings() {
        // macOS 13+ (Ventura and later)
        if #available(macOS 13.0, *) {
            // Try to open directly to Accessibility pane
            if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
                NSWorkspace.shared.open(url)
            }
        } else {
            // macOS 12 and earlier - open Security & Privacy
            let prefpaneUrl = URL(fileURLWithPath: "/System/Library/PreferencePanes/Security.prefPane")
            NSWorkspace.shared.open(prefpaneUrl)
        }
    }

    /// Get user-friendly instructions
    var permissionInstructions: String {
        """
        To use keyboard shortcuts, Promptist needs Accessibility permissions.

        Steps:
        1. Click "Open System Settings" below
        2. Click the lock icon and enter your password
        3. Find "Promptist" in the list
        4. Enable the checkbox next to it
        5. Restart Promptist
        """
    }

    var permissionInstructionsKorean: String {
        """
        키보드 단축키를 사용하려면 Promptist에 접근성 권한이 필요합니다.

        단계:
        1. 아래 "시스템 설정 열기" 버튼 클릭
        2. 잠금 아이콘 클릭 후 비밀번호 입력
        3. 목록에서 "Promptist" 찾기
        4. 옆의 체크박스 활성화
        5. Promptist 재시작
        """
    }
}

// MARK: - Permission Alert View

import SwiftUI

struct AccessibilityPermissionAlert: View {
    @ObservedObject var permissionManager: AccessibilityPermissionManager
    @EnvironmentObject private var languageSettings: LanguageSettings
    let onDismiss: () -> Void

    var body: some View {
        VStack(spacing: DesignTokens.Spacing.lg) {
            // Icon
            Image(systemName: "lock.shield")
                .font(.system(size: 48))
                .foregroundColor(DesignTokens.Colors.accentPrimary)

            // Title
            Text(languageSettings.localized("accessibility.alert.title"))
                .font(DesignTokens.Typography.headline(20, weight: .semibold))
                .foregroundColor(DesignTokens.Colors.foregroundPrimary)
                .multilineTextAlignment(.center)

            // Instructions
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
                instructionStep(
                    number: "1",
                    text: languageSettings.localized("accessibility.alert.step1")
                )
                instructionStep(
                    number: "2",
                    text: languageSettings.localized("accessibility.alert.step2")
                )
                instructionStep(
                    number: "3",
                    text: languageSettings.localized("accessibility.alert.step3")
                )
                instructionStep(
                    number: "4",
                    text: languageSettings.localized("accessibility.alert.step4")
                )
                instructionStep(
                    number: "5",
                    text: languageSettings.localized("accessibility.alert.step5")
                )
            }
            .padding(DesignTokens.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: DesignTokens.Radius.md, style: .continuous)
                    .fill(DesignTokens.Colors.backgroundSecondary)
            )

            // Warning
            HStack(spacing: DesignTokens.Spacing.sm) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: DesignTokens.IconSize.md))
                    .foregroundColor(DesignTokens.Colors.warning)

                Text(languageSettings.localized("accessibility.alert.warning"))
                    .font(DesignTokens.Typography.caption())
                    .foregroundColor(DesignTokens.Colors.foregroundSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(DesignTokens.Spacing.sm)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: DesignTokens.Radius.sm, style: .continuous)
                    .fill(DesignTokens.Colors.warning.opacity(0.1))
            )

            Spacer()

            // Buttons
            VStack(spacing: DesignTokens.Spacing.sm) {
                ActionButton(
                    languageSettings.localized("accessibility.alert.open_settings"),
                    variant: .primary
                ) {
                    permissionManager.openSystemSettings()
                    // Check permission after a delay
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        permissionManager.checkPermission()
                        if permissionManager.hasPermission {
                            onDismiss()
                        }
                    }
                }

                ActionButton(
                    languageSettings.localized("accessibility.alert.later"),
                    variant: .secondary,
                    action: onDismiss
                )
            }
        }
        .padding(DesignTokens.Spacing.xl)
        .frame(width: 500)
        .frame(minHeight: 520, maxHeight: 600)
        .background(DesignTokens.Colors.backgroundElevated)
    }

    private func instructionStep(number: String, text: String) -> some View {
        HStack(alignment: .top, spacing: DesignTokens.Spacing.md) {
            Text(number)
                .font(DesignTokens.Typography.headline(14, weight: .semibold))
                .foregroundColor(DesignTokens.Colors.accentPrimary)
                .frame(width: 24, height: 24)
                .background(
                    Circle()
                        .fill(DesignTokens.Colors.accentPrimary.opacity(0.1))
                )

            Text(text)
                .font(DesignTokens.Typography.body())
                .foregroundColor(DesignTokens.Colors.foregroundPrimary)
                .fixedSize(horizontal: false, vertical: true)

            Spacer()
        }
    }
}

// MARK: - Compact Permission Banner

struct AccessibilityPermissionBanner: View {
    @ObservedObject var permissionManager: AccessibilityPermissionManager
    @EnvironmentObject private var languageSettings: LanguageSettings

    var body: some View {
        HStack(spacing: DesignTokens.Spacing.md) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: DesignTokens.IconSize.md))
                .foregroundColor(DesignTokens.Colors.warning)

            VStack(alignment: .leading, spacing: DesignTokens.Spacing.xxs) {
                Text(languageSettings.localized("accessibility.banner.title"))
                    .font(DesignTokens.Typography.label(weight: .semibold))
                    .foregroundColor(DesignTokens.Colors.foregroundPrimary)

                Text(languageSettings.localized("accessibility.banner.description"))
                    .font(DesignTokens.Typography.caption())
                    .foregroundColor(DesignTokens.Colors.foregroundSecondary)
            }

            Spacer()

            Button(action: {
                permissionManager.openSystemSettings()
            }) {
                Text(languageSettings.localized("accessibility.banner.button"))
                    .font(DesignTokens.Typography.label(weight: .medium))
                    .foregroundColor(DesignTokens.Colors.accentPrimary)
                    .padding(.horizontal, DesignTokens.Spacing.md)
                    .padding(.vertical, DesignTokens.Spacing.sm)
                    .background(
                        RoundedRectangle(cornerRadius: DesignTokens.Radius.sm, style: .continuous)
                            .fill(DesignTokens.Colors.accentPrimary.opacity(0.1))
                    )
            }
            .buttonStyle(.plain)
        }
        .padding(DesignTokens.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: DesignTokens.Radius.md, style: .continuous)
                .fill(DesignTokens.Colors.warning.opacity(0.1))
        )
        .overlay(
            RoundedRectangle(cornerRadius: DesignTokens.Radius.md, style: .continuous)
                .stroke(DesignTokens.Colors.warning.opacity(0.3), lineWidth: 1)
        )
    }
}
