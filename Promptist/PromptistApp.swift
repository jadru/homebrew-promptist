//
//  PromptistApp.swift
//  Promptist
//
//  Created by Younggun Park on 11/25/25.
//

import SwiftUI
import AppKit

// <CHORUS_TAG>main</CHORUS_TAG>
@main
struct PromptistApp: App {
    // Use ServiceContainer for dependency injection
    @StateObject private var container = ServiceContainer.shared

    @Environment(\.openWindow) private var openWindow

    init() {
        configureAppIcon()
        configureOnboardingCallback()
    }

    var body: some Scene {
        // Onboarding Window
        Window("onboarding.window_title", id: "onboarding") {
            OnboardingContainerView()
                .environmentObject(container.onboardingManager)
                .environmentObject(container.languageSettings)
                .environment(\.locale, container.languageSettings.locale)
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
        .defaultPosition(.center)

        MenuBarExtra {
            menuBarContent
        } label: {
            menuBarLabel
        }
        .menuBarExtraStyle(.window)

        Window("prompt_manager.window_title", id: "manager") {
            managerWindowContent
        }
        .windowResizability(.contentSize)

        Settings {
            SettingsView()
                .environmentObject(container.languageSettings)
                .environment(\.locale, container.languageSettings.locale)
        }
    }

    // MARK: - View Builders

    @ViewBuilder
    private var menuBarContent: some View {
        if container.onboardingManager.shouldShowOnboarding {
            OnboardingBlockedCompactView {
                openOnboardingWindow()
            }
            .environmentObject(container.languageSettings)
            .environment(\.locale, container.languageSettings.locale)
        } else {
            PromptLauncherView()
                .environmentObject(container.appContext)
                .environmentObject(container.executionService)
                .environmentObject(container.languageSettings)
                .environment(\.locale, container.languageSettings.locale)
        }
    }

    private var menuBarLabel: some View {
        MenuBarIconView(
            count: overlayCount,
            showWarning: container.onboardingManager.shouldShowOnboarding
        )
        .onAppear {
            container.syncAppContext()
            openOnboardingIfNeeded()
        }
        .onReceive(container.appContext.$currentTrackedApp) { _ in
            container.syncAppContext()
        }
        .onReceive(container.appContext.$frontmostBundleIdentifier) { _ in
            container.syncAppContext()
        }
        .onReceive(container.appContext.$frontmostAppName) { _ in
            container.syncAppContext()
        }
    }

    @ViewBuilder
    private var managerWindowContent: some View {
        if container.onboardingManager.shouldShowOnboarding {
            OnboardingBlockedView {
                openOnboardingWindow()
            }
            .environmentObject(container.languageSettings)
            .environment(\.locale, container.languageSettings.locale)
        } else {
            PromptManagerRootView(
                promptListViewModel: container.promptListViewModel,
                shortcutManager: container.shortcutManager
            )
            .environmentObject(container.appContext)
            .environmentObject(container.languageSettings)
            .environment(\.locale, container.languageSettings.locale)
        }
    }

    // MARK: - Computed Properties

    private var overlayCount: Int {
        container.promptListViewModel.linkedTemplatesForCurrentApp.count
    }

    // MARK: - Configuration

    private func configureAppIcon() {
        if let appIcon = NSImage(named: "AppIcon") {
            NSApplication.shared.applicationIconImage = appIcon
        }
    }

    private func configureOnboardingCallback() {
        container.onboardingManager.onOnboardingCompleted = { [self] in
            Task { @MainActor in
                try? await Task.sleep(for: .milliseconds(200))
                closeOnboardingWindow()
                try? await Task.sleep(for: .milliseconds(100))
                openMenuBarPopover()
            }
        }
    }

    // MARK: - Window Management

    private func openOnboardingWindow() {
        openWindow(id: "onboarding")
        NSApp.activate(ignoringOtherApps: true)
    }

    private func openOnboardingIfNeeded() {
        if container.onboardingManager.shouldShowOnboarding {
            Task { @MainActor in
                try? await Task.sleep(for: .milliseconds(500))
                openOnboardingWindow()
            }
        }
    }

    private func closeOnboardingWindow() {
        if let onboardingWindow = NSApp.windows.first(where: { window in
            window.identifier?.rawValue == "onboarding" ||
            window.title.contains("Promptist") ||
            window.title.contains("Welcome")
        }) {
            onboardingWindow.close()
        }
    }

    private func openMenuBarPopover() {
        for window in NSApp.windows where window.className.contains("NSStatusBarWindow") {
            if let button = window.contentView?.hitTest(NSPoint(x: 1, y: 1)) as? NSButton {
                button.performClick(nil)
                return
            }
        }
        NSApp.activate(ignoringOtherApps: true)
    }
}

// MARK: - Menu Bar Icon View

/// Custom menu bar icon with a badge showing the current app's template count.
private struct MenuBarIconView: View {
    let count: Int
    var showWarning: Bool = false

    var body: some View {
        HStack(spacing: 0) {
            Image("MenuBarIcon")
                .resizable()
                .renderingMode(.template)
                .scaledToFit()
                .frame(width: 18, height: 18)
                .foregroundStyle(.primary)
                .overlay(alignment: .topTrailing) {
                    badgeOverlay
                }
        }
        .frame(width: 18, height: 18)
    }

    @ViewBuilder
    private var badgeOverlay: some View {
        if showWarning {
            Circle()
                .fill(Color.orange)
                .frame(width: 8, height: 8)
                .offset(x: 4, y: -4)
        } else if count > 0 {
            Text("\(count)")
                .font(.system(size: 8, weight: .bold))
                .padding(.horizontal, 3.5)
                .padding(.vertical, 1.25)
                .background(
                    Capsule()
                        .fill(Color.red.opacity(0.95))
                )
                .foregroundColor(.white)
                .offset(x: 5, y: -5)
        }
    }
}
