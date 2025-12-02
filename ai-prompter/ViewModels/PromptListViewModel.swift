import Foundation
import Combine

/// Drives the prompt list, including persistence, filtering, and mutations.
final class PromptListViewModel: ObservableObject {
    struct PromptCreationIntent: Equatable {
        let presetApps: [PromptAppTarget]
    }

    @Published var allTemplates: [PromptTemplate] = []
    @Published var allGroups: [PromptTemplateGroup] = []
    @Published var searchText: String = ""
    @Published var currentTrackedApp: TrackedApp?
    @Published var currentBundleIdentifier: String?
    @Published var currentAppName: String?
    @Published private(set) var recentSearches: [String] = []
    @Published var pendingCreationIntent: PromptCreationIntent?

    private let repository: PromptTemplateRepository
    private var cancellables = Set<AnyCancellable>()
    private static let recentSearchesKey = "PromptListViewModel.recentSearches"

    init(repository: PromptTemplateRepository) {
        self.repository = repository
        allTemplates = repository.loadTemplates()
        allGroups = repository.loadGroups()
        recentSearches = UserDefaults.standard.stringArray(forKey: Self.recentSearchesKey) ?? []

        observeSearchText()
    }

    func updateCurrentApp(trackedApp: TrackedApp?, bundleIdentifier: String?, appDisplayName: String?) {
        currentTrackedApp = trackedApp

        let trimmedBundle = bundleIdentifier?.trimmingCharacters(in: .whitespacesAndNewlines)
        currentBundleIdentifier = trimmedBundle?.isEmpty == false ? trimmedBundle?.lowercased() : nil

        let trimmedName = appDisplayName?.trimmingCharacters(in: .whitespacesAndNewlines)
        currentAppName = trimmedName?.isEmpty == false ? trimmedName : nil
    }

    func prepareCreationIntentForCurrentApp() {
        guard let app = currentPromptAppTarget else {
            pendingCreationIntent = PromptCreationIntent(presetApps: [])
            return
        }
        pendingCreationIntent = PromptCreationIntent(presetApps: [app])
    }

    func consumePendingCreationIntent() -> PromptCreationIntent? {
        let intent = pendingCreationIntent
        pendingCreationIntent = nil
        return intent
    }

    var filteredTemplates: [PromptTemplate] {
        let searchTerm = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

        let appFiltered = applyAppFilter(to: allTemplates)

        let searched = appFiltered.filter { template in
            guard !searchTerm.isEmpty else { return true }
            let inTitle = template.title.lowercased().contains(searchTerm)
            let inTags = template.tags.map { $0.lowercased() }.contains { $0.contains(searchTerm) }
            return inTitle || inTags
        }

        return sortTemplates(searched)
    }

    var linkedTemplatesForCurrentApp: [PromptTemplate] {
        guard let appFilter = activeAppFilter else { return [] }
        let linked = filteredTemplates.filter { $0.linkedApps.contains { $0.matches(appFilter) } }
        return sortTemplates(linked)
    }

    var generalTemplates: [PromptTemplate] {
        guard let appFilter = activeAppFilter else {
            return sortTemplates(filteredTemplates)
        }

        let general = filteredTemplates.filter { !$0.linkedApps.contains { $0.matches(appFilter) } }
        return sortTemplates(general)
    }

    var nextSortOrder: Int {
        (allTemplates.map { $0.sortOrder }.max() ?? 0) + 1
    }

    func saveNewOrUpdated(_ template: PromptTemplate) {
        if let index = allTemplates.firstIndex(where: { $0.id == template.id }) {
            allTemplates[index] = template
        } else {
            allTemplates.append(template)
        }
        persist()
    }

    func deleteTemplate(_ template: PromptTemplate) {
        allTemplates.removeAll { $0.id == template.id }
        persist()
    }

    // MARK: - Group Management

    func addGroup(_ group: PromptTemplateGroup) {
        allGroups.append(group)
        repository.addGroup(group)
        allGroups = repository.loadGroups()
    }

    func updateGroup(_ group: PromptTemplateGroup) {
        if let index = allGroups.firstIndex(where: { $0.id == group.id }) {
            allGroups[index] = group
        }
        repository.updateGroup(group)
        allGroups = repository.loadGroups()
    }

    func deleteGroup(_ groupId: UUID) {
        allGroups.removeAll { $0.id == groupId }
        repository.deleteGroup(groupId)
        allTemplates = repository.loadTemplates()
    }

    func moveTemplateToGroup(templateId: UUID, groupId: UUID?) {
        if let index = allTemplates.firstIndex(where: { $0.id == templateId }) {
            allTemplates[index].groupId = groupId
        }
        repository.moveTemplateToGroup(templateId: templateId, groupId: groupId)
        allTemplates = repository.loadTemplates()
    }

    var nextGroupSortOrder: Int {
        (allGroups.map { $0.sortOrder }.max() ?? 0) + 1
    }

    /// Returns sorted templates matching a search term, without filtering by the current app.
    func templatesForManagement(searchText: String) -> [PromptTemplate] {
        let searchTerm = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

        let appFiltered = applyAppFilter(to: allTemplates)

        let searched = appFiltered.filter { template in
            guard !searchTerm.isEmpty else { return true }
            let inTitle = template.title.lowercased().contains(searchTerm)
            let inTags = template.tags.map { $0.lowercased() }.contains { $0.contains(searchTerm) }
            return inTitle || inTags
        }

        return sortTemplates(searched)
    }

    func recordRecentSearch(_ term: String) {
        let trimmed = term.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        var updated = recentSearches.filter { $0.caseInsensitiveCompare(trimmed) != .orderedSame }
        updated.insert(trimmed, at: 0)
        if updated.count > 5 {
            updated = Array(updated.prefix(5))
        }
        recentSearches = updated
        UserDefaults.standard.set(updated, forKey: Self.recentSearchesKey)
    }

    func clearRecentSearches() {
        recentSearches = []
        UserDefaults.standard.removeObject(forKey: Self.recentSearchesKey)
    }

    private func persist() {
        repository.saveTemplates(allTemplates)
    }

    private var currentPromptAppTarget: PromptAppTarget? {
        if let trackedApp = currentTrackedApp {
            return .tracked(trackedApp)
        }

        if let appName = currentAppName {
            return .custom(name: appName, bundleIdentifier: currentBundleIdentifier)
        }

        if let bundleIdentifier = currentBundleIdentifier {
            return .custom(name: bundleIdentifier, bundleIdentifier: bundleIdentifier)
        }

        return nil
    }

    private func observeSearchText() {
        $searchText
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .removeDuplicates()
            .debounce(for: .milliseconds(400), scheduler: RunLoop.main)
            .sink { [weak self] term in
                self?.recordRecentSearch(term)
            }
            .store(in: &cancellables)
    }

    private var activeAppFilter: PromptAppFilter? {
        guard currentTrackedApp != nil || currentBundleIdentifier != nil || currentAppName != nil else { return nil }
        return PromptAppFilter(
            trackedApp: currentTrackedApp,
            bundleIdentifier: currentBundleIdentifier,
            displayName: currentAppName
        )
    }

    private func applyAppFilter(to templates: [PromptTemplate]) -> [PromptTemplate] {
        guard let appFilter = activeAppFilter else { return templates }
        return templates.filter { template in
            template.linkedApps.isEmpty || template.linkedApps.contains { $0.matches(appFilter) }
        }
    }

    private func sortTemplates(_ templates: [PromptTemplate]) -> [PromptTemplate] {
        templates.sorted {
            if $0.sortOrder == $1.sortOrder {
                return $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending
            }
            return $0.sortOrder < $1.sortOrder
        }
    }
}
