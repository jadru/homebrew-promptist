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
        Form {
            // Accessibility Permission Banner
            if !permissionManager.hasPermission {
                Section {
                    AccessibilityPermissionBanner(permissionManager: permissionManager)
                }
            }

            // Scope Filter
            if !appFilters.isEmpty {
                Section {
                    HStack {
                        Text(languageSettings.localized("shortcut_manager.filter.scope"))
                        Spacer()
                        Menu {
                            Button {
                                viewModel.selectedScopeFilter = .all
                            } label: {
                                if viewModel.selectedScopeFilter == .all {
                                    Label(languageSettings.localized("shortcut_manager.filter.all_apps"), systemImage: "checkmark")
                                } else {
                                    Text(languageSettings.localized("shortcut_manager.filter.all_apps"))
                                }
                            }

                            Button {
                                viewModel.selectedScopeFilter = .global
                            } label: {
                                if viewModel.selectedScopeFilter == .global {
                                    Label(languageSettings.localized("shortcut_manager.filter.global"), systemImage: "checkmark")
                                } else {
                                    Text(languageSettings.localized("shortcut_manager.filter.global"))
                                }
                            }

                            Divider()

                            ForEach(appFilters, id: \.self) { app in
                                Button {
                                    viewModel.selectedScopeFilter = .app(app)
                                } label: {
                                    if viewModel.selectedScopeFilter == .app(app) {
                                        Label(app.displayName, systemImage: "checkmark")
                                    } else {
                                        Text(app.displayName)
                                    }
                                }
                            }
                        } label: {
                            Text(scopeFilterLabel)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }

            // Shortcut List
            let displayedItems = viewModel.displayedTemplatesWithShortcuts

            if displayedItems.isEmpty {
                Section {
                    ContentUnavailableView {
                        Label(
                            languageSettings.localized("shortcut_manager.empty.title"),
                            systemImage: "command"
                        )
                    } description: {
                        Text(languageSettings.localized("shortcut_manager.empty.description"))
                    }
                }
            } else {
                Section(languageSettings.localized("shortcut_manager.title")) {
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
        }
        .formStyle(.grouped)
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
            permissionManager.checkPermission()

            if focusedTemplateId != nil {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    focusedTemplateId = nil
                }
            }
        }
    }

    private var appFilters: [PromptAppTarget] {
        viewModel.uniqueAppTargets
    }

    private var scopeFilterLabel: String {
        switch viewModel.selectedScopeFilter {
        case .all:
            return languageSettings.localized("shortcut_manager.filter.all_apps")
        case .global:
            return languageSettings.localized("shortcut_manager.filter.global")
        case .app(let app):
            return app.displayName
        }
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

    private func presentRecorder(for templateId: UUID, editing shortcut: TemplateShortcut? = nil) {
        recordingTemplateId = templateId
        isPresentingRecorder = true
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
        DisclosureGroup {
            // Shortcuts list
            if templateWithShortcuts.shortcuts.isEmpty {
                Button {
                    onAddShortcut()
                } label: {
                    Label(languageSettings.localized("shortcut_manager.add_shortcut"), systemImage: "plus.circle.fill")
                }
            } else {
                ForEach(templateWithShortcuts.shortcuts) { shortcut in
                    ShortcutItemRow(
                        shortcut: shortcut,
                        hasConflict: hasConflict(shortcut: shortcut),
                        onEdit: { onEditShortcut(shortcut) },
                        onDelete: { onDeleteShortcut(shortcut.id) },
                        onToggleEnabled: { onToggleEnabled(shortcut.id) }
                    )
                }

                Button {
                    onAddShortcut()
                } label: {
                    Label(languageSettings.localized("shortcut_manager.add_another"), systemImage: "plus.circle")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        } label: {
            HStack {
                Text(templateWithShortcuts.template.title)
                    .font(.headline)

                Spacer()

                if !templateWithShortcuts.template.linkedApps.isEmpty {
                    HStack(spacing: 4) {
                        ForEach(Array(templateWithShortcuts.template.linkedApps.prefix(2).enumerated()), id: \.offset) { _, app in
                            Text(app.displayName)
                                .font(.caption2)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(.accent.opacity(0.1), in: Capsule())
                                .foregroundStyle(.accent)
                        }
                    }
                }
            }
        }
        .listRowBackground(
            isFocused ? Color.accentColor.opacity(0.08) : nil
        )
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

    @EnvironmentObject private var languageSettings: LanguageSettings

    var body: some View {
        HStack(spacing: 12) {
            // Key combo
            Text(shortcut.keyCombo.displayString)
                .font(.system(.body, design: .monospaced))
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(.quaternary, in: RoundedRectangle(cornerRadius: 6))

            // Scope
            Text(shortcut.scope.displayName)
                .font(.caption)
                .foregroundStyle(.secondary)

            Spacer()

            // Conflict indicator
            if hasConflict {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(.yellow)
                    .help(languageSettings.localized("shortcut_manager.conflict.tooltip"))
            }

            // Enabled toggle
            Toggle("", isOn: Binding(
                get: { shortcut.isEnabled },
                set: { _ in onToggleEnabled() }
            ))
            .toggleStyle(.switch)
            .labelsHidden()

            // Delete
            Button(role: .destructive) {
                onDelete()
            } label: {
                Image(systemName: "trash")
                    .font(.caption)
            }
            .buttonStyle(.borderless)
        }
    }
}
