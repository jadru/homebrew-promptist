import SwiftUI
import Combine
import AppKit

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
    @State private var isCompactMode = false
    @State private var selectedAppFilter: String?
    @State private var selectedGroupFilter: UUID?
    @State private var showGroupEditor = false
    @State private var editingGroupName = ""
    @State private var editingGroupId: UUID?

    var body: some View {
        VStack(spacing: 0) {
            // Toolbar with search, density toggle, and new button
            HStack(spacing: DesignTokens.Spacing.md) {
                SearchBar(text: $searchText, placeholder: String(localized: "search.placeholder", locale: languageSettings.locale)) {
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

                // Density toggle
                Button(action: {
                    withAnimation(DesignTokens.Animation.normal) {
                        isCompactMode.toggle()
                    }
                }) {
                    Image(systemName: isCompactMode ? "square.grid.2x2" : "square.grid.2x2.fill")
                        .font(.system(size: DesignTokens.IconSize.sm, weight: .medium))
                        .foregroundColor(DesignTokens.Colors.foregroundSecondary)
                        .frame(width: 28, height: 28)
                }
                .buttonStyle(.plain)
                .help(isCompactMode ? String(localized: "prompt_manager.density.normal", locale: languageSettings.locale) : String(localized: "prompt_manager.density.compact", locale: languageSettings.locale))

                ActionButton(
                    String(localized: "prompt_manager.toolbar.new_prompt", locale: languageSettings.locale),
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

            // Content area with custom ScrollView
            ScrollView {
                LazyVStack(spacing: DesignTokens.Spacing.md, pinnedViews: [.sectionHeaders]) {
                    if !displayedTemplates.isEmpty {
                        templateList(displayedTemplates)
                    } else {
                        EmptyStateView(
                            icon: "doc.text.magnifyingglass",
                            title: String(localized: "prompt_manager.empty.title", locale: languageSettings.locale).isEmpty ? "No prompts found" : String(localized: "prompt_manager.empty.title", locale: languageSettings.locale),
                            description: String(localized: "prompt_manager.empty.description", locale: languageSettings.locale).isEmpty ? "Try adjusting your search or create a new prompt" : String(localized: "prompt_manager.empty.description", locale: languageSettings.locale),
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
        .alert("prompt_manager.delete_alert.title", isPresented: $showDeleteConfirmation, presenting: templatePendingDeletion) { template in
            Button("prompt_manager.delete_alert.delete", role: .destructive) {
                viewModel.deleteTemplate(template)
            }
            Button("prompt_manager.delete_alert.cancel", role: .cancel) { }
        } message: { _ in
            Text("prompt_manager.delete_alert.message")
        }
        .sheet(isPresented: $showGroupEditor) {
            GroupEditorView(
                groupName: $editingGroupName,
                isEditing: editingGroupId != nil,
                onCreate: createOrUpdateGroup,
                onCancel: { showGroupEditor = false }
            )
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
                template.linkedApps.contains { target in
                    target.displayName == filterApp
                }
            }
        }

        // Apply group filter if selected
        if let groupId = selectedGroupFilter {
            filtered = filtered.filter { $0.groupId == groupId }
        } else if selectedGroupFilter == UUID(uuidString: "00000000-0000-0000-0000-000000000000") {
            // Special UUID for "No Group"
            filtered = filtered.filter { $0.groupId == nil }
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
                        filterChip(title: String(localized: "prompt_manager.filter.all", locale: languageSettings.locale), appName: nil, count: viewModel.allTemplates.count)

                        // Dynamic app filters
                        ForEach(appFilters, id: \.app) { filter in
                            filterChip(title: filter.app, appName: filter.app, count: filter.count)
                        }
                    }
                    .padding(.horizontal, DesignTokens.Spacing.md)
                }
            }

            // Group filters
            if !viewModel.allGroups.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: DesignTokens.Spacing.xs) {
                        // All groups filter
                        groupFilterChip(title: "All Groups", groupId: nil, count: viewModel.allTemplates.count)

                        // No group filter
                        groupFilterChip(title: "No Group", groupId: UUID(uuidString: "00000000-0000-0000-0000-000000000000"), count: viewModel.allTemplates.filter { $0.groupId == nil }.count)

                        // Dynamic group filters
                        ForEach(viewModel.allGroups) { group in
                            groupFilterChip(title: group.name, groupId: group.id, count: viewModel.allTemplates.filter { $0.groupId == group.id }.count)
                                .contextMenu {
                                    Button("Rename") {
                                        editingGroupName = group.name
                                        editingGroupId = group.id
                                        showGroupEditor = true
                                    }
                                    Button("Delete", role: .destructive) {
                                        viewModel.deleteGroup(group.id)
                                    }
                                }
                        }

                        // Add group button
                        Button(action: { presentGroupCreator() }) {
                            Image(systemName: "plus.circle")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(DesignTokens.Colors.accentPrimary)
                        }
                        .buttonStyle(.plain)
                        .help("Add Group")
                    }
                    .padding(.horizontal, DesignTokens.Spacing.md)
                }
            } else {
                // Show add group button when no groups exist
                HStack {
                    Button(action: { presentGroupCreator() }) {
                        HStack(spacing: DesignTokens.Spacing.xs) {
                            Image(systemName: "folder.badge.plus")
                            Text("Create Group")
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

    private func groupFilterChip(title: String, groupId: UUID?, count: Int) -> some View {
        GroupFilterChipWrapper(
            title: "\(title) (\(count))",
            isSelected: selectedGroupFilter == groupId,
            groupId: groupId,
            action: {
                selectedGroupFilter = groupId
            },
            onDrop: { templateId in
                let targetGroupId = (groupId == UUID(uuidString: "00000000-0000-0000-0000-000000000000")) ? nil : groupId
                viewModel.moveTemplateToGroup(templateId: templateId, groupId: targetGroupId)
            }
        )
    }

    private struct GroupFilterChipWrapper: View {
        let title: String
        let isSelected: Bool
        let groupId: UUID?
        let action: () -> Void
        let onDrop: (UUID) -> Void

        @State private var isDropTarget = false

        var body: some View {
            GroupFilterChipButton(
                title: title,
                isSelected: isSelected,
                action: action,
                isDropTarget: isDropTarget
            )
            .dropDestination(for: String.self) { items, location in
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

    private func presentGroupCreator() {
        editingGroupName = ""
        editingGroupId = nil
        showGroupEditor = true
    }

    private func createOrUpdateGroup() {
        guard !editingGroupName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }

        if let groupId = editingGroupId {
            // Update existing group
            if let group = viewModel.allGroups.first(where: { $0.id == groupId }) {
                var updated = group
                updated.name = editingGroupName
                viewModel.updateGroup(updated)
            }
        } else {
            // Create new group
            let newGroup = PromptTemplateGroup(
                name: editingGroupName,
                sortOrder: viewModel.nextGroupSortOrder
            )
            viewModel.addGroup(newGroup)
        }

        showGroupEditor = false
    }

    private func templateList(_ templates: [PromptTemplate]) -> some View {
        VStack(spacing: DesignTokens.Spacing.sm) {
            ForEach(templates) { template in
                managerRow(template)
            }
        }
    }

    private func managerRow(_ template: PromptTemplate) -> some View {
        PromptManagerRowView(
            template: template,
            isCompact: isCompactMode,
            shortcutCount: shortcutCount(for: template.id),
            onEdit: { presentEditEditor(for: template) },
            onDelete: {
                templatePendingDeletion = template
                showDeleteConfirmation = true
            },
            onNavigateToShortcut: { onNavigateToShortcut(template.id) }
        )
        .draggable(template.id.uuidString) {
            // Preview while dragging
            Text(template.title)
                .padding(DesignTokens.Spacing.sm)
                .background(DesignTokens.Colors.backgroundElevated)
                .cornerRadius(DesignTokens.Radius.md)
        }
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

// MARK: - Group Filter Chip Button

private struct GroupFilterChipButton: View {
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
    let isCompact: Bool
    let shortcutCount: Int
    let onEdit: () -> Void
    let onDelete: () -> Void
    let onNavigateToShortcut: () -> Void

    @State private var isHovering = false

    var body: some View {
        HStack(alignment: .top, spacing: DesignTokens.Spacing.md) {
            VStack(alignment: .leading, spacing: isCompact ? DesignTokens.Spacing.xs : DesignTokens.Spacing.sm) {
                HStack {
                    Text(template.title)
                        .font(DesignTokens.Typography.headline(isCompact ? 15 : 16))
                        .foregroundColor(DesignTokens.Colors.foregroundPrimary)

                    // NEW: Shortcut badge
                    if shortcutCount > 0 {
                        ShortcutBadge(count: shortcutCount, action: onNavigateToShortcut)
                    }

                    Spacer()

                    if !template.linkedApps.isEmpty {
                        LinkedAppsDisplay(apps: template.linkedApps, isCompact: isCompact)
                    }
                }

                if !template.tags.isEmpty {
                    Text(template.tags.joined(separator: ", "))
                        .font(DesignTokens.Typography.caption(isCompact ? 10 : 11))
                        .foregroundColor(DesignTokens.Colors.foregroundSecondary)
                }

                Text(template.content)
                    .font(DesignTokens.Typography.body(isCompact ? 12 : 13))
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
        .padding(isCompact ? DesignTokens.Spacing.sm : DesignTokens.Spacing.md)
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
    let isCompact: Bool

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: DesignTokens.Spacing.xxs) {
                ForEach(Array(apps.enumerated()), id: \.offset) { _, app in
                    Text(app.displayName)
                        .font(DesignTokens.Typography.caption(isCompact ? 10 : 11, weight: .medium))
                        .foregroundColor(DesignTokens.Colors.accentPrimary)
                        .padding(.horizontal, isCompact ? DesignTokens.Spacing.xs : DesignTokens.Spacing.sm)
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
