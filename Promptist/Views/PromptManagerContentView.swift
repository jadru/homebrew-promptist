import SwiftUI
import Combine
import AppKit
import UniformTypeIdentifiers

/// Content view for the Template Manager tab with 3-axis filter layout.
/// Layout: TopFilterBar | CategorySidebar | CollectionRail + TemplateList
struct PromptManagerContentView: View {
    enum PresentationStyle {
        case window
        case floatingPanel
    }

    @EnvironmentObject private var languageSettings: LanguageSettings
    @ObservedObject var viewModel: PromptListViewModel
    @ObservedObject var shortcutViewModel: ShortcutManagerViewModel
    var presentationStyle: PresentationStyle = .window
    let onNavigateToShortcut: (UUID) -> Void

    @State private var isPresentingEditor = false
    @State private var editorMode: PromptEditorView.Mode = .create(nextSortOrder: 1, presetApps: [], categoryId: nil)
    @State private var templatePendingDeletion: PromptTemplate?
    @State private var showDeleteConfirmation = false
    @State private var showCollectionEditor = false
    @State private var editingCollectionName = ""
    @State private var editingCollectionId: UUID?

    var body: some View {
        VStack(spacing: 0) {
            // Top bar with search and app filter
            TopFilterBar(viewModel: viewModel, onNewPrompt: presentCreateEditor)

            Divider()

            // Main content with sidebar
            HStack(spacing: 0) {
                // Left: Category Sidebar
                CategorySidebar(viewModel: viewModel)

                Divider()

                // Right: Collection Rail + Template List
                VStack(spacing: 0) {
                    // Collection Rail
                    CollectionRail(viewModel: viewModel)

                    Divider()

                    // Template List
                    TemplateListView(
                        templates: viewModel.filteredTemplates,
                        viewModel: viewModel,
                        onEdit: presentEditEditor,
                        onDelete: confirmDelete
                    )
                }
            }
        }
        .background(DesignTokens.Colors.backgroundPrimary)
        .sheet(isPresented: $isPresentingEditor) {
            PromptEditorView(
                mode: editorMode,
                categories: viewModel.allCategories
            ) { template in
                viewModel.saveNewOrUpdated(template)
                isPresentingEditor = false
            } onCancel: {
                isPresentingEditor = false
            }
        }
        .alert(languageSettings.localized("prompt_manager.delete_alert.title"), isPresented: $showDeleteConfirmation, presenting: templatePendingDeletion) { template in
            Button(languageSettings.localized("prompt_manager.delete_alert.delete"), role: .destructive) {
                viewModel.deleteTemplate(template)
            }
            Button(languageSettings.localized("prompt_manager.delete_alert.cancel"), role: .cancel) { }
        } message: { _ in
            Text(languageSettings.localized("prompt_manager.delete_alert.message"))
        }
        .sheet(isPresented: $showCollectionEditor) {
            CollectionEditorView(
                collectionName: $editingCollectionName,
                isEditing: editingCollectionId != nil,
                onCreate: createOrUpdateCollection,
                onCancel: { showCollectionEditor = false }
            )
            .environmentObject(languageSettings)
        }
        .onAppear {
            if let intent = viewModel.pendingCreationIntent {
                handlePendingCreationIntent(intent)
            }
        }
        .onReceive(viewModel.$pendingCreationIntent.compactMap { $0 }) { intent in
            handlePendingCreationIntent(intent)
        }
    }

    // MARK: - Actions

    private func presentCreateEditor() {
        editorMode = .create(
            nextSortOrder: viewModel.nextSortOrder,
            presetApps: [],
            categoryId: viewModel.filterState.selectedCategoryId
        )
        isPresentingEditor = true
    }

    private func presentEditEditor(for template: PromptTemplate) {
        editorMode = .edit(existing: template)
        isPresentingEditor = true
    }

    private func confirmDelete(template: PromptTemplate) {
        templatePendingDeletion = template
        showDeleteConfirmation = true
    }

    private func handlePendingCreationIntent(_ intent: PromptListViewModel.PromptCreationIntent) {
        editorMode = .create(
            nextSortOrder: viewModel.nextSortOrder,
            presetApps: intent.presetApps,
            categoryId: intent.categoryId ?? viewModel.filterState.selectedCategoryId
        )
        isPresentingEditor = true
        viewModel.pendingCreationIntent = nil
    }

    private func createOrUpdateCollection() {
        guard !editingCollectionName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }

        if let collectionId = editingCollectionId {
            if let collection = viewModel.allCollections.first(where: { $0.id == collectionId }) {
                var updated = collection
                updated.name = editingCollectionName
                viewModel.updateCollection(updated)
            }
        } else {
            let newCollection = PromptTemplateCollection(
                name: editingCollectionName,
                sortOrder: viewModel.nextCollectionSortOrder
            )
            viewModel.addCollection(newCollection)
        }

        showCollectionEditor = false
    }
}

// MARK: - Presentation Style Extension

private extension PromptManagerContentView.PresentationStyle {
    var minWidth: CGFloat {
        switch self {
        case .window:
            return 800
        case .floatingPanel:
            return 600
        }
    }

    var minHeight: CGFloat {
        switch self {
        case .window:
            return 600
        case .floatingPanel:
            return 500
        }
    }
}
