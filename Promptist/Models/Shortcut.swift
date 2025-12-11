import Foundation

// MARK: - Modifier Key

struct ModifierKey: OptionSet, Codable, Hashable {
    let rawValue: Int

    static let command = ModifierKey(rawValue: 1 << 0)
    static let option = ModifierKey(rawValue: 1 << 1)
    static let control = ModifierKey(rawValue: 1 << 2)
    static let shift = ModifierKey(rawValue: 1 << 3)

    var displayString: String {
        var result = ""

        // macOS standard order: Control, Option, Shift, Command
        if contains(.control) { result += "⌃" }
        if contains(.option) { result += "⌥" }
        if contains(.shift) { result += "⇧" }
        if contains(.command) { result += "⌘" }

        return result
    }

    var isEmpty: Bool {
        rawValue == 0
    }
}

// MARK: - Key Combo

struct KeyCombo: Codable, Hashable {
    let modifiers: ModifierKey
    let key: String // "P", "Return", "F1", etc.

    var displayString: String {
        "\(modifiers.displayString)\(key.uppercased())"
    }

    func conflicts(with other: KeyCombo) -> Bool {
        modifiers == other.modifiers && key.lowercased() == other.key.lowercased()
    }
}

// MARK: - Shortcut Scope

enum ShortcutScope: Codable, Hashable {
    case global
    case app(PromptAppTarget)

    var displayName: String {
        switch self {
        case .global:
            return "Global"
        case .app(let target):
            return target.displayName
        }
    }

    func overlaps(with other: ShortcutScope) -> Bool {
        switch (self, other) {
        case (.global, .global):
            return true
        case (.app(let a), .app(let b)):
            return a == b
        case (.global, .app), (.app, .global):
            return false // global and app-specific don't hard conflict
        }
    }
}

// MARK: - Template Shortcut

struct TemplateShortcut: Identifiable, Codable, Equatable {
    let id: UUID
    let templateId: UUID
    var keyCombo: KeyCombo
    var scope: ShortcutScope
    var isEnabled: Bool
    let createdAt: Date
    var modifiedAt: Date

    init(
        id: UUID = UUID(),
        templateId: UUID,
        keyCombo: KeyCombo,
        scope: ShortcutScope,
        isEnabled: Bool = true,
        createdAt: Date = Date(),
        modifiedAt: Date = Date()
    ) {
        self.id = id
        self.templateId = templateId
        self.keyCombo = keyCombo
        self.scope = scope
        self.isEnabled = isEnabled
        self.createdAt = createdAt
        self.modifiedAt = modifiedAt
    }
}
