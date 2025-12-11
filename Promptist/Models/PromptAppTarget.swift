import Foundation

/// Represents either a known tracked app or a custom app added by the user.
enum PromptAppTarget: Hashable, Codable, Identifiable {
    case tracked(TrackedApp)
    case custom(name: String, bundleIdentifier: String?)

    var id: String {
        switch self {
        case .tracked(let app):
            return "tracked-\(app.rawValue)"
        case .custom(_, let bundleIdentifier):
            if let bundleIdentifier {
                return "custom-\(bundleIdentifier.lowercased())"
            }
            return "custom-\(displayName.lowercased())"
        }
    }

    var displayName: String {
        switch self {
        case .tracked(let app):
            return app.displayName
        case .custom(let name, _):
            return name
        }
    }

    var normalizedDisplayName: String {
        displayName.lowercased()
    }

    var trackedApp: TrackedApp? {
        switch self {
        case .tracked(let app):
            return app
        case .custom:
            return nil
        }
    }

    var bundleIdentifier: String? {
        switch self {
        case .tracked:
            return nil
        case .custom(_, let bundleIdentifier):
            return bundleIdentifier?.lowercased()
        }
    }

    func matches(_ filter: PromptAppFilter) -> Bool {
        if let trackedApp, trackedApp == filter.trackedApp {
            return true
        }

        if let filterBundle = filter.normalizedBundleIdentifier,
           let bundleIdentifier,
           bundleIdentifier.caseInsensitiveCompare(filterBundle) == .orderedSame {
            return true
        }

        if let filterName = filter.normalizedDisplayName,
           filterName == normalizedDisplayName {
            return true
        }

        return false
    }
}

/// Represents the app (tracked or custom) we are filtering prompts against.
struct PromptAppFilter: Equatable {
    let trackedApp: TrackedApp?
    let bundleIdentifier: String?
    let displayName: String?

    var normalizedBundleIdentifier: String? {
        bundleIdentifier?.lowercased()
    }

    var normalizedDisplayName: String? {
        displayName?.lowercased()
    }
}
