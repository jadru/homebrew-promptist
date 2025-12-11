//
//  PromptistApp.swift
//  Promptist
//
//  Created by Younggun Park on 11/25/25.
//

import SwiftUI
import AppKit
import Combine

// <CHORUS_TAG>main</CHORUS_TAG>
@main
struct PromptistApp: App {
    @StateObject private var appContext = AppContextService()
    @StateObject private var languageSettings = LanguageSettings()
    @StateObject private var promptListViewModel: PromptListViewModel
    @StateObject private var shortcutManager: ShortcutManager
    @StateObject private var onboardingManager: OnboardingManager

    // Variable system services
    @StateObject private var accessibilityManager: AccessibilityPermissionManager
    @StateObject private var clipboardHistory: ClipboardHistoryManager
    @StateObject private var executionService: PromptExecutionService

    // Window observer for dock visibility
    @StateObject private var windowObserver = WindowObserver()

    @Environment(\.openWindow) private var openWindow

    init() {
        if let appIcon = NSImage(named: "AppIcon") {
            NSApplication.shared.applicationIconImage = appIcon
        }

        let repository = FilePromptTemplateRepository()
        let viewModel = PromptListViewModel(repository: repository)
        _promptListViewModel = StateObject(wrappedValue: viewModel)

        // Create shared AppContext instance
        let sharedContext = AppContextService()
        _appContext = StateObject(wrappedValue: sharedContext)

        // Initialize shortcut infrastructure with SHARED context
        let store = FileShortcutStore()
        let manager = ShortcutManager(store: store, appContext: sharedContext)
        _shortcutManager = StateObject(wrappedValue: manager)

        // Initialize onboarding manager
        let onboarding = OnboardingManager()
        _onboardingManager = StateObject(wrappedValue: onboarding)

        // Set onboarding completion callback to open launcher
        onboarding.onOnboardingCompleted = {
            // Close onboarding window first, then open menu bar popover
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                // Close the onboarding window
                if let onboardingWindow = NSApp.windows.first(where: {
                    $0.identifier?.rawValue == "onboarding" ||
                    $0.title.contains("Promptist") ||
                    $0.title.contains("Welcome")
                }) {
                    onboardingWindow.close()
                }

                // Open the menu bar popover by simulating click on status item
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    // Try to find and click the status bar button
                    for window in NSApp.windows where window.className.contains("NSStatusBarWindow") {
                        if let button = window.contentView?.hitTest(NSPoint(x: 1, y: 1)) as? NSButton {
                            button.performClick(nil)
                            return
                        }
                    }
                    // Fallback: just activate the app
                    NSApp.activate(ignoringOtherApps: true)
                }
            }
        }

        // Initialize variable system services
        let accessibility = AccessibilityPermissionManager()
        _accessibilityManager = StateObject(wrappedValue: accessibility)

        let clipboard = ClipboardHistoryManager()
        _clipboardHistory = StateObject(wrappedValue: clipboard)

        let grabber = SelectionGrabber(permissionManager: accessibility)

        let execution = PromptExecutionService(
            selectionGrabber: grabber,
            clipboardHistory: clipboard
        )
        _executionService = StateObject(wrappedValue: execution)

        // Start clipboard monitoring
        clipboard.startMonitoring()

        // Set execution callback for shortcuts (now uses variable system)
        manager.onShortcutTriggered = { templateId in
            Task { @MainActor in
                if let template = viewModel.allTemplates.first(where: { $0.id == templateId }) {
                    let result = await execution.prepareExecution(for: template)

                    switch result {
                    case .directCopy(let content):
                        execution.copyToClipboard(content)
                        print("✅ Shortcut triggered: \(template.title)")
                        print("📋 Copied to clipboard: \(content.prefix(50))...")

                    case .needsInput:
                        // For shortcuts with interactive variables, just copy raw content
                        // (showing dialog from shortcut would be complex UX)
                        execution.copyToClipboard(template.content)
                        print("⚠️ Shortcut triggered (has variables): \(template.title)")
                    }
                }
            }
        }
    }

    var body: some Scene {
        // Onboarding Window
        Window("onboarding.window_title", id: "onboarding") {
            OnboardingContainerView()
                .environmentObject(onboardingManager)
                .environmentObject(languageSettings)
                .environment(\.locale, languageSettings.locale)
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
        .defaultPosition(.center)

        MenuBarExtra {
            if onboardingManager.shouldShowOnboarding {
                OnboardingBlockedCompactView {
                    openOnboardingWindow()
                }
                .environmentObject(languageSettings)
                .environment(\.locale, languageSettings.locale)
            } else {
                PromptLauncherView()
                    .environmentObject(appContext)
                    .environmentObject(executionService)
                    .environmentObject(languageSettings)
                    .environment(\.locale, languageSettings.locale)
            }
        } label: {
            MenuBarIconView(count: overlayCount, showWarning: onboardingManager.shouldShowOnboarding)
                .onAppear {
                    syncAppContext()
                    // Open onboarding window on first launch
                    if onboardingManager.shouldShowOnboarding {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            openOnboardingWindow()
                        }
                    }
                }
                .onReceive(appContext.$currentTrackedApp) { _ in
                    syncAppContext()
                }
                .onReceive(appContext.$frontmostBundleIdentifier) { _ in
                    syncAppContext()
                }
                .onReceive(appContext.$frontmostAppName) { _ in
                    syncAppContext()
                }
        }
        .menuBarExtraStyle(.window)

        Window("prompt_manager.window_title", id: "manager") {
            if onboardingManager.shouldShowOnboarding {
                OnboardingBlockedView {
                    openOnboardingWindow()
                }
                .environmentObject(languageSettings)
                .environment(\.locale, languageSettings.locale)
            } else {
                PromptManagerRootView(
                    promptListViewModel: promptListViewModel,
                    shortcutManager: shortcutManager
                )
                .environmentObject(appContext)
                .environmentObject(languageSettings)
                .environment(\.locale, languageSettings.locale)
            }
        }
        .windowResizability(.contentSize)

        Settings {
            SettingsView()
                .environmentObject(languageSettings)
                .environment(\.locale, languageSettings.locale)
        }
    }

    private var overlayCount: Int {
        promptListViewModel.linkedTemplatesForCurrentApp.count
    }

    private func syncAppContext() {
        promptListViewModel.updateCurrentApp(
            trackedApp: appContext.currentTrackedApp,
            bundleIdentifier: appContext.frontmostBundleIdentifier,
            appDisplayName: appContext.frontmostAppName
        )
    }

    private func openOnboardingWindow() {
        openWindow(id: "onboarding")
        // Bring window to front
        NSApp.activate(ignoringOtherApps: true)
    }
}

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
                    if showWarning {
                        // Warning indicator when onboarding is needed
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
        .frame(width: 18, height: 18)
    }
}

// MARK: - Window Observer for Dock Visibility

/// Observes window open/close events to dynamically show/hide the dock icon.
/// Only the manager window shows in dock. Onboarding is handled separately and
/// ghost windows are automatically closed.
final class WindowObserver: ObservableObject {
    private var cancellables = Set<AnyCancellable>()
    // Only track manager window for dock visibility
    private let trackedWindowIds = ["manager"]

    init() {
        // Start as accessory (no dock icon) by default
        NSApp.setActivationPolicy(.accessory)

        setupWindowObservers()
        setupDockClickHandler()
    }

    private func setupWindowObservers() {
        // Observe when windows become visible
        NotificationCenter.default.publisher(for: NSWindow.didBecomeKeyNotification)
            .sink { [weak self] notification in
                self?.handleWindowBecameKey(notification)
            }
            .store(in: &cancellables)

        // Observe when windows close
        NotificationCenter.default.publisher(for: NSWindow.willCloseNotification)
            .sink { [weak self] notification in
                self?.handleWindowWillClose(notification)
            }
            .store(in: &cancellables)
    }

    private func setupDockClickHandler() {
        // Handle dock icon click when no windows are open
        NSAppleEventManager.shared().setEventHandler(
            self,
            andSelector: #selector(handleReopenApp(_:withReplyEvent:)),
            forEventClass: AEEventClass(kCoreEventClass),
            andEventID: AEEventID(kAEReopenApplication)
        )
    }

    @objc private func handleReopenApp(_ event: NSAppleEventDescriptor, withReplyEvent reply: NSAppleEventDescriptor) {
        // When dock icon is clicked, close any ghost onboarding windows and update dock
        DispatchQueue.main.async { [weak self] in
            // Close any ghost onboarding windows
            self?.closeGhostOnboardingWindows()

            // Check if any tracked windows (manager) are visible
            let hasVisibleTrackedWindow = NSApp.windows.contains { window in
                self?.isTrackedWindow(window) == true && window.isVisible
            }

            if !hasVisibleTrackedWindow {
                self?.hideFromDock()
            }
        }
    }

    private func closeGhostOnboardingWindows() {
        // Find and close any onboarding windows that shouldn't be visible
        for window in NSApp.windows {
            if window.identifier?.rawValue == "onboarding" ||
               window.title.contains("Welcome") ||
               (window.title.contains("Promptist") && !window.title.contains("Manager")) {
                window.orderOut(nil) // Hide without triggering close notification
                window.close()
            }
        }
    }

    private func handleWindowBecameKey(_ notification: Notification) {
        guard let window = notification.object as? NSWindow else { return }

        // Check if this is a tracked window (manager only)
        if isTrackedWindow(window) {
            showInDock()
        }
    }

    private func handleWindowWillClose(_ notification: Notification) {
        guard let closingWindow = notification.object as? NSWindow else { return }

        // Only handle tracked windows (manager)
        guard isTrackedWindow(closingWindow) else { return }

        // Check if any other tracked windows will remain open
        DispatchQueue.main.async { [weak self] in
            self?.updateDockVisibility(excluding: closingWindow)
        }
    }

    private func isTrackedWindow(_ window: NSWindow) -> Bool {
        // Check by window identifier - only manager
        if let identifier = window.identifier?.rawValue,
           trackedWindowIds.contains(identifier) {
            return true
        }
        // Check by title for manager window
        if window.title.contains("Manager") {
            return true
        }
        return false
    }

    private func updateDockVisibility(excluding closedWindow: NSWindow) {
        // Check if any tracked windows are still open (excluding the one being closed)
        let hasOpenTrackedWindows = NSApp.windows.contains { window in
            window != closedWindow &&
            isTrackedWindow(window) &&
            window.isVisible
        }

        if hasOpenTrackedWindows {
            showInDock()
        } else {
            hideFromDock()
        }
    }

    private func showInDock() {
        guard NSApp.activationPolicy() != .regular else { return }
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
    }

    private func hideFromDock() {
        guard NSApp.activationPolicy() != .accessory else { return }
        NSApp.setActivationPolicy(.accessory)
    }
}
