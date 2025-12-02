//
//  PromptList.swift
//  ai-prompter
//
//  Scrollable prompt list with keyboard navigation support
//

import SwiftUI

struct PromptList: View {
    @ObservedObject var viewModel: PromptLauncherViewModel
    let onExecute: (PromptTemplate) -> Void

    @Namespace private var promptListNamespace

    private let tokens = LauncherDesignTokens.self

    var body: some View {
        ScrollViewReader { scrollProxy in
            ScrollView(.vertical, showsIndicators: true) {
                if viewModel.filteredPrompts.isEmpty && viewModel.groupsWithPrompts.isEmpty {
                    emptyStateView
                } else {
                    LazyVStack(spacing: 0) {
                        // Show back button if in a group
                        if viewModel.currentGroupId != nil {
                            backToAllPromptsButton
                        }

                        // Show groups if not in a group and not searching
                        if viewModel.currentGroupId == nil && viewModel.searchText.isEmpty {
                            ForEach(viewModel.groupsWithPrompts) { group in
                                GroupRow(
                                    group: group,
                                    promptCount: viewModel.allPrompts.filter { $0.groupId == group.id }.count,
                                    onTap: {
                                        viewModel.enterGroup(group.id)
                                    }
                                )
                            }
                        }

                        // Show prompts
                        ForEach(Array(viewModel.filteredPrompts.enumerated()), id: \.element.id) { index, prompt in
                            PromptRow(
                                prompt: prompt,
                                isSelected: viewModel.isSelected(promptId: prompt.id),
                                onExecute: {
                                    onExecute(prompt)
                                }
                            )
                            .id(prompt.id)
                        }

                        // Show "View other prompts" button if showing app-specific prompts
                        if !viewModel.showingAllPrompts && viewModel.hasAppSpecificPrompts && viewModel.currentGroupId == nil {
                            showOtherPromptsButton
                        }
                    }
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

    // MARK: - Back Button

    private var backToAllPromptsButton: some View {
        Button(action: {
            viewModel.exitGroup()
        }) {
            HStack(spacing: 8) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 12, weight: .semibold))
                Text(viewModel.currentGroup?.name ?? "Back")
                    .font(.system(size: 14, weight: .semibold))
                Spacer()
            }
            .foregroundColor(tokens.Colors.accent)
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
        }
        .buttonStyle(.plain)
        .background(tokens.Colors.rowHover.opacity(0.3))
    }

    // MARK: - Show Other Prompts Button

    private var showOtherPromptsButton: some View {
        Button(action: {
            viewModel.toggleShowAllPrompts()
        }) {
            HStack(spacing: 6) {
                Image(systemName: "ellipsis.circle")
                    .font(.system(size: 13, weight: .medium))
                Text("다른 프롬프트 보기")
                    .font(.system(size: 13, weight: .medium))
            }
            .foregroundColor(tokens.Colors.secondaryText)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(tokens.Colors.rowHover)
            )
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 8)
        .padding(.vertical, 8)
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 32, weight: .light))
                .foregroundColor(tokens.Colors.tertiaryText)

            Text(emptyStateMessage)
                .font(tokens.Typography.emptyStateFont)
                .foregroundColor(tokens.Colors.secondaryText)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(40)
    }

    private var emptyStateMessage: String {
        if viewModel.searchText.isEmpty {
            return "No prompts yet.\nCreate your first prompt to get started."
        } else {
            return "No prompts match \"\(viewModel.searchText)\""
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
                    tags: ["dev", "review"],
                    linkedApps: [],
                    sortOrder: 0
                ),
                PromptTemplate(
                    id: UUID(),
                    title: "Debug This",
                    content: "Help me debug this issue I'm experiencing with...",
                    tags: ["debug", "help"],
                    linkedApps: [],
                    sortOrder: 1
                ),
                PromptTemplate(
                    id: UUID(),
                    title: "Explain Code",
                    content: "Explain how this code works in simple terms.",
                    tags: ["learning", "explain"],
                    linkedApps: [],
                    sortOrder: 2
                ),
                PromptTemplate(
                    id: UUID(),
                    title: "Write Tests",
                    content: "Write comprehensive unit tests for this function.",
                    tags: ["testing", "dev"],
                    linkedApps: [],
                    sortOrder: 3
                ),
                PromptTemplate(
                    id: UUID(),
                    title: "Refactor",
                    content: "Suggest refactoring improvements for better code quality.",
                    tags: ["refactor", "cleanup"],
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
    private var groups: [PromptTemplateGroup] = []

    init(prompts: [PromptTemplate]) {
        self.prompts = prompts
    }

    func loadTemplates() -> [PromptTemplate] {
        prompts
    }

    func saveTemplates(_ templates: [PromptTemplate]) {
        self.prompts = templates
    }

    func incrementUsageCount(for templateId: UUID) {
        if let index = prompts.firstIndex(where: { $0.id == templateId }) {
            prompts[index].usageCount += 1
        }
    }

    func loadGroups() -> [PromptTemplateGroup] {
        groups
    }

    func saveGroups(_ groups: [PromptTemplateGroup]) {
        self.groups = groups
    }

    func addGroup(_ group: PromptTemplateGroup) {
        groups.append(group)
    }

    func updateGroup(_ group: PromptTemplateGroup) {
        if let index = groups.firstIndex(where: { $0.id == group.id }) {
            groups[index] = group
        }
    }

    func deleteGroup(_ groupId: UUID) {
        groups.removeAll { $0.id == groupId }
    }

    func moveTemplateToGroup(templateId: UUID, groupId: UUID?) {
        if let index = prompts.firstIndex(where: { $0.id == templateId }) {
            prompts[index].groupId = groupId
        }
    }
}
