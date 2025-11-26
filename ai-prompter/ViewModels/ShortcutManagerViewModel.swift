import Foundation
import Combine

@MainActor
final class ShortcutManagerViewModel: ObservableObject {
    @Published var shortcuts: [TemplateShortcut] = []
    @Published var selectedScopeFilter: ShortcutScopeFilter = .all
    @Published var conflicts: [ShortcutConflict] = []

    enum ShortcutScopeFilter: Equatable {
        case all
        case global
        case app(PromptAppTarget)
    }

    private let shortcutManager: ShortcutManager
    private let conflictDetector: ShortcutConflictDetector
    private let promptListViewModel: PromptListViewModel
    private var cancellables = Set<AnyCancellable>()

    init(
        shortcutManager: ShortcutManager,
        conflictDetector: ShortcutConflictDetector,
        promptListViewModel: PromptListViewModel
    ) {
        self.shortcutManager = shortcutManager
        self.conflictDetector = conflictDetector
        self.promptListViewModel = promptListViewModel

        // Load shortcuts from manager
        self.shortcuts = shortcutManager.registeredShortcuts

        // Detect initial conflicts
        detectConflicts()

        // Observe template changes for cleanup
        observeTemplateChanges()
    }

    var displayedTemplatesWithShortcuts: [TemplateWithShortcuts] {
        var result: [TemplateWithShortcuts] = []

        for template in promptListViewModel.allTemplates {
            let templateShortcuts = shortcuts.filter { $0.templateId == template.id }

            // Apply scope filter
            let filteredShortcuts: [TemplateShortcut]
            switch selectedScopeFilter {
            case .all:
                filteredShortcuts = templateShortcuts
            case .global:
                filteredShortcuts = templateShortcuts.filter { shortcut in
                    if case .global = shortcut.scope { return true }
                    return false
                }
            case .app(let target):
                filteredShortcuts = templateShortcuts.filter { shortcut in
                    if case .app(let shortcutTarget) = shortcut.scope {
                        return shortcutTarget == target
                    }
                    return false
                }
            }

            // Only include templates that have shortcuts matching the filter
            // or include all templates if filter is .all
            if selectedScopeFilter == .all || !filteredShortcuts.isEmpty {
                result.append(TemplateWithShortcuts(
                    template: template,
                    shortcuts: filteredShortcuts
                ))
            }
        }

        return result
    }

    var uniqueAppTargets: [PromptAppTarget] {
        var targets = Set<PromptAppTarget>()

        for shortcut in shortcuts {
            if case .app(let target) = shortcut.scope {
                targets.insert(target)
            }
        }

        return Array(targets).sorted { $0.displayName < $1.displayName }
    }

    func addShortcut(templateId: UUID, keyCombo: KeyCombo, scope: ShortcutScope) {
        let shortcut = TemplateShortcut(
            templateId: templateId,
            keyCombo: keyCombo,
            scope: scope
        )

        shortcuts.append(shortcut)
        shortcutManager.registerShortcut(shortcut)
        detectConflicts()
    }

    func deleteShortcut(id: UUID) {
        shortcuts.removeAll { $0.id == id }
        shortcutManager.unregisterShortcut(id: id)
        detectConflicts()
    }

    func toggleShortcutEnabled(id: UUID) {
        guard let index = shortcuts.firstIndex(where: { $0.id == id }) else { return }

        var updatedShortcut = shortcuts[index]
        updatedShortcut.isEnabled.toggle()
        updatedShortcut.modifiedAt = Date()

        shortcuts[index] = updatedShortcut
        shortcutManager.updateShortcut(updatedShortcut)
        detectConflicts()
    }

    func updateShortcut(_ shortcut: TemplateShortcut) {
        guard let index = shortcuts.firstIndex(where: { $0.id == shortcut.id }) else { return }

        var updatedShortcut = shortcut
        updatedShortcut.modifiedAt = Date()

        shortcuts[index] = updatedShortcut
        shortcutManager.updateShortcut(updatedShortcut)
        detectConflicts()
    }

    private func detectConflicts() {
        conflicts = conflictDetector.detectConflicts(in: shortcuts)
    }

    private func observeTemplateChanges() {
        promptListViewModel.$allTemplates
            .sink { [weak self] templates in
                self?.cleanupOrphanedShortcuts(templates: templates)
            }
            .store(in: &cancellables)
    }

    private func cleanupOrphanedShortcuts(templates: [PromptTemplate]) {
        let templateIds = Set(templates.map { $0.id })
        let orphanedShortcuts = shortcuts.filter { !templateIds.contains($0.templateId) }

        for orphaned in orphanedShortcuts {
            deleteShortcut(id: orphaned.id)
        }
    }
}

// MARK: - Template With Shortcuts

struct TemplateWithShortcuts: Identifiable {
    let template: PromptTemplate
    let shortcuts: [TemplateShortcut]

    var id: UUID { template.id }
}
