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
                if viewModel.filteredPrompts.isEmpty {
                    emptyStateView
                } else {
                    LazyVStack(spacing: tokens.Layout.rowSpacing) {
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
                    }
                    .padding(.horizontal, tokens.Layout.searchPadding)
                    .padding(.bottom, tokens.Layout.searchPadding)
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

    init(prompts: [PromptTemplate]) {
        self.prompts = prompts
    }

    func loadTemplates() -> [PromptTemplate] {
        prompts
    }

    func saveTemplates(_ templates: [PromptTemplate]) {
        self.prompts = templates
    }
}
