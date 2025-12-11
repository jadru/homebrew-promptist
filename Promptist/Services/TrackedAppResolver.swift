import Foundation
import AppKit

/// Maps bundle identifiers to known tracked apps.
enum TrackedAppResolver {
    static func resolveTrackedApp(for bundleIdentifier: String) -> TrackedApp? {
        let normalized = bundleIdentifier.lowercased()
        for config in TrackedAppConfig.configs {
            if config.bundleIdentifiers.map({ $0.lowercased() }).contains(normalized) {
                return config.trackedApp
            }
        }
        return nil
    }

    static func resolveTrackedApp(for application: NSRunningApplication?) -> TrackedApp? {
        guard let bundleIdentifier = application?.bundleIdentifier else { return nil }
        return resolveTrackedApp(for: bundleIdentifier)
    }
}
