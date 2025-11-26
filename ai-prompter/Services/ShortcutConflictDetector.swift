import Foundation

// MARK: - Shortcut Conflict

struct ShortcutConflict: Identifiable {
    let id = UUID()
    let shortcut1: TemplateShortcut
    let shortcut2: TemplateShortcut
    let reason: String
}

// MARK: - Shortcut Conflict Detector

final class ShortcutConflictDetector {

    func detectConflicts(in shortcuts: [TemplateShortcut]) -> [ShortcutConflict] {
        var conflicts: [ShortcutConflict] = []

        // Compare all pairs
        for i in 0..<shortcuts.count {
            for j in (i+1)..<shortcuts.count {
                let shortcut1 = shortcuts[i]
                let shortcut2 = shortcuts[j]

                // Skip if key combos don't match
                guard shortcut1.keyCombo.conflicts(with: shortcut2.keyCombo) else {
                    continue
                }

                // Check if scopes conflict
                if shortcut1.scope.overlaps(with: shortcut2.scope) {
                    // Hard conflict: same keyCombo + same scope
                    conflicts.append(ShortcutConflict(
                        shortcut1: shortcut1,
                        shortcut2: shortcut2,
                        reason: "Same key combination and scope"
                    ))
                } else {
                    // Soft conflict: same keyCombo but different scope (app vs global)
                    // This is actually allowed - app-specific wins at runtime
                    // Could optionally add as a warning
                    // For now, we skip adding these as conflicts
                }
            }
        }

        return conflicts
    }
}
