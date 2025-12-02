//
//  PromptLauncherViewModel.swift
//  ai-prompter
//
//  Minimal ViewModel for fast prompt launcher with keyboard navigation
//

import SwiftUI
import Combine

@MainActor
final class PromptLauncherViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var searchText: String = ""
    @Published var selectedIndex: Int = 0
    @Published private(set) var allPrompts: [PromptTemplate] = []
    @Published private(set) var allGroups: [PromptTemplateGroup] = []
    @Published var showingAllPrompts: Bool = false
    @Published var currentGroupId: UUID? = nil
    @Published var isShowingGroupSubmenu: Bool = false

    // MARK: - Dependencies
    private let repository: PromptTemplateRepository
    private let appContext: AppContextService
    private var cancellables = Set<AnyCancellable>()

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

    /// Get groups that have prompts
    var groupsWithPrompts: [PromptTemplateGroup] {
        allGroups.filter { group in
            allPrompts.contains { $0.groupId == group.id }
        }
    }

    /// Get prompts without a group
    var ungroupedPrompts: [PromptTemplate] {
        allPrompts.filter { $0.groupId == nil }
    }

    /// Filtered prompts based on search text and app context
    var filteredPrompts: [PromptTemplate] {
        let basePrompts: [PromptTemplate]

        // If browsing a specific group, show only that group's prompts
        if let groupId = currentGroupId {
            basePrompts = allPrompts.filter { $0.groupId == groupId }
        } else if showingAllPrompts || !hasAppSpecificPrompts {
            // Show all prompts (ungrouped only if not in a group)
            basePrompts = ungroupedPrompts
        } else {
            // Show app-specific prompts (ungrouped only)
            basePrompts = appSpecificPrompts.filter { $0.groupId == nil }
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

            // Match tags
            if prompt.tags.contains(where: { $0.lowercased().contains(query) }) {
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

    // MARK: - Initialization

    init(
        repository: PromptTemplateRepository,
        appContext: AppContextService
    ) {
        self.repository = repository
        self.appContext = appContext

        loadPrompts()
        observeSearchText()
    }

    // MARK: - Data Loading

    func loadPrompts() {
        allPrompts = repository.loadTemplates()
            .sorted { $0.usageCount > $1.usageCount }
        allGroups = repository.loadGroups()
            .sorted { $0.sortOrder < $1.sortOrder }
    }

    func refresh() {
        loadPrompts()
        resetSelection()
        showingAllPrompts = false
        currentGroupId = nil
        isShowingGroupSubmenu = false
    }

    func toggleShowAllPrompts() {
        showingAllPrompts.toggle()
        resetSelection()
    }

    // MARK: - Group Navigation

    func enterGroup(_ groupId: UUID) {
        currentGroupId = groupId
        isShowingGroupSubmenu = false
        resetSelection()
    }

    func exitGroup() {
        currentGroupId = nil
        resetSelection()
    }

    func toggleGroupSubmenu() {
        isShowingGroupSubmenu.toggle()
    }

    var currentGroup: PromptTemplateGroup? {
        guard let groupId = currentGroupId else { return nil }
        return allGroups.first { $0.id == groupId }
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
