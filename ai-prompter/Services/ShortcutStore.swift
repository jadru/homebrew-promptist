import Foundation

// MARK: - Shortcut Store Protocol

protocol ShortcutStore {
    func loadShortcuts() -> [TemplateShortcut]
    func saveShortcuts(_ shortcuts: [TemplateShortcut])
}

// MARK: - File Shortcut Store

final class FileShortcutStore: ShortcutStore {
    private let fileURL: URL

    init() {
        let appSupport = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first!

        let appDir = appSupport.appendingPathComponent("ai-prompter", isDirectory: true)

        // Ensure directory exists
        try? FileManager.default.createDirectory(
            at: appDir,
            withIntermediateDirectories: true,
            attributes: nil
        )

        self.fileURL = appDir.appendingPathComponent("shortcuts.json")
    }

    func loadShortcuts() -> [TemplateShortcut] {
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            return []
        }

        guard let data = try? Data(contentsOf: fileURL) else {
            return []
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        guard let shortcuts = try? decoder.decode([TemplateShortcut].self, from: data) else {
            return []
        }

        return shortcuts
    }

    func saveShortcuts(_ shortcuts: [TemplateShortcut]) {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

        guard let data = try? encoder.encode(shortcuts) else {
            return
        }

        // Atomic write
        try? data.write(to: fileURL, options: .atomic)
    }
}
