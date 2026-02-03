//
//  PromptList.swift
//  Promptist
//
//  Scrollable prompt list with keyboard navigation support
//

import SwiftUI

struct PromptList: View {
    @ObservedObject var viewModel: PromptLauncherViewModel
    let onExecute: (PromptTemplate) -> Void

    @EnvironmentObject private var languageSettings: LanguageSettings
    @Namespace private var promptListNamespace

    var body: some View {
        ScrollViewReader { scrollProxy in
            ScrollView(.vertical, showsIndicators: true) {
                if viewModel.allDisplayablePrompts.isEmpty && viewModel.collectionsWithPrompts.isEmpty {
                    emptyStateView
                } else {
                    LazyVStack(spacing: 4) {
                        // Show back button if in a collection
                        if viewModel.currentCollectionId != nil {
                            backToAllPromptsButton
                        }

                        // Show collections if not in a collection and not searching
                        if viewModel.currentCollectionId == nil && !viewModel.isSearching {
                            ForEach(viewModel.collectionsWithPrompts) { collection in
                                CollectionRow(
                                    collection: collection,
                                    promptCount: viewModel.allPrompts.filter { $0.collectionId == collection.id }.count,
                                    onTap: {
                                        viewModel.enterCollection(collection.id)
                                    }
                                )
                            }
                        }

                        // MARK: - Sections (only when not searching)
                        if !viewModel.isSearching {
                            // Recent section
                            if !viewModel.recentPrompts.isEmpty {
                                SectionHeader(title: L("launcher.section.recent"))
                                ForEach(viewModel.recentPrompts) { prompt in
                                    promptRow(for: prompt)
                                }
                            }

                            // Frequent section
                            if !viewModel.frequentPrompts.isEmpty {
                                SectionHeader(title: L("launcher.section.frequent"))
                                ForEach(viewModel.frequentPrompts) { prompt in
                                    promptRow(for: prompt)
                                }
                            }

                            // All section header (only if there are section items)
                            if !viewModel.recentPrompts.isEmpty || !viewModel.frequentPrompts.isEmpty {
                                if !viewModel.mainPrompts.isEmpty {
                                    SectionHeader(title: L("launcher.section.all"))
                                }
                            }
                        }

                        // Main prompts
                        ForEach(viewModel.mainPrompts) { prompt in
                            promptRow(for: prompt)
                        }

                        // Show "View other prompts" button if showing app-specific prompts
                        if !viewModel.showingAllPrompts && viewModel.hasAppSpecificPrompts && viewModel.currentCollectionId == nil {
                            showOtherPromptsButton
                        }
                    }
                    .padding(.horizontal, 8)
                }
            }
            .onChange(of: viewModel.selectedIndex) { _, _ in
                // Auto-scroll to selected item
                scrollToSelected(scrollProxy: scrollProxy)
            }
            .onChange(of: viewModel.searchText) { _, _ in
                // Reset scroll when search changes
                scrollToSelected(scrollProxy: scrollProxy, animated: false)
            }
        }
    }

    // MARK: - Prompt Row Helper

    @ViewBuilder
    private func promptRow(for prompt: PromptTemplate) -> some View {
        PromptRow(
            prompt: prompt,
            isSelected: viewModel.isSelected(promptId: prompt.id),
            shortcut: viewModel.shortcut(for: prompt.id),
            onExecute: {
                onExecute(prompt)
            },
            onHover: { isHovered in
                viewModel.hoveredPromptId = isHovered ? prompt.id : nil
            }
        )
        .id(prompt.id)
    }

    // MARK: - Localization Helper

    private func L(_ key: String) -> String {
        languageSettings.localized(key)
    }

    // MARK: - Back Button

    private var backToAllPromptsButton: some View {
        Button(action: {
            viewModel.exitCollection()
        }) {
            HStack(spacing: 8) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 12, weight: .semibold))
                Text(viewModel.currentCollection?.name ?? L("launcher.back"))
                    .font(.system(size: 14, weight: .semibold))
                Spacer()
            }
            .foregroundStyle(.accent)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
        }
        .buttonStyle(.plain)
        .glassInteractiveRow(isHovered: true, cornerRadius: 8)
    }

    // MARK: - Show Other Prompts Button

    private var showOtherPromptsButton: some View {
        Button(action: {
            viewModel.toggleShowAllPrompts()
        }) {
            HStack(spacing: 6) {
                Image(systemName: "ellipsis.circle")
                    .font(.system(size: 13, weight: .medium))
                Text(L("launcher.show_other_prompts"))
                    .font(.system(size: 13, weight: .medium))
            }
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                Capsule()
                    .fill(Color.primary.opacity(0.06))
            )
        }
        .buttonStyle(.plain)
        .padding(.vertical, 8)
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 32, weight: .light))
                .foregroundStyle(.tertiary)
                .glassCircleBackground(size: 64)

            Text(emptyStateMessage)
                .font(.system(size: 13))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(40)
    }

    private var emptyStateMessage: String {
        if viewModel.searchText.isEmpty {
            return L("launcher.empty.no_prompts")
        } else {
            return String(format: L("launcher.empty.no_matches"), viewModel.searchText)
        }
    }

    // MARK: - Scroll Helper

    private func scrollToSelected(scrollProxy: ScrollViewProxy, animated: Bool = true) {
        guard let selectedPrompt = viewModel.selectedPrompt else { return }

        if animated {
            withAnimation(.easeInOut(duration: 0.2)) {
                scrollProxy.scrollTo(selectedPrompt.id, anchor: .center)
            }
        } else {
            scrollProxy.scrollTo(selectedPrompt.id, anchor: .center)
        }
    }
}

// MARK: - Section Header

private struct SectionHeader: View {
    let title: String

    var body: some View {
        HStack {
            Text(title)
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(.secondary)
            Spacer()
        }
        .padding(.horizontal, 8)
        .padding(.top, 16)
        .padding(.bottom, 8)
    }
}

// MARK: - Preview

#Preview {
    struct PreviewWrapper: View {
        @StateObject private var viewModel: PromptLauncherViewModel

        init() {
            // Create mock repository with sample prompts
            let mockRepo = MockPromptRepository(prompts: [
                PromptTemplate(
                    id: UUID(),
                    title: "Code Review",
                    content: "Please review this code for best practices and potential issues.",
                    keywords: ["dev", "review"],
                    linkedApps: [],
                    sortOrder: 0
                ),
                PromptTemplate(
                    id: UUID(),
                    title: "Debug This",
                    content: "Help me debug this issue I'm experiencing with...",
                    keywords: ["debug", "help"],
                    linkedApps: [],
                    sortOrder: 1
                ),
                PromptTemplate(
                    id: UUID(),
                    title: "Explain Code",
                    content: "Explain how this code works in simple terms.",
                    keywords: ["learning", "explain"],
                    linkedApps: [],
                    sortOrder: 2
                ),
                PromptTemplate(
                    id: UUID(),
                    title: "Write Tests",
                    content: "Write comprehensive unit tests for this function.",
                    keywords: ["testing", "dev"],
                    linkedApps: [],
                    sortOrder: 3
                ),
                PromptTemplate(
                    id: UUID(),
                    title: "Refactor",
                    content: "Suggest refactoring improvements for better code quality.",
                    keywords: ["refactor", "cleanup"],
                    linkedApps: [],
                    sortOrder: 4
                )
            ])

            _viewModel = StateObject(wrappedValue: PromptLauncherViewModel(
                repository: mockRepo,
                appContext: AppContextService()
            ))
        }

        var body: some View {
            VStack(spacing: 0) {
                PromptList(
                    viewModel: viewModel,
                    onExecute: { prompt in
                        print("Execute: \(prompt.title)")
                    }
                )
            }
            .frame(width: 540, height: 400)
            .background(Color(nsColor: .windowBackgroundColor))
        }
    }

    return PreviewWrapper()
}

// MARK: - Mock Repository

private class MockPromptRepository: PromptTemplateRepository {
    private var prompts: [PromptTemplate]
    private var collections: [PromptTemplateCollection] = []

    init(prompts: [PromptTemplate]) {
        self.prompts = prompts
    }

    func loadTemplates() -> [PromptTemplate] {
        prompts
    }

    func saveTemplates(_ templates: [PromptTemplate]) {
        self.prompts = templates
    }

    func deleteTemplate(_ templateId: UUID) {
        prompts.removeAll { $0.id == templateId }
    }

    func deleteTemplates(_ templateIds: [UUID]) {
        prompts.removeAll { templateIds.contains($0.id) }
    }

    func incrementUsageCount(for templateId: UUID) {
        if let index = prompts.firstIndex(where: { $0.id == templateId }) {
            prompts[index].usageCount += 1
        }
    }

    func updateTemplateSortOrder(templateId: UUID, newSortOrder: Int) {
        if let index = prompts.firstIndex(where: { $0.id == templateId }) {
            prompts[index].sortOrder = newSortOrder
        }
    }

    func reorderTemplates(_ templateIds: [UUID]) {
        for (newOrder, templateId) in templateIds.enumerated() {
            if let index = prompts.firstIndex(where: { $0.id == templateId }) {
                prompts[index].sortOrder = newOrder
            }
        }
    }

    func loadCollections() -> [PromptTemplateCollection] {
        collections
    }

    func saveCollections(_ collections: [PromptTemplateCollection]) {
        self.collections = collections
    }

    func addCollection(_ collection: PromptTemplateCollection) {
        collections.append(collection)
    }

    func updateCollection(_ collection: PromptTemplateCollection) {
        if let index = collections.firstIndex(where: { $0.id == collection.id }) {
            collections[index] = collection
        }
    }

    func deleteCollection(_ collectionId: UUID) {
        collections.removeAll { $0.id == collectionId }
    }

    func moveTemplateToCollection(templateId: UUID, collectionId: UUID?) {
        if let index = prompts.firstIndex(where: { $0.id == templateId }) {
            prompts[index].collectionId = collectionId
        }
    }

    func reorderCollections(_ collectionIds: [UUID]) {
        for (newOrder, collectionId) in collectionIds.enumerated() {
            if let index = collections.firstIndex(where: { $0.id == collectionId }) {
                collections[index].sortOrder = newOrder
            }
        }
    }

    // MARK: - Category Methods (stub implementations for mock)
    func loadCategories() -> [PromptCategory] { [] }
    func saveCategories(_ categories: [PromptCategory]) {}
    func addCategory(_ category: PromptCategory) {}
    func updateCategory(_ category: PromptCategory) {}
    func deleteCategory(_ categoryId: UUID) {}
    func moveTemplateToCategory(templateId: UUID, categoryId: UUID?) {}
    func reorderCategories(_ categoryIds: [UUID]) {}
    func generalQACategoryId() -> UUID? { nil }
    func migrateToV2IfNeeded() {}
}
