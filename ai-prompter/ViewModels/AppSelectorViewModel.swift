import Foundation
import Combine
import AppKit

/// Drives the app selector drawer with built-in, installed, and custom apps plus filtering.
@MainActor
final class AppSelectorViewModel: ObservableObject {
    @Published var builtInApps: [AppInfo]
    @Published var installedApps: [AppInfo]
    @Published var customApps: [AppInfo]
    @Published var selectedApps: Set<AppInfo>
    @Published var searchText: String = ""

    private let workspace: NSWorkspace

    init(
        initialLinkedApps: [PromptAppTarget],
        workspace: NSWorkspace = .shared
    ) {
        self.workspace = workspace
        self.builtInApps = Self.loadBuiltInApps(using: workspace)
        self.installedApps = Self.loadInstalledApps(using: workspace)
        self.customApps = []
        self.selectedApps = []

        hydrateSelection(from: initialLinkedApps)
    }

    func isSelected(_ app: AppInfo) -> Bool {
        selectedApps.contains(app)
    }

    func toggleSelection(_ app: AppInfo) {
        if selectedApps.contains(app) {
            selectedApps.remove(app)
        } else {
            selectedApps.insert(app)
        }
    }

    func addEmptyCustomApp() {
        let newApp = AppInfo(name: "Custom App", bundleId: nil, icon: nil, isCustom: true)
        customApps.append(newApp)
        selectedApps.insert(newApp)
    }

    func removeCustomApp(_ app: AppInfo) {
        customApps.removeAll { $0.id == app.id }
        selectedApps.remove(app)
    }

    func refreshInstalledApps() {
        installedApps = Self.loadInstalledApps(using: workspace)
    }

    var filteredBuiltInApps: [AppInfo] {
        filterApps(builtInApps)
    }

    var filteredInstalledApps: [AppInfo] {
        filterApps(prunedInstalledApps())
    }

    var filteredCustomApps: [AppInfo] {
        filterApps(customApps)
    }

    func linkedAppTargets() -> [PromptAppTarget] {
        selectedApps.compactMap { app in
            if let tracked = resolveTrackedApp(from: app) {
                return .tracked(tracked)
            }

            let trimmedName = app.name.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmedName.isEmpty else { return nil }

            let trimmedBundle = app.bundleId?.trimmingCharacters(in: .whitespacesAndNewlines)
            let normalizedBundle = trimmedBundle?.isEmpty == false ? trimmedBundle : nil
            return .custom(name: trimmedName, bundleIdentifier: normalizedBundle)
        }
        .sorted { $0.displayName.localizedCaseInsensitiveCompare($1.displayName) == .orderedAscending }
    }

    // MARK: - Private helpers

    private func hydrateSelection(from targets: [PromptAppTarget]) {
        for target in targets {
            guard let appInfo = findOrCreateAppInfo(for: target) else { continue }
            selectedApps.insert(appInfo)
        }
    }

    private func findOrCreateAppInfo(for target: PromptAppTarget) -> AppInfo? {
        switch target {
        case .tracked(let trackedApp):
            if let existing = (builtInApps + installedApps).first(where: { info in
                matchesTrackedApp(info: info, trackedApp: trackedApp)
            }) {
                return existing
            }

            let config = TrackedAppConfig.config(for: trackedApp)
            let bundleId = config?.bundleIdentifiers.first
            let icon = bundleId.flatMap { workspace.urlForApplication(withBundleIdentifier: $0) }.map { workspace.icon(forFile: $0.path) }
            let newApp = AppInfo(
                name: trackedApp.displayName,
                bundleId: bundleId,
                icon: icon,
                isCustom: false
            )
            builtInApps.append(newApp)
            return newApp

        case .custom(let name, let bundleIdentifier):
            if let existing = (customApps + installedApps + builtInApps).first(where: { info in
                matchesCustomApp(info: info, name: name, bundleIdentifier: bundleIdentifier)
            }) {
                return existing
            }

            let newApp = AppInfo(
                name: name,
                bundleId: bundleIdentifier,
                icon: nil,
                isCustom: true
            )
            customApps.append(newApp)
            return newApp
        }
    }

    private func matchesTrackedApp(info: AppInfo, trackedApp: TrackedApp) -> Bool {
        if let bundleId = info.bundleId,
           let resolved = TrackedAppResolver.resolveTrackedApp(for: bundleId),
           resolved == trackedApp {
            return true
        }

        return info.name.caseInsensitiveCompare(trackedApp.displayName) == .orderedSame
    }

    private func matchesCustomApp(info: AppInfo, name: String, bundleIdentifier: String?) -> Bool {
        if let bundleIdentifier,
           let normalizedBundle = info.normalizedBundleId,
           normalizedBundle == bundleIdentifier.lowercased() {
            return true
        }
        return info.name.caseInsensitiveCompare(name) == .orderedSame
    }

    private func resolveTrackedApp(from appInfo: AppInfo) -> TrackedApp? {
        if let bundleId = appInfo.bundleId,
           let tracked = TrackedAppResolver.resolveTrackedApp(for: bundleId) {
            return tracked
        }

        if let match = TrackedAppConfig.configs.first(where: {
            $0.displayName.caseInsensitiveCompare(appInfo.name) == .orderedSame
        }) {
            return match.trackedApp
        }

        return nil
    }

    private func filterApps(_ apps: [AppInfo]) -> [AppInfo] {
        let term = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !term.isEmpty else { return apps }
        return apps.filter { $0.matchesSearch(term) }
    }

    private func prunedInstalledApps() -> [AppInfo] {
        let builtInBundles = Set(builtInApps.compactMap { $0.normalizedBundleId })
        let builtInNames = Set(builtInApps.map { $0.normalizedName })
        return installedApps.filter { app in
            if let bundle = app.normalizedBundleId, builtInBundles.contains(bundle) { return false }
            return !builtInNames.contains(app.normalizedName)
        }
    }

    private static func loadBuiltInApps(using workspace: NSWorkspace) -> [AppInfo] {
        TrackedAppConfig.configs.map { config in
            let bundleId = config.bundleIdentifiers.first
            let icon = bundleId.flatMap { workspace.urlForApplication(withBundleIdentifier: $0) }
                .map { workspace.icon(forFile: $0.path) }

            return AppInfo(
                name: config.displayName,
                bundleId: bundleId,
                icon: icon,
                isCustom: false
            )
        }
        .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    private static func loadInstalledApps(using workspace: NSWorkspace) -> [AppInfo] {
        let applicationsURL = URL(fileURLWithPath: "/Applications")
        let fileManager = FileManager.default
        let contents = (try? fileManager.contentsOfDirectory(at: applicationsURL, includingPropertiesForKeys: nil)) ?? []

        let appInfos: [AppInfo] = contents
            .filter { $0.pathExtension == "app" }
            .map { url in
                let bundle = Bundle(url: url)
                let name = bundle?.object(forInfoDictionaryKey: "CFBundleName") as? String ?? url.deletingPathExtension().lastPathComponent
                let bundleId = bundle?.bundleIdentifier
                let icon = workspace.icon(forFile: url.path)

                return AppInfo(
                    name: name,
                    bundleId: bundleId,
                    icon: icon,
                    isCustom: false
                )
            }
            .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }

        return appInfos
    }
}
