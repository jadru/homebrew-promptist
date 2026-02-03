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
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 12) {
                // Section heading
                VStack(alignment: .leading, spacing: 4) {
                    Text(languageSettings.localized("prompt_manager.nav.all_templates"))
                        .font(.system(size: 24, weight: .bold))
                        .foregroundStyle(.primary)

                    Text("\(viewModel.filteredTemplates.count) \(languageSettings.localized("prompt_manager.template_count"))")
                        .font(.system(size: 14))
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 4)

                // Template cards
                ForEach(viewModel.filteredTemplates) { template in
                    TemplateListRow(
                        template: template,
                        categoryPath: viewModel.categoryPath(for: template.categoryId ?? UUID()),
                        onEdit: { presentEditEditor(for: template) },
                        onDelete: { confirmDelete(template: template) }
                    )
                }
                .padding(.horizontal, 20)
            }
        }
        .searchable(
            text: $viewModel.filterState.searchText,
            prompt: languageSettings.localized("prompt_manager.search.placeholder")
        )
        .overlay {
            if viewModel.filteredTemplates.isEmpty {
                EmptyStateView(
                    icon: "doc.text",
                    title: languageSettings.localized("prompt_manager.empty.title"),
                    description: languageSettings.localized("prompt_manager.empty.description"),
                    actionLabel: languageSettings.localized("prompt_manager.empty.create"),
                    action: presentCreateEditor
                )
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
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(template.title)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.primary)
                        .lineLimit(1)

                    if !template.content.isEmpty {
                        Text(template.content)
                            .font(.system(size: 13))
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                    }
                }

                Spacer()

                if isHovering {
                    HStack(spacing: 6) {
                        Button {
                            onEdit()
                        } label: {
                            Image(systemName: "pencil")
                                .font(.system(size: 12))
                                .foregroundStyle(.secondary)
                        }
                        .buttonStyle(.plain)

                        Button {
                            onDelete()
                        } label: {
                            Image(systemName: "trash")
                                .font(.system(size: 12))
                                .foregroundStyle(.red.opacity(0.8))
                        }
                        .buttonStyle(.plain)
                    }
                    .transition(.opacity)
                }
            }

            // Bottom row: app badges + category
            HStack(spacing: 8) {
                if !template.linkedApps.isEmpty {
                    HStack(spacing: 4) {
                        ForEach(Array(template.linkedApps.prefix(3).enumerated()), id: \.offset) { _, app in
                            Text(String(app.displayName.prefix(1)))
                                .font(.caption2.weight(.medium))
                                .frame(width: 20, height: 20)
                                .glassCircleBackground(size: 20, tint: .accentColor)
                                .foregroundStyle(.accent)
                        }
                        if template.linkedApps.count > 3 {
                            Text("+\(template.linkedApps.count - 3)")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                if !categoryPath.isEmpty {
                    HStack(spacing: 3) {
                        Image(systemName: "folder")
                            .font(.system(size: 9))
                        Text(categoryPath)
                            .font(.system(size: 11))
                    }
                    .foregroundStyle(.tertiary)
                }

                Spacer()
            }
        }
        .padding(12)
        .background {
            if #available(macOS 26.0, *) {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(.clear)
                    .glassEffect(
                        isHovering ? .clear : .regular,
                        in: RoundedRectangle(cornerRadius: 10, style: .continuous)
                    )
            } else {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(isHovering ? AnyShapeStyle(Color.primary.opacity(0.06)) : AnyShapeStyle(.regularMaterial))
            }
        }
        .contentShape(Rectangle())
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovering = hovering
            }
        }
    }
}
