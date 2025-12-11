//
//  PromptLauncherViewModel.swift
//  Promptist
//
//  Minimal ViewModel for fast prompt launcher with keyboard navigation.
//  Uses 2-axis filter: App Filter (auto) → Collection Filter → Search
//  Note: Category filter is NOT used in Launcher for UX simplicity.
//

import SwiftUI
import Combine

@MainActor
final class PromptLauncherViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var searchText: String = ""
    @Published var selectedIndex: Int = 0
    @Published private(set) var allPrompts: [PromptTemplate] = []
    @Published private(set) var allCollections: [PromptTemplateCollection] = []
    @Published var showingAllPrompts: Bool = false
    @Published var currentCollectionId: UUID? = nil
    @Published var isShowingCollectionSubmenu: Bool = false
    @Published var hoveredPromptId: UUID? = nil

    // MARK: - Dependencies
    private let repository: PromptTemplateRepository
    private let appContext: AppContextService
    private let shortcutStore: ShortcutStore
    private let launcherSettings: LauncherSettings
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Shortcuts Cache
    private var shortcutsMap: [UUID: TemplateShortcut] = [:]

    // MARK: - Computed Properties

    /// Get prompts for the current app
    private var appSpecificPrompts: [PromptTemplate] {
        guard let currentApp = appContext.currentTrackedApp else {
            return []
        }

        let filter = PromptAppFilter(
            trackedApp: currentApp,
            bundleIdentifier: appContext.frontmostBundleIdentifier,
            displayName: appContext.frontmostAppName
        )

        return allPrompts.filter { prompt in
            prompt.linkedApps.contains { $0.matches(filter) }
        }
    }

    /// Has app-specific prompts for the current app
    var hasAppSpecificPrompts: Bool {
        !appSpecificPrompts.isEmpty
    }

    /// Get collections that have prompts
    var collectionsWithPrompts: [PromptTemplateCollection] {
        allCollections.filter { collection in
            allPrompts.contains { $0.collectionId == collection.id }
        }
    }

    /// Get prompts without a collection
    var uncollectedPrompts: [PromptTemplate] {
        allPrompts.filter { $0.collectionId == nil }
    }

    /// Filtered prompts based on search text and app context
    /// Filter priority: App Filter (1st) → Collection Filter (2nd) → Search (3rd)
    var filteredPrompts: [PromptTemplate] {
        var basePrompts: [PromptTemplate]

        // 1st: App Filter - determine base prompt set
        if showingAllPrompts || !hasAppSpecificPrompts {
            // Show all prompts
            basePrompts = allPrompts
        } else {
            // Show app-specific prompts (all of them, regardless of collection)
            basePrompts = appSpecificPrompts
        }

        // 2nd: Collection Filter - if a collection is selected, filter to that collection
        if let collectionId = currentCollectionId {
            basePrompts = basePrompts.filter { $0.collectionId == collectionId }
        }

        guard !searchText.isEmpty else {
            return basePrompts
        }

        let query = searchText.lowercased()

        return basePrompts.filter { prompt in
            // Match title
            if prompt.title.lowercased().contains(query) {
                return true
            }

            // Fuzzy match title (e.g., "fb" matches "FooBar")
            if fuzzyMatch(query: query, text: prompt.title.lowercased()) {
                return true
            }

            // Match keywords (metadata for search)
            if prompt.keywords.contains(where: { $0.lowercased().contains(query) }) {
                return true
            }

            // Match content
            if prompt.content.lowercased().contains(query) {
                return true
            }

            return false
        }
    }

    /// Total count of filtered prompts
    var promptCount: Int {
        filteredPrompts.count
    }

    /// Currently selected prompt (safe access)
    var selectedPrompt: PromptTemplate? {
        guard selectedIndex >= 0 && selectedIndex < filteredPrompts.count else {
            return nil
        }
        return filteredPrompts[selectedIndex]
    }

    // MARK: - Section Properties

    /// Whether user is currently searching
    var isSearching: Bool {
        !searchText.trimmingCharacters(in: .whitespaces).isEmpty
    }

    /// Recent prompts (sorted by lastUsedAt, limited by settings)
    var recentPrompts: [PromptTemplate] {
        guard !isSearching, launcherSettings.showRecentSection else { return [] }
        return allPrompts
            .filter { $0.lastUsedAt != nil }
            .sorted { ($0.lastUsedAt ?? .distantPast) > ($1.lastUsedAt ?? .distantPast) }
            .prefix(launcherSettings.recentSectionCount)
            .map { $0 }
    }

    /// Frequently used prompts (usage >= 3, excluding those already in recent)
    var frequentPrompts: [PromptTemplate] {
        guard !isSearching, launcherSettings.showFrequentSection else { return [] }
        let recentIds = Set(recentPrompts.map { $0.id })
        return allPrompts
            .filter { $0.usageCount >= 3 && !recentIds.contains($0.id) }
            .sorted { $0.usageCount > $1.usageCount }
            .prefix(5)
            .map { $0 }
    }

    /// Main prompts list (excluding section items when not searching)
    var mainPrompts: [PromptTemplate] {
        let sectionIds = Set(recentPrompts.map { $0.id } + frequentPrompts.map { $0.id })
        let basePrompts = isSearching ? filteredPrompts : filteredPrompts.filter { !sectionIds.contains($0.id) }

        if launcherSettings.autoSortByUsage {
            return basePrompts.sorted { $0.usageCount > $1.usageCount }
        } else {
            return basePrompts.sorted { $0.sortOrder < $1.sortOrder }
        }
    }

    /// All displayable prompts in order (for keyboard navigation)
    var allDisplayablePrompts: [PromptTemplate] {
        if isSearching {
            return mainPrompts
        }
        return recentPrompts + frequentPrompts + mainPrompts
    }

    /// Total count for keyboard navigation
    var totalDisplayableCount: Int {
        allDisplayablePrompts.count
    }

    // MARK: - Shortcut Access

    /// Get shortcut for a template
    func shortcut(for templateId: UUID) -> TemplateShortcut? {
        shortcutsMap[templateId]
    }

    // MARK: - Preview Support

    /// Currently hovered or selected prompt for preview
    var previewPrompt: PromptTemplate? {
        // Prefer hovered, fallback to selected
        if let hoveredId = hoveredPromptId {
            return allPrompts.first { $0.id == hoveredId }
        }
        return selectedPrompt
    }

    /// Shortcut for the preview prompt
    var previewShortcut: TemplateShortcut? {
        guard let promptId = previewPrompt?.id else { return nil }
        return shortcut(for: promptId)
    }

    // MARK: - Initialization

    init(
        repository: PromptTemplateRepository,
        appContext: AppContextService,
        shortcutStore: ShortcutStore = FileShortcutStore(),
        launcherSettings: LauncherSettings = .shared
    ) {
        self.repository = repository
        self.appContext = appContext
        self.shortcutStore = shortcutStore
        self.launcherSettings = launcherSettings

        loadPrompts()
        loadShortcuts()
        observeSearchText()
    }

    // MARK: - Data Loading

    func loadPrompts() {
        allPrompts = repository.loadTemplates()
            .sorted { $0.usageCount > $1.usageCount }
        allCollections = repository.loadCollections()
            .sorted { $0.sortOrder < $1.sortOrder }
    }

    func loadShortcuts() {
        let shortcuts = shortcutStore.loadShortcuts()
        shortcutsMap = Dictionary(uniqueKeysWithValues: shortcuts.map { ($0.templateId, $0) })
    }

    func refresh() {
        loadPrompts()
        loadShortcuts()
        resetSelection()
        showingAllPrompts = false
        currentCollectionId = nil
        isShowingCollectionSubmenu = false
    }

    func toggleShowAllPrompts() {
        showingAllPrompts.toggle()
        resetSelection()
    }

    // MARK: - Collection Navigation

    func enterCollection(_ collectionId: UUID) {
        currentCollectionId = collectionId
        isShowingCollectionSubmenu = false
        resetSelection()
    }

    func exitCollection() {
        currentCollectionId = nil
        resetSelection()
    }

    func toggleCollectionSubmenu() {
        isShowingCollectionSubmenu.toggle()
    }

    var currentCollection: PromptTemplateCollection? {
        guard let collectionId = currentCollectionId else { return nil }
        return allCollections.first { $0.id == collectionId }
    }

    // MARK: - Search

    private func observeSearchText() {
        $searchText
            .removeDuplicates()
            .sink { [weak self] _ in
                self?.resetSelection()
            }
            .store(in: &cancellables)
    }

    func clearSearch() {
        searchText = ""
    }

    // MARK: - Keyboard Navigation

    func moveSelectionUp() {
        guard promptCount > 0 else { return }
        selectedIndex = max(0, selectedIndex - 1)
    }

    func moveSelectionDown() {
        guard promptCount > 0 else { return }
        selectedIndex = min(promptCount - 1, selectedIndex + 1)
    }

    func resetSelection() {
        selectedIndex = 0
    }

    func selectPrompt(at index: Int) {
        guard index >= 0 && index < promptCount else { return }
        selectedIndex = index
    }

    // MARK: - Prompt Execution

    /// Execute the currently selected prompt
    func executeSelected() -> PromptTemplate? {
        guard let prompt = selectedPrompt else { return nil }
        return prompt
    }

    /// Execute a specific prompt by ID
    func execute(promptId: UUID) -> PromptTemplate? {
        return filteredPrompts.first(where: { $0.id == promptId })
    }

    /// Increment usage count for a prompt
    func incrementUsageCount(for promptId: UUID) {
        repository.incrementUsageCount(for: promptId)
        loadPrompts()
    }

    // MARK: - Fuzzy Matching

    /// Simple fuzzy matching algorithm
    /// Example: "fb" matches "FooBar", "fzymtch" matches "fuzzy match"
    private func fuzzyMatch(query: String, text: String) -> Bool {
        guard !query.isEmpty else { return false }

        var queryIndex = query.startIndex
        let queryEnd = query.endIndex

        for char in text {
            if queryIndex == queryEnd {
                return true
            }

            if char == query[queryIndex] {
                queryIndex = query.index(after: queryIndex)
            }
        }

        return queryIndex == queryEnd
    }

    // MARK: - Helpers

    func isSelected(promptId: UUID) -> Bool {
        selectedPrompt?.id == promptId
    }

    func index(of promptId: UUID) -> Int? {
        filteredPrompts.firstIndex(where: { $0.id == promptId })
    }
}
