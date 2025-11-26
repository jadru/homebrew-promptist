import SwiftUI

struct ShortcutManagerView: View {
    @ObservedObject var viewModel: ShortcutManagerViewModel
    @ObservedObject var shortcutManager: ShortcutManager
    @Binding var focusedTemplateId: UUID?
    @EnvironmentObject private var appContext: AppContextService
    @EnvironmentObject private var languageSettings: LanguageSettings

    @StateObject private var permissionManager = AccessibilityPermissionManager()
    @State private var isPresentingRecorder = false
    @State private var recordingTemplateId: UUID?
    @State private var showPermissionAlert = false

    var body: some View {
        VStack(spacing: 0) {
            // Toolbar
            HStack {
                Text(String(localized: "shortcut_manager.title", locale: languageSettings.locale))
                    .font(DesignTokens.Typography.headline(18))
                    .foregroundColor(DesignTokens.Colors.foregroundPrimary)
                Spacer()
            }
            .padding(DesignTokens.Spacing.md)
            .background(DesignTokens.Colors.backgroundElevated)

            Separator()

            // Accessibility Permission Banner
            if !permissionManager.hasPermission {
                AccessibilityPermissionBanner(permissionManager: permissionManager)
                    .padding(DesignTokens.Spacing.md)

                Separator()
            }

            // Scope filter bar
            if !appFilters.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: DesignTokens.Spacing.xs) {
                        filterChip(title: String(localized: "shortcut_manager.filter.all_apps", locale: languageSettings.locale), scope: .all)
                        filterChip(title: String(localized: "shortcut_manager.filter.global", locale: languageSettings.locale), scope: .global)
                        ForEach(appFilters, id: \.self) { app in
                            filterChip(title: app.displayName, scope: .app(app))
                        }
                    }
                    .padding(.horizontal, DesignTokens.Spacing.md)
                }
                .padding(.vertical, DesignTokens.Spacing.sm)

                Separator()
            }

            // Template list with shortcuts
            ScrollView {
                LazyVStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
                    let displayedItems = viewModel.displayedTemplatesWithShortcuts

                    if displayedItems.isEmpty {
                        EmptyStateView(
                            icon: "command",
                            title: String(localized: "shortcut_manager.empty.title", locale: languageSettings.locale),
                            description: String(localized: "shortcut_manager.empty.description", locale: languageSettings.locale),
                            actionLabel: nil,
                            action: nil
                        )
                        .padding(.top, DesignTokens.Spacing.xxxl)
                    } else {
                        ForEach(displayedItems) { item in
                            ShortcutTemplateRow(
                                templateWithShortcuts: item,
                                isFocused: focusedTemplateId == item.template.id,
                                conflicts: viewModel.conflicts,
                                onAddShortcut: { presentRecorder(for: item.template.id) },
                                onEditShortcut: { presentRecorder(for: item.template.id, editing: $0) },
                                onDeleteShortcut: { viewModel.deleteShortcut(id: $0) },
                                onToggleEnabled: { viewModel.toggleShortcutEnabled(id: $0) }
                            )
                        }
                    }
                }
                .padding(DesignTokens.Spacing.lg)
            }
        }
        .background(DesignTokens.Colors.backgroundPrimary)
        .sheet(isPresented: $isPresentingRecorder) {
            if let templateId = recordingTemplateId {
                ShortcutRecorderSheet(
                    templateId: templateId,
                    currentApp: currentAppTarget,
                    shortcutManager: shortcutManager,
                    onSave: { keyCombo, scope in
                        viewModel.addShortcut(templateId: templateId, keyCombo: keyCombo, scope: scope)
                        isPresentingRecorder = false
                        recordingTemplateId = nil
                    },
                    onCancel: {
                        isPresentingRecorder = false
                        recordingTemplateId = nil
                    }
                )
                .environmentObject(languageSettings)
            }
        }
        .sheet(isPresented: $showPermissionAlert) {
            AccessibilityPermissionAlert(permissionManager: permissionManager) {
                showPermissionAlert = false
            }
            .environmentObject(languageSettings)
        }
        .onAppear {
            // Check permission on appear
            permissionManager.checkPermission()

            if focusedTemplateId != nil {
                // Scroll happens automatically via LazyVStack
                // Clear after a moment
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    focusedTemplateId = nil
                }
            }
        }
    }

    private var appFilters: [PromptAppTarget] {
        viewModel.uniqueAppTargets
    }

    private var currentAppTarget: PromptAppTarget? {
        if let trackedApp = appContext.currentTrackedApp {
            return .tracked(trackedApp)
        } else if let bundleId = appContext.frontmostBundleIdentifier,
                  let name = appContext.frontmostAppName {
            return .custom(name: name, bundleIdentifier: bundleId)
        }
        return nil
    }

    private func filterChip(title: String, scope: ShortcutManagerViewModel.ShortcutScopeFilter) -> some View {
        FilterChipButton(
            title: title,
            isSelected: viewModel.selectedScopeFilter == scope,
            action: {
                withAnimation(DesignTokens.Animation.normal) {
                    viewModel.selectedScopeFilter = scope
                }
            }
        )
    }

    private func presentRecorder(for templateId: UUID, editing shortcut: TemplateShortcut? = nil) {
        recordingTemplateId = templateId
        isPresentingRecorder = true
    }
}

// MARK: - Filter Chip Button

private struct FilterChipButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    @State private var isHovering = false

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
                            isSelected
                                ? DesignTokens.Colors.selectedBackground
                                : (isHovering ? DesignTokens.Colors.hoverBackground : DesignTokens.Colors.backgroundSecondary)
                        )
                )
                .overlay(
                    Capsule()
                        .stroke(
                            isSelected ? DesignTokens.Colors.accentPrimary.opacity(0.3) : DesignTokens.Colors.borderSubtle,
                            lineWidth: isSelected ? 1 : 0.5
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

// MARK: - Shortcut Template Row

private struct ShortcutTemplateRow: View {
    let templateWithShortcuts: TemplateWithShortcuts
    let isFocused: Bool
    let conflicts: [ShortcutConflict]
    let onAddShortcut: () -> Void
    let onEditShortcut: (TemplateShortcut) -> Void
    let onDeleteShortcut: (UUID) -> Void
    let onToggleEnabled: (UUID) -> Void

    @EnvironmentObject private var languageSettings: LanguageSettings

    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
            // Template header
            HStack {
                Text(templateWithShortcuts.template.title)
                    .font(DesignTokens.Typography.headline())
                    .foregroundColor(DesignTokens.Colors.foregroundPrimary)
                Spacer()
                if !templateWithShortcuts.template.linkedApps.isEmpty {
                    LinkedAppsDisplay(apps: templateWithShortcuts.template.linkedApps)
                }
            }

            // Shortcuts list
            if templateWithShortcuts.shortcuts.isEmpty {
                Button(action: onAddShortcut) {
                    HStack(spacing: DesignTokens.Spacing.xs) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: DesignTokens.IconSize.sm))
                        Text(String(localized: "shortcut_manager.add_shortcut", locale: languageSettings.locale))
                            .font(DesignTokens.Typography.body())
                    }
                    .foregroundColor(DesignTokens.Colors.accentPrimary)
                }
                .buttonStyle(.plain)
            } else {
                VStack(spacing: DesignTokens.Spacing.sm) {
                    ForEach(templateWithShortcuts.shortcuts) { shortcut in
                        ShortcutItemRow(
                            shortcut: shortcut,
                            hasConflict: hasConflict(shortcut: shortcut),
                            onEdit: { onEditShortcut(shortcut) },
                            onDelete: { onDeleteShortcut(shortcut.id) },
                            onToggleEnabled: { onToggleEnabled(shortcut.id) }
                        )
                    }
                }

                Button(action: onAddShortcut) {
                    HStack(spacing: DesignTokens.Spacing.xs) {
                        Image(systemName: "plus.circle")
                            .font(.system(size: DesignTokens.IconSize.sm))
                        Text(String(localized: "shortcut_manager.add_another", locale: languageSettings.locale))
                            .font(DesignTokens.Typography.caption())
                    }
                    .foregroundColor(DesignTokens.Colors.foregroundSecondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(DesignTokens.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: DesignTokens.Radius.lg, style: .continuous)
                .fill(isFocused ? DesignTokens.Colors.selectedBackground : DesignTokens.Colors.backgroundElevated)
        )
        .overlay(
            RoundedRectangle(cornerRadius: DesignTokens.Radius.lg, style: .continuous)
                .stroke(
                    isFocused ? DesignTokens.Colors.accentPrimary : DesignTokens.Colors.borderSubtle,
                    lineWidth: 1
                )
        )
        .animation(DesignTokens.Animation.normal, value: isFocused)
    }

    private func hasConflict(shortcut: TemplateShortcut) -> Bool {
        conflicts.contains { conflict in
            conflict.shortcut1.id == shortcut.id || conflict.shortcut2.id == shortcut.id
        }
    }
}

// MARK: - Shortcut Item Row

private struct ShortcutItemRow: View {
    let shortcut: TemplateShortcut
    let hasConflict: Bool
    let onEdit: () -> Void
    let onDelete: () -> Void
    let onToggleEnabled: () -> Void

    @State private var isHovering = false
    @EnvironmentObject private var languageSettings: LanguageSettings

    var body: some View {
        HStack(spacing: DesignTokens.Spacing.md) {
            // Key combo badge
            Text(shortcut.keyCombo.displayString)
                .font(DesignTokens.Typography.mono(13))
                .foregroundColor(DesignTokens.Colors.foregroundPrimary)
                .padding(.horizontal, DesignTokens.Spacing.sm)
                .padding(.vertical, DesignTokens.Spacing.xs)
                .background(
                    RoundedRectangle(cornerRadius: DesignTokens.Radius.sm, style: .continuous)
                        .fill(DesignTokens.Colors.backgroundSecondary)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: DesignTokens.Radius.sm, style: .continuous)
                        .stroke(DesignTokens.Colors.borderSubtle, lineWidth: 0.5)
                )

            // Scope
            Text(shortcut.scope.displayName)
                .font(DesignTokens.Typography.caption())
                .foregroundColor(DesignTokens.Colors.foregroundSecondary)

            Spacer()

            // Conflict indicator
            if hasConflict {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: DesignTokens.IconSize.sm))
                    .foregroundColor(DesignTokens.Colors.warning)
                    .help(String(localized: "shortcut_manager.conflict.tooltip", locale: languageSettings.locale))
            }

            // Enabled toggle
            Toggle("", isOn: Binding(
                get: { shortcut.isEnabled },
                set: { _ in onToggleEnabled() }
            ))
            .toggleStyle(.switch)
            .labelsHidden()

            // Actions
            if isHovering {
                HStack(spacing: DesignTokens.Spacing.xxs) {
                    IconButton(icon: "trash", size: DesignTokens.IconSize.sm, action: onDelete)
                }
                .transition(.opacity)
            }
        }
        .padding(.vertical, DesignTokens.Spacing.xs)
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
        HStack(spacing: DesignTokens.Spacing.xxs) {
            ForEach(Array(apps.prefix(3).enumerated()), id: \.offset) { _, app in
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

            if apps.count > 3 {
                Text("+\(apps.count - 3)")
                    .font(DesignTokens.Typography.caption(10, weight: .medium))
                    .foregroundColor(DesignTokens.Colors.foregroundSecondary)
            }
        }
    }
}
