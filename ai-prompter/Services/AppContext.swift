import SwiftUI
import Combine
import AppKit

/// Tracks the frontmost application and resolves it to a `TrackedApp`.
@MainActor
final class AppContextService: ObservableObject {
    @Published var frontmostAppName: String?
    @Published var frontmostBundleIdentifier: String?
    @Published var currentTrackedApp: TrackedApp?

    private let workspace: NSWorkspace
    private var activationObserver: Any?

    init(workspace: NSWorkspace = .shared) {
        self.workspace = workspace
        updateFrontmostApp()

        activationObserver = workspace.notificationCenter.addObserver(
            forName: NSWorkspace.didActivateApplicationNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.updateFrontmostApp()
            }
        }
    }

    deinit {
        if let activationObserver {
            workspace.notificationCenter.removeObserver(activationObserver)
        }
    }

    @MainActor
    private func updateFrontmostApp() {
        let app = workspace.frontmostApplication
        frontmostAppName = app?.localizedName
        frontmostBundleIdentifier = app?.bundleIdentifier
        currentTrackedApp = TrackedAppResolver.resolveTrackedApp(for: app)
    }
}
