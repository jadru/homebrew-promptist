//
//  WindowObserver.swift
//  Promptist
//
//  Observes window open/close events to dynamically show/hide the dock icon.
//

import AppKit
import Combine

/// Observes window open/close events to dynamically show/hide the dock icon.
/// Only the manager window shows in dock. Onboarding is handled separately and
/// ghost windows are automatically closed.
final class WindowObserver: ObservableObject {
    private var cancellables = Set<AnyCancellable>()
    private let trackedWindowIds: Set<String>

    init(trackedWindowIds: Set<String> = ["manager"]) {
        self.trackedWindowIds = trackedWindowIds
        NSApp.setActivationPolicy(.accessory)
        setupWindowObservers()
        setupDockClickHandler()
    }

    // MARK: - Window Observers

    private func setupWindowObservers() {
        NotificationCenter.default.publisher(for: NSWindow.didBecomeKeyNotification)
            .sink { [weak self] notification in
                self?.handleWindowBecameKey(notification)
            }
            .store(in: &cancellables)

        NotificationCenter.default.publisher(for: NSWindow.willCloseNotification)
            .sink { [weak self] notification in
                self?.handleWindowWillClose(notification)
            }
            .store(in: &cancellables)
    }

    private func setupDockClickHandler() {
        NSAppleEventManager.shared().setEventHandler(
            self,
            andSelector: #selector(handleReopenApp(_:withReplyEvent:)),
            forEventClass: AEEventClass(kCoreEventClass),
            andEventID: AEEventID(kAEReopenApplication)
        )
    }

    // MARK: - Event Handlers

    @objc
    private func handleReopenApp(
        _ event: NSAppleEventDescriptor,
        withReplyEvent reply: NSAppleEventDescriptor
    ) {
        DispatchQueue.main.async { [weak self] in
            self?.closeGhostOnboardingWindows()

            let hasVisibleTrackedWindow = NSApp.windows.contains { window in
                self?.isTrackedWindow(window) == true && window.isVisible
            }

            if !hasVisibleTrackedWindow {
                self?.hideFromDock()
            }
        }
    }

    private func handleWindowBecameKey(_ notification: Notification) {
        guard let window = notification.object as? NSWindow else { return }

        if isTrackedWindow(window) {
            showInDock()
        }
    }

    private func handleWindowWillClose(_ notification: Notification) {
        guard let closingWindow = notification.object as? NSWindow else { return }
        guard isTrackedWindow(closingWindow) else { return }

        DispatchQueue.main.async { [weak self] in
            self?.updateDockVisibility(excluding: closingWindow)
        }
    }

    // MARK: - Window Helpers

    private func isTrackedWindow(_ window: NSWindow) -> Bool {
        if let identifier = window.identifier?.rawValue,
           trackedWindowIds.contains(identifier) {
            return true
        }
        if window.title.contains("Manager") {
            return true
        }
        return false
    }

    private func closeGhostOnboardingWindows() {
        for window in NSApp.windows {
            if window.identifier?.rawValue == "onboarding" {
                window.orderOut(nil)
                window.close()
            }
        }
    }

    private func updateDockVisibility(excluding closedWindow: NSWindow) {
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

    // MARK: - Dock Visibility

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
