import Foundation

// MARK: - Shortcut Store Protocol

protocol ShortcutStore {
    func loadShortcuts() -> [TemplateShortcut]
    func saveShortcuts(_ shortcuts: [TemplateShortcut])

    /// Removes shortcuts associated with deleted templates (cascade delete)
    func removeShortcuts(forTemplateIds templateIds: [UUID])

    /// Returns shortcut for a specific template if exists
    func shortcut(forTemplateId templateId: UUID) -> TemplateShortcut?
}

// MARK: - File Shortcut Store

final class FileShortcutStore: ShortcutStore {
    private let fileURL: URL

    init() {
        guard let appSupport = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first else {
            fatalError("Unable to locate Application Support directory")
        }

        let appDir = appSupport.appendingPathComponent("Promptist", isDirectory: true)

        // Ensure directory exists
        do {
            try FileManager.default.createDirectory(
                at: appDir,
                withIntermediateDirectories: true,
                attributes: nil
            )
        } catch {
            AppLogger.logPersistence("Failed to create shortcuts directory", level: .error, error: error)
        }

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
            AppLogger.logPersistence("Failed to encode shortcuts", level: .error)
            return
        }

        do {
            try data.write(to: fileURL, options: .atomic)
            AppLogger.logPersistence("Saved \(shortcuts.count) shortcuts")
        } catch {
            AppLogger.logPersistence("Failed to save shortcuts", level: .error, error: error)
        }
    }

    func removeShortcuts(forTemplateIds templateIds: [UUID]) {
        guard !templateIds.isEmpty else { return }

        var shortcuts = loadShortcuts()
        let initialCount = shortcuts.count

        shortcuts.removeAll { templateIds.contains($0.templateId) }

        let removedCount = initialCount - shortcuts.count
        if removedCount > 0 {
            saveShortcuts(shortcuts)
            AppLogger.logPersistence("Cascade deleted \(removedCount) shortcuts for deleted templates")
        }
    }

    func shortcut(forTemplateId templateId: UUID) -> TemplateShortcut? {
        loadShortcuts().first { $0.templateId == templateId }
    }
}
