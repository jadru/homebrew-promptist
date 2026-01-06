import Foundation
import Combine
import ServiceManagement

/// Manages the launch at login functionality for the app.
/// Uses ServiceManagement framework to register/unregister the app as a login item.
@MainActor
class LaunchAtLoginManager: ObservableObject {
    @Published var isEnabled: Bool {
        didSet {
            if oldValue != isEnabled {
                updateLaunchAtLogin()
            }
        }
    }

    static let shared = LaunchAtLoginManager()

    private init() {
        // Check current status on initialization
        self.isEnabled = SMAppService.mainApp.status == .enabled
    }

    /// Updates the launch at login status based on the current isEnabled value
    private func updateLaunchAtLogin() {
        do {
            if isEnabled {
                if SMAppService.mainApp.status == .enabled {
                    // Already enabled, no action needed
                    return
                }
                try SMAppService.mainApp.register()
            } else {
                if SMAppService.mainApp.status == .notRegistered {
                    // Already disabled, no action needed
                    return
                }
                try SMAppService.mainApp.unregister()
            }
        } catch {
            // Revert the state if registration/unregistration fails
            isEnabled = !isEnabled
            AppLogger.log("Failed to update launch at login", level: .error, error: error)
        }
    }

    /// Refreshes the current launch at login status
    func refresh() {
        isEnabled = SMAppService.mainApp.status == .enabled
    }
}
