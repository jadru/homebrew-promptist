import Foundation
import AppKit

/// Normalized representation for any app we can link to a prompt.
struct AppInfo: Identifiable, Hashable {
    var id: UUID
    var name: String
    var bundleId: String?
    var icon: NSImage?
    var isCustom: Bool

    init(
        id: UUID = UUID(),
        name: String,
        bundleId: String?,
        icon: NSImage? = nil,
        isCustom: Bool
    ) {
        self.id = id
        self.name = name
        self.bundleId = bundleId
        self.icon = icon
        self.isCustom = isCustom
    }

    var normalizedName: String { name.lowercased() }
    var normalizedBundleId: String? { bundleId?.lowercased() }

    func matchesSearch(_ term: String) -> Bool {
        guard !term.isEmpty else { return true }
        let lowered = term.lowercased()
        if normalizedName.contains(lowered) { return true }
        if let normalizedBundleId, normalizedBundleId.contains(lowered) { return true }
        return false
    }

    static func == (lhs: AppInfo, rhs: AppInfo) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
