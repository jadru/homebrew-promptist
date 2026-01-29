import SwiftUI
import Combine
import AppKit
import UniformTypeIdentifiers

struct PromptManagerContentView: View {
    @EnvironmentObject private var languageSettings: LanguageSettings
    @ObservedObject var viewModel: PromptListViewModel
    @ObservedObject var shortcutViewModel: ShortcutManagerViewModel
    let onNavigateToShortcut: (UUID) -> Void

    @State private var isPresentingEditor = false
    @State private var editorMode: PromptEditorView.Mode = .create(nextSortOrder: 1, presetApps: [], categoryId: nil)
    @State private var templatePendingDeletion: PromptTemplate?
    @State private var showDeleteConfirmation = false
    @State private var showCollectionEditor = false
    @State private var editingCollectionName = ""
    @State private var editingCollectionId: UUID?

    var body: some View {
        List {
            ForEach(viewModel.filteredTemplates) { template in
                TemplateListRow(
                    template: template,
                    categoryPath: viewModel.categoryPath(for: template.categoryId ?? UUID()),
                    onEdit: { presentEditEditor(for: template) },
                    onDelete: { confirmDelete(template: template) }
                )
            }
        }
        .listStyle(.inset(alternatesRowBackgrounds: true))
        .searchable(
            text: $viewModel.filterState.searchText,
            prompt: languageSettings.localized("prompt_manager.search.placeholder")
        )
        .overlay {
            if viewModel.filteredTemplates.isEmpty {
                ContentUnavailableView {
                    Label(
                        languageSettings.localized("prompt_manager.empty.title"),
                        systemImage: "doc.text"
                    )
                } description: {
                    Text(languageSettings.localized("prompt_manager.empty.description"))
                } actions: {
                    Button(languageSettings.localized("prompt_manager.empty.create")) {
                        presentCreateEditor()
                    }
                }
            }
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    presentCreateEditor()
                } label: {
                    Label(languageSettings.localized("prompt_manager.new_prompt"), systemImage: "plus")
                }
            }

            ToolbarItem(placement: .automatic) {
                AppFilterToggle(viewModel: viewModel)
            }
        }
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

// MARK: - Template List Row

private struct TemplateListRow: View {
    let template: PromptTemplate
    let categoryPath: String
    let onEdit: () -> Void
    let onDelete: () -> Void

    @State private var isHovering = false

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(template.title)
                    .font(.headline)
                    .lineLimit(1)

                if !template.content.isEmpty {
                    Text(template.content)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }

                if !categoryPath.isEmpty {
                    Text(categoryPath)
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }

            Spacer()

            if !template.linkedApps.isEmpty {
                HStack(spacing: 4) {
                    ForEach(Array(template.linkedApps.prefix(3).enumerated()), id: \.offset) { _, app in
                        Text(String(app.displayName.prefix(1)))
                            .font(.caption2.weight(.medium))
                            .frame(width: 22, height: 22)
                            .background(Circle().fill(.accent.opacity(0.12)))
                            .foregroundStyle(.accent)
                    }
                    if template.linkedApps.count > 3 {
                        Text("+\(template.linkedApps.count - 3)")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            if isHovering {
                HStack(spacing: 4) {
                    Button {
                        onEdit()
                    } label: {
                        Image(systemName: "pencil")
                            .font(.caption)
                    }
                    .buttonStyle(.borderless)

                    Button(role: .destructive) {
                        onDelete()
                    } label: {
                        Image(systemName: "trash")
                            .font(.caption)
                    }
                    .buttonStyle(.borderless)
                }
                .transition(.opacity)
            }
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovering = hovering
            }
        }
    }
}
