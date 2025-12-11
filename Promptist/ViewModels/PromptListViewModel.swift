import Foundation
import Combine

/// Drives the prompt list, including persistence, filtering, and mutations.
/// Uses a 3-axis filter system: App → Category → Collection → Search
final class PromptListViewModel: ObservableObject {
    struct PromptCreationIntent: Equatable {
        let presetApps: [PromptAppTarget]
        let categoryId: UUID?

        init(presetApps: [PromptAppTarget], categoryId: UUID? = nil) {
            self.presetApps = presetApps
            self.categoryId = categoryId
        }
    }

    // MARK: - Published State

    @Published var allTemplates: [PromptTemplate] = []
    @Published var allCollections: [PromptTemplateCollection] = []
    @Published var allCategories: [PromptCategory] = []
    @Published var filterState = FilterState()

    // App context (from AppContextService)
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
        allCollections = repository.loadCollections()
        allCategories = repository.loadCategories()
        recentSearches = UserDefaults.standard.stringArray(forKey: Self.recentSearchesKey) ?? []

        observeSearchText()
    }

    // MARK: - Convenience for searchText binding

    var searchText: String {
        get { filterState.searchText }
        set { filterState.searchText = newValue }
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
            pendingCreationIntent = PromptCreationIntent(presetApps: [], categoryId: filterState.selectedCategoryId)
            return
        }
        pendingCreationIntent = PromptCreationIntent(presetApps: [app], categoryId: filterState.selectedCategoryId)
    }

    func consumePendingCreationIntent() -> PromptCreationIntent? {
        let intent = pendingCreationIntent
        pendingCreationIntent = nil
        return intent
    }

    // MARK: - 3-Axis Filtered Templates

    /// Returns templates filtered by the 3-axis filter chain:
    /// App Filter → Category Filter → Collection Filter → Search
    var filteredTemplates: [PromptTemplate] {
        var result = allTemplates

        // 1st: Apply App Filter
        result = applyAppFilter(to: result)

        // 2nd: Apply Category Filter
        result = applyCategoryFilter(to: result)

        // 3rd: Apply Collection Filter
        result = applyCollectionFilter(to: result)

        // 4th: Apply Search Filter
        result = applySearchFilter(to: result)

        return sortTemplates(result)
    }

    var linkedTemplatesForCurrentApp: [PromptTemplate] {
        guard let appFilter = detectedAppFilter else { return [] }
        let linked = filteredTemplates.filter { $0.linkedApps.contains { $0.matches(appFilter) } }
        return sortTemplates(linked)
    }

    var generalTemplates: [PromptTemplate] {
        guard let appFilter = detectedAppFilter else {
            return sortTemplates(filteredTemplates)
        }

        let general = filteredTemplates.filter { !$0.linkedApps.contains { $0.matches(appFilter) } }
        return sortTemplates(general)
    }

    // MARK: - Category Helpers

    /// Root (major) categories sorted by sortOrder
    var rootCategories: [PromptCategory] {
        allCategories
            .filter { $0.parentId == nil }
            .sorted { $0.sortOrder < $1.sortOrder }
    }

    /// Child categories of a given parent, sorted by sortOrder
    func childCategories(of parentId: UUID) -> [PromptCategory] {
        allCategories
            .filter { $0.parentId == parentId }
            .sorted { $0.sortOrder < $1.sortOrder }
    }

    /// Get category by ID
    func category(for id: UUID) -> PromptCategory? {
        allCategories.first { $0.id == id }
    }

    /// Get the display path for a category (e.g., "Coding > Code Review")
    func categoryPath(for categoryId: UUID) -> String {
        guard let category = category(for: categoryId) else { return "" }

        if let parentId = category.parentId,
           let parent = self.category(for: parentId) {
            return "\(parent.name) > \(category.name)"
        }

        return category.name
    }

    /// Returns all category IDs including the given category and all its children
    private func categoryIdsIncludingChildren(of categoryId: UUID) -> Set<UUID> {
        var ids: Set<UUID> = [categoryId]
        let children = childCategories(of: categoryId)
        for child in children {
            ids.formUnion(categoryIdsIncludingChildren(of: child.id))
        }
        return ids
    }

    // MARK: - Filter Actions

    /// Select an app filter manually (disables auto-detect)
    func selectApp(_ app: PromptAppFilter?) {
        filterState.selectedApp = app
        filterState.autoDetectedApp = (app == nil)
    }

    /// Toggle auto-detect mode for app filter
    func toggleAutoDetectApp() {
        filterState.autoDetectedApp.toggle()
        if filterState.autoDetectedApp {
            filterState.selectedApp = nil
        }
    }

    /// Select a category filter
    func selectCategory(_ categoryId: UUID?) {
        filterState.selectedCategoryId = categoryId
    }

    /// Select a collection filter
    func selectCollection(_ collectionId: UUID?) {
        filterState.selectedCollectionId = collectionId
    }

    /// Reset all filters
    func resetFilters() {
        filterState.reset()
    }

    /// The currently effective app filter (auto-detected or manually selected)
    var detectedAppFilter: PromptAppFilter? {
        if filterState.autoDetectedApp {
            guard currentTrackedApp != nil || currentBundleIdentifier != nil || currentAppName != nil else { return nil }
            return PromptAppFilter(
                trackedApp: currentTrackedApp,
                bundleIdentifier: currentBundleIdentifier,
                displayName: currentAppName
            )
        } else {
            return filterState.selectedApp
        }
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

    // MARK: - Collection Management

    func addCollection(_ collection: PromptTemplateCollection) {
        allCollections.append(collection)
        repository.addCollection(collection)
        allCollections = repository.loadCollections()
    }

    func updateCollection(_ collection: PromptTemplateCollection) {
        if let index = allCollections.firstIndex(where: { $0.id == collection.id }) {
            allCollections[index] = collection
        }
        repository.updateCollection(collection)
        allCollections = repository.loadCollections()
    }

    func deleteCollection(_ collectionId: UUID) {
        allCollections.removeAll { $0.id == collectionId }
        repository.deleteCollection(collectionId)
        allTemplates = repository.loadTemplates()
    }

    func moveTemplateToCollection(templateId: UUID, collectionId: UUID?) {
        if let index = allTemplates.firstIndex(where: { $0.id == templateId }) {
            allTemplates[index].collectionId = collectionId
        }
        repository.moveTemplateToCollection(templateId: templateId, collectionId: collectionId)
        allTemplates = repository.loadTemplates()
    }

    var nextCollectionSortOrder: Int {
        (allCollections.map { $0.sortOrder }.max() ?? 0) + 1
    }

    func reorderTemplates(_ templateIds: [UUID]) {
        repository.reorderTemplates(templateIds)
        allTemplates = repository.loadTemplates()
    }

    func reorderCollections(_ collectionIds: [UUID]) {
        repository.reorderCollections(collectionIds)
        allCollections = repository.loadCollections()
    }

    // MARK: - Category Management

    func addCategory(_ category: PromptCategory) {
        repository.addCategory(category)
        allCategories = repository.loadCategories()
    }

    func updateCategory(_ category: PromptCategory) {
        repository.updateCategory(category)
        allCategories = repository.loadCategories()
    }

    func deleteCategory(_ categoryId: UUID) {
        repository.deleteCategory(categoryId)
        allCategories = repository.loadCategories()
        allTemplates = repository.loadTemplates()
    }

    func moveTemplateToCategory(templateId: UUID, categoryId: UUID?) {
        if let index = allTemplates.firstIndex(where: { $0.id == templateId }) {
            allTemplates[index].categoryId = categoryId
        }
        repository.moveTemplateToCategory(templateId: templateId, categoryId: categoryId)
        allTemplates = repository.loadTemplates()
    }

    var nextCategorySortOrder: Int {
        (allCategories.map { $0.sortOrder }.max() ?? 0) + 1
    }

    func reorderCategories(_ categoryIds: [UUID]) {
        repository.reorderCategories(categoryIds)
        allCategories = repository.loadCategories()
    }

    /// Returns sorted templates matching a search term, without filtering by the current app.
    /// This is used for the Template Manager view where all templates should be visible.
    func templatesForManagement(searchText: String) -> [PromptTemplate] {
        let searchTerm = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

        guard !searchTerm.isEmpty else {
            return sortTemplates(allTemplates)
        }

        let searched = allTemplates.filter { template in
            let inTitle = template.title.lowercased().contains(searchTerm)
            let inKeywords = template.keywords.contains { $0.lowercased().contains(searchTerm) }
            return inTitle || inKeywords
        }

        return sortTemplates(searched)
    }

    /// Count of templates in a specific category (including children)
    func templateCount(for categoryId: UUID) -> Int {
        let categoryIds = categoryIdsIncludingChildren(of: categoryId)
        return allTemplates.filter { template in
            guard let templateCategoryId = template.categoryId else { return false }
            return categoryIds.contains(templateCategoryId)
        }.count
    }

    /// Count of templates in a specific collection
    func templateCount(forCollection collectionId: UUID) -> Int {
        allTemplates.filter { $0.collectionId == collectionId }.count
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
        $filterState
            .map { $0.searchText.trimmingCharacters(in: .whitespacesAndNewlines) }
            .removeDuplicates()
            .debounce(for: .milliseconds(400), scheduler: RunLoop.main)
            .sink { [weak self] term in
                self?.recordRecentSearch(term)
            }
            .store(in: &cancellables)
    }

    // MARK: - Private Filter Methods

    private func applyAppFilter(to templates: [PromptTemplate]) -> [PromptTemplate] {
        guard let appFilter = detectedAppFilter else { return templates }
        return templates.filter { template in
            // Include if no app restriction OR matches the filter
            template.linkedApps.isEmpty || template.linkedApps.contains { $0.matches(appFilter) }
        }
    }

    private func applyCategoryFilter(to templates: [PromptTemplate]) -> [PromptTemplate] {
        guard let categoryId = filterState.selectedCategoryId else { return templates }

        // Include the selected category and all its children
        let categoryIds = categoryIdsIncludingChildren(of: categoryId)
        return templates.filter { template in
            guard let templateCategoryId = template.categoryId else { return false }
            return categoryIds.contains(templateCategoryId)
        }
    }

    private func applyCollectionFilter(to templates: [PromptTemplate]) -> [PromptTemplate] {
        guard let collectionId = filterState.selectedCollectionId else { return templates }
        return templates.filter { $0.collectionId == collectionId }
    }

    private func applySearchFilter(to templates: [PromptTemplate]) -> [PromptTemplate] {
        let term = filterState.searchText.trimmingCharacters(in: .whitespaces).lowercased()
        guard !term.isEmpty else { return templates }

        return templates.filter { template in
            template.title.lowercased().contains(term) ||
            template.content.lowercased().contains(term) ||
            template.keywords.contains { $0.lowercased().contains(term) }
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
