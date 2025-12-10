import SwiftUI
import Combine
import AppKit
import UniformTypeIdentifiers

/// Content view for the Template Manager tab
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

    @State private var searchText = ""
    @State private var isPresentingEditor = false
    @State private var editorMode: PromptEditorView.Mode = .create(nextSortOrder: 1, presetApps: [])
    @State private var templatePendingDeletion: PromptTemplate?
    @State private var showDeleteConfirmation = false
    @State private var searchRecordWorkItem: DispatchWorkItem?
    @State private var selectedAppFilter: String?
    @State private var selectedCollectionFilter: CollectionFilter = .all
    @State private var showCollectionEditor = false
    @State private var editingCollectionName = ""
    @State private var editingCollectionId: UUID?
    @State private var draggingTemplateId: UUID?

    /// Represents a collection filter state for clear, unambiguous filtering
    private enum CollectionFilter: Equatable {
        case all
        case noCollection
        case collection(UUID)
    }

    var body: some View {
        VStack(spacing: 0) {
            // Toolbar with search, density toggle, and new button
            HStack(spacing: DesignTokens.Spacing.md) {
                SearchBar(text: $searchText, placeholder: languageSettings.localized("search.placeholder")) {
                    viewModel.recordRecentSearch(searchText)
                }
                .frame(maxWidth: 400)
                .onChange(of: searchText) { newValue in
                    searchRecordWorkItem?.cancel()
                    let workItem = DispatchWorkItem { viewModel.recordRecentSearch(newValue) }
                    searchRecordWorkItem = workItem
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: workItem)
                }

                Spacer()

                ActionButton(
                    languageSettings.localized("prompt_manager.toolbar.new_prompt"),
                    icon: "plus",
                    variant: .primary,
                    action: presentCreateEditor
                )
            }
            .padding(DesignTokens.Spacing.md)
            .background(DesignTokens.Colors.backgroundElevated)

            Separator()

            // Dynamic filter bar
            dynamicFilterBar
                .padding(.vertical, DesignTokens.Spacing.sm)

            Separator()

            // Content area with custom ScrollView and drag-and-drop reordering
            ScrollView {
                LazyVStack(spacing: DesignTokens.Spacing.md, pinnedViews: [.sectionHeaders]) {
                    if !displayedTemplates.isEmpty {
                        templateList(displayedTemplates)
                    } else {
                        EmptyStateView(
                            icon: "doc.text.magnifyingglass",
                            title: languageSettings.localized("prompt_manager.empty.title"),
                            description: languageSettings.localized("prompt_manager.empty.description"),
                            actionLabel: nil,
                            action: nil
                        )
                    }
                }
                .padding(DesignTokens.Spacing.lg)
            }
        }
        .background(DesignTokens.Colors.backgroundPrimary)
        .sheet(isPresented: $isPresentingEditor) {
            PromptEditorView(mode: editorMode) { template in
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

    private var displayedTemplates: [PromptTemplate] {
        var filtered = viewModel.templatesForManagement(searchText: searchText)

        // Apply app filter if selected
        if let filterApp = selectedAppFilter {
            filtered = filtered.filter { template in
                template.linkedApps.contains { $0.displayName == filterApp }
            }
        }

        // Apply collection filter
        switch selectedCollectionFilter {
        case .all:
            break
        case .noCollection:
            filtered = filtered.filter { $0.collectionId == nil }
        case .collection(let collectionId):
            filtered = filtered.filter { $0.collectionId == collectionId }
        }

        return filtered
    }

    private var dynamicFilterBar: some View {
        VStack(spacing: DesignTokens.Spacing.sm) {
            // App filters
            if !appFilters.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: DesignTokens.Spacing.xs) {
                        // All filter
                        filterChip(title: languageSettings.localized("prompt_manager.filter.all"), appName: nil, count: viewModel.allTemplates.count)

                        // Dynamic app filters
                        ForEach(appFilters, id: \.app) { filter in
                            filterChip(title: filter.app, appName: filter.app, count: filter.count)
                        }
                    }
                    .padding(.horizontal, DesignTokens.Spacing.md)
                }
            }

            // Collection filters
            if !viewModel.allCollections.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: DesignTokens.Spacing.xs) {
                        // All collections filter
                        collectionFilterChip(
                            title: languageSettings.localized("collection.filter.all"),
                            filter: .all,
                            count: viewModel.allTemplates.count
                        )

                        // No collection filter
                        collectionFilterChip(
                            title: languageSettings.localized("collection.filter.none"),
                            filter: .noCollection,
                            count: viewModel.allTemplates.filter { $0.collectionId == nil }.count
                        )

                        // Dynamic collection filters
                        ForEach(viewModel.allCollections) { collection in
                            collectionFilterChip(
                                title: collection.name,
                                filter: .collection(collection.id),
                                count: viewModel.allTemplates.filter { $0.collectionId == collection.id }.count
                            )
                            .contextMenu {
                                Button(languageSettings.localized("collection.rename")) {
                                    editingCollectionName = collection.name
                                    editingCollectionId = collection.id
                                    showCollectionEditor = true
                                }
                                Button(languageSettings.localized("collection.delete"), role: .destructive) {
                                    viewModel.deleteCollection(collection.id)
                                }
                            }
                        }

                        // Add collection button
                        Button(action: { presentCollectionCreator() }) {
                            Image(systemName: "plus.circle")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(DesignTokens.Colors.accentPrimary)
                        }
                        .buttonStyle(.plain)
                        .help(languageSettings.localized("collection.add"))
                    }
                    .padding(.horizontal, DesignTokens.Spacing.md)
                }
            } else {
                // Show add collection button when no collections exist
                HStack {
                    Button(action: { presentCollectionCreator() }) {
                        HStack(spacing: DesignTokens.Spacing.xs) {
                            Image(systemName: "folder.badge.plus")
                            Text(languageSettings.localized("collection.create"))
                        }
                        .font(DesignTokens.Typography.label())
                        .foregroundColor(DesignTokens.Colors.accentPrimary)
                    }
                    .buttonStyle(.plain)
                    Spacer()
                }
                .padding(.horizontal, DesignTokens.Spacing.md)
            }
        }
    }

    private var appFilters: [(app: String, count: Int)] {
        var appCounts: [String: Int] = [:]

        for template in viewModel.allTemplates {
            for app in template.linkedApps {
                let name = app.displayName
                appCounts[name, default: 0] += 1
            }
        }

        return appCounts
            .sorted { $0.key.localizedCaseInsensitiveCompare($1.key) == .orderedAscending } // Sort alphabetically
            .map { (app: $0.key, count: $0.value) }
    }

    private func filterChip(title: String, appName: String?, count: Int) -> some View {
        FilterChipButton(
            title: "\(title) (\(count))",
            isSelected: selectedAppFilter == appName,
            action: {
                selectedAppFilter = appName
            }
        )
    }

    private func collectionFilterChip(title: String, filter: CollectionFilter, count: Int) -> some View {
        CollectionFilterChipWrapper(
            title: "\(title) (\(count))",
            isSelected: selectedCollectionFilter == filter,
            filter: filter,
            action: {
                selectedCollectionFilter = filter
            },
            onDrop: { templateId in
                let targetCollectionId: UUID? = {
                    switch filter {
                    case .all, .noCollection:
                        return nil
                    case .collection(let id):
                        return id
                    }
                }()
                viewModel.moveTemplateToCollection(templateId: templateId, collectionId: targetCollectionId)
            }
        )
    }

    private struct CollectionFilterChipWrapper: View {
        let title: String
        let isSelected: Bool
        let filter: PromptManagerContentView.CollectionFilter
        let action: () -> Void
        let onDrop: (UUID) -> Void

        @State private var isDropTarget = false

        var body: some View {
            CollectionFilterChipButton(
                title: title,
                isSelected: isSelected,
                action: action,
                isDropTarget: isDropTarget
            )
            .dropDestination(for: String.self) { items, _ in
                guard let templateIdString = items.first,
                      let templateId = UUID(uuidString: templateIdString) else {
                    return false
                }
                onDrop(templateId)
                return true
            } isTargeted: { isTargeted in
                isDropTarget = isTargeted
            }
        }
    }

    private func presentCollectionCreator() {
        editingCollectionName = ""
        editingCollectionId = nil
        showCollectionEditor = true
    }

    private func createOrUpdateCollection() {
        guard !editingCollectionName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }

        if let collectionId = editingCollectionId {
            // Update existing collection
            if let collection = viewModel.allCollections.first(where: { $0.id == collectionId }) {
                var updated = collection
                updated.name = editingCollectionName
                viewModel.updateCollection(updated)
            }
        } else {
            // Create new collection
            let newCollection = PromptTemplateCollection(
                name: editingCollectionName,
                sortOrder: viewModel.nextCollectionSortOrder
            )
            viewModel.addCollection(newCollection)
        }

        showCollectionEditor = false
    }

    private func templateList(_ templates: [PromptTemplate]) -> some View {
        VStack(spacing: DesignTokens.Spacing.sm) {
            ForEach(Array(templates.enumerated()), id: \.element.id) { index, template in
                DraggablePromptRow(
                    template: template,
                    index: index,
                    shortcutCount: shortcutCount(for: template.id),
                    onEdit: { presentEditEditor(for: template) },
                    onDelete: {
                        templatePendingDeletion = template
                        showDeleteConfirmation = true
                    },
                    onNavigateToShortcut: { onNavigateToShortcut(template.id) },
                    onReorder: { fromIndex, toIndex in
                        reorderTemplates(from: fromIndex, to: toIndex, in: templates)
                    },
                    draggingTemplateId: $draggingTemplateId
                )
            }
        }
    }

    private func reorderTemplates(from fromIndex: Int, to toIndex: Int, in templates: [PromptTemplate]) {
        guard fromIndex != toIndex else { return }
        var reorderedIds = templates.map { $0.id }
        let movedId = reorderedIds.remove(at: fromIndex)
        reorderedIds.insert(movedId, at: toIndex > fromIndex ? toIndex - 1 : toIndex)
        viewModel.reorderTemplates(reorderedIds)
    }

    private func shortcutCount(for templateId: UUID) -> Int {
        shortcutViewModel.shortcuts.filter { $0.templateId == templateId }.count
    }

    private func presentCreateEditor() {
        editorMode = .create(nextSortOrder: viewModel.nextSortOrder, presetApps: [])
        isPresentingEditor = true
    }

    private func presentEditEditor(for template: PromptTemplate) {
        editorMode = .edit(existing: template)
        isPresentingEditor = true
    }

    private func handlePendingCreationIntent(_ intent: PromptListViewModel.PromptCreationIntent) {
        editorMode = .create(nextSortOrder: viewModel.nextSortOrder, presetApps: intent.presetApps)
        isPresentingEditor = true
        viewModel.pendingCreationIntent = nil
    }
}

// MARK: - Draggable Prompt Row

private struct DraggablePromptRow: View {
    let template: PromptTemplate
    let index: Int
    let shortcutCount: Int
    let onEdit: () -> Void
    let onDelete: () -> Void
    let onNavigateToShortcut: () -> Void
    let onReorder: (Int, Int) -> Void
    @Binding var draggingTemplateId: UUID?

    @State private var isDropTarget = false

    var body: some View {
        PromptManagerRowView(
            template: template,
            shortcutCount: shortcutCount,
            onEdit: onEdit,
            onDelete: onDelete,
            onNavigateToShortcut: onNavigateToShortcut
        )
        .draggable(template.id.uuidString) {
            // Preview while dragging
            Text(template.title)
                .padding(DesignTokens.Spacing.sm)
                .background(DesignTokens.Colors.backgroundElevated)
                .cornerRadius(DesignTokens.Radius.md)
        }
        .dropDestination(for: String.self) { items, _ in
            guard let draggedIdString = items.first,
                  let draggedId = UUID(uuidString: draggedIdString),
                  draggedId != template.id else {
                return false
            }
            // Find the source index
            if let sourceIdx = draggingTemplateId.flatMap({ _ in nil as Int? }) {
                onReorder(sourceIdx, index)
            }
            return true
        } isTargeted: { isTargeted in
            isDropTarget = isTargeted
        }
        .overlay(
            RoundedRectangle(cornerRadius: DesignTokens.Radius.lg, style: .continuous)
                .stroke(
                    isDropTarget ? DesignTokens.Colors.accentPrimary : Color.clear,
                    lineWidth: isDropTarget ? 2 : 0
                )
        )
    }
}

// MARK: - Filter Chip Button

private struct FilterChipButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    @State private var isHovering = false
    @State private var isDropTarget = false

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(DesignTokens.Typography.label())
                .foregroundColor(
                    isSelected
                        ? DesignTokens.Colors.foregroundPrimary
                        : DesignTokens.Colors.foregroundSecondary
                )
                .padding(.horizontal, DesignTokens.Spacing.md)
                .padding(.vertical, DesignTokens.Spacing.xs)
                .background(
                    Capsule()
                        .fill(
                            isDropTarget
                                ? DesignTokens.Colors.accentPrimary.opacity(0.2)
                                : (isSelected
                                    ? DesignTokens.Colors.selectedBackground
                                    : (isHovering ? DesignTokens.Colors.hoverBackground : DesignTokens.Colors.backgroundSecondary))
                        )
                )
                .overlay(
                    Capsule()
                        .stroke(
                            isDropTarget
                                ? DesignTokens.Colors.accentPrimary
                                : (isSelected ? DesignTokens.Colors.accentPrimary.opacity(0.3) : DesignTokens.Colors.borderSubtle),
                            lineWidth: isDropTarget ? 2 : (isSelected ? 1 : 0.5)
                        )
                )
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            withAnimation(DesignTokens.Animation.normal) {
                isHovering = hovering
            }
        }
    }
}

// MARK: - Collection Filter Chip Button

private struct CollectionFilterChipButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    let isDropTarget: Bool

    @State private var isHovering = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: "folder.fill")
                    .font(.system(size: 11, weight: .medium))
                Text(title)
                    .font(DesignTokens.Typography.label())
            }
            .foregroundColor(
                isSelected
                    ? Color.white
                    : (isDropTarget ? Color(hex: 0x8B7AFF) : DesignTokens.Colors.foregroundSecondary)
            )
            .padding(.horizontal, DesignTokens.Spacing.md)
            .padding(.vertical, DesignTokens.Spacing.xs)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(
                        isDropTarget
                            ? Color(hex: 0x8B7AFF).opacity(0.35)
                            : (isSelected
                                ? Color(hex: 0x8B7AFF)
                                : (isHovering ? Color(hex: 0x8B7AFF).opacity(0.1) : DesignTokens.Colors.backgroundSecondary))
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(
                        isDropTarget
                            ? Color(hex: 0x8B7AFF).opacity(0.9)
                            : (isSelected ? Color(hex: 0x8B7AFF).opacity(0.5) : DesignTokens.Colors.borderSubtle),
                        lineWidth: isDropTarget ? 2.5 : (isSelected ? 1.5 : 0.5)
                    )
            )
            .shadow(
                color: isDropTarget ? Color(hex: 0x8B7AFF).opacity(0.5) : Color.clear,
                radius: isDropTarget ? 10 : 0,
                x: 0,
                y: 2
            )
            .scaleEffect(isDropTarget ? 1.05 : 1.0)
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            withAnimation(DesignTokens.Animation.normal) {
                isHovering = hovering
            }
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isDropTarget)
    }
}

// MARK: - Prompt Manager Row View

private struct PromptManagerRowView: View {
    let template: PromptTemplate
    let shortcutCount: Int
    let onEdit: () -> Void
    let onDelete: () -> Void
    let onNavigateToShortcut: () -> Void

    @State private var isHovering = false

    var body: some View {
        HStack(alignment: .top, spacing: DesignTokens.Spacing.md) {
            // Drag handle
            Image(systemName: "line.3.horizontal")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(DesignTokens.Colors.foregroundTertiary)
                .frame(width: 20)
                .opacity(isHovering ? 1 : 0.3)

            VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                HStack {
                    Text(template.title)
                        .font(DesignTokens.Typography.headline(16))
                        .foregroundColor(DesignTokens.Colors.foregroundPrimary)

                    // Shortcut badge
                    if shortcutCount > 0 {
                        ShortcutBadge(count: shortcutCount, action: onNavigateToShortcut)
                    }

                    Spacer()

                    if !template.linkedApps.isEmpty {
                        LinkedAppsDisplay(apps: template.linkedApps)
                    }
                }

                if !template.tags.isEmpty {
                    Text(template.tags.joined(separator: ", "))
                        .font(DesignTokens.Typography.caption(11))
                        .foregroundColor(DesignTokens.Colors.foregroundSecondary)
                }

                Text(template.content)
                    .font(DesignTokens.Typography.body(13))
                    .foregroundColor(DesignTokens.Colors.foregroundSecondary)
                    .lineLimit(3)
            }

            if isHovering {
                HStack(spacing: DesignTokens.Spacing.xs) {
                    IconButton(icon: "square.and.pencil", action: onEdit)
                    IconButton(icon: "trash", action: onDelete)
                }
                .transition(.opacity)
            }
        }
        .padding(DesignTokens.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: DesignTokens.Radius.lg, style: .continuous)
                .fill(isHovering ? DesignTokens.Colors.backgroundSecondary : DesignTokens.Colors.backgroundElevated)
        )
        .overlay(
            RoundedRectangle(cornerRadius: DesignTokens.Radius.lg, style: .continuous)
                .stroke(
                    isHovering ? DesignTokens.Colors.borderDefault : DesignTokens.Colors.borderSubtle,
                    lineWidth: 1
                )
        )
        .onHover { hovering in
            withAnimation(DesignTokens.Animation.normal) {
                isHovering = hovering
            }
        }
    }
}

// MARK: - Linked Apps Display

private struct LinkedAppsDisplay: View {
    let apps: [PromptAppTarget]

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: DesignTokens.Spacing.xxs) {
                ForEach(Array(apps.enumerated()), id: \.offset) { _, app in
                    Text(app.displayName)
                        .font(DesignTokens.Typography.caption(11, weight: .medium))
                        .foregroundColor(DesignTokens.Colors.accentPrimary)
                        .padding(.horizontal, DesignTokens.Spacing.sm)
                        .padding(.vertical, DesignTokens.Spacing.xxs)
                        .background(
                            Capsule()
                                .fill(DesignTokens.Colors.accentPrimary.opacity(0.1))
                        )
                        .overlay(
                            Capsule()
                                .stroke(DesignTokens.Colors.accentPrimary.opacity(0.2), lineWidth: 0.5)
                        )
                }
            }
        }
        .frame(maxWidth: 300)
    }
}

private extension PromptManagerContentView.PresentationStyle {
    var minWidth: CGFloat {
        switch self {
        case .window:
            return 640
        case .floatingPanel:
            return 420
        }
    }

    var minHeight: CGFloat {
        switch self {
        case .window:
            return 520
        case .floatingPanel:
            return 460
        }
    }
}
