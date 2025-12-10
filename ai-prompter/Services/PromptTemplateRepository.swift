import Foundation

protocol PromptTemplateRepository {
    func loadTemplates() -> [PromptTemplate]
    func saveTemplates(_ templates: [PromptTemplate])
    func incrementUsageCount(for templateId: UUID)
    func updateTemplateSortOrder(templateId: UUID, newSortOrder: Int)
    func reorderTemplates(_ templateIds: [UUID])

    func loadCollections() -> [PromptTemplateCollection]
    func saveCollections(_ collections: [PromptTemplateCollection])
    func addCollection(_ collection: PromptTemplateCollection)
    func updateCollection(_ collection: PromptTemplateCollection)
    func deleteCollection(_ collectionId: UUID)
    func moveTemplateToCollection(templateId: UUID, collectionId: UUID?)
    func reorderCollections(_ collectionIds: [UUID])
}

/// Persists templates to a JSON file in Application Support.
final class FilePromptTemplateRepository: PromptTemplateRepository {
    private let fileURL: URL
    private let collectionsFileURL: URL
    private let fileManager: FileManager
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
        let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let directory = appSupport.appendingPathComponent("ai-prompter", isDirectory: true)
        fileURL = directory.appendingPathComponent("templates.json", isDirectory: false)
        collectionsFileURL = directory.appendingPathComponent("collections.json", isDirectory: false)

        if !fileManager.fileExists(atPath: directory.path) {
            try? fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        }

        // Migrate legacy groups.json to collections.json if needed
        migrateGroupsToCollectionsIfNeeded(directory: directory)
    }

    private func migrateGroupsToCollectionsIfNeeded(directory: URL) {
        let legacyGroupsURL = directory.appendingPathComponent("groups.json", isDirectory: false)
        guard fileManager.fileExists(atPath: legacyGroupsURL.path),
              !fileManager.fileExists(atPath: collectionsFileURL.path) else {
            return
        }

        // Copy groups.json to collections.json (same format)
        try? fileManager.copyItem(at: legacyGroupsURL, to: collectionsFileURL)
    }

    func loadTemplates() -> [PromptTemplate] {
        guard fileManager.fileExists(atPath: fileURL.path) else {
            let defaults = defaultTemplates()
            saveTemplates(defaults)
            return defaults
        }

        do {
            let data = try Data(contentsOf: fileURL)
            let decoded = try decoder.decode([PromptTemplate].self, from: data)
            return decoded.isEmpty ? seedDefaults() : decoded
        } catch {
            return seedDefaults()
        }
    }

    func saveTemplates(_ templates: [PromptTemplate]) {
        do {
            let data = try encoder.encode(templates)
            try data.write(to: fileURL, options: [.atomic])
        } catch {
            // Persisting failures shouldn't crash the menu bar app; they can be logged later.
        }
    }

    func incrementUsageCount(for templateId: UUID) {
        var templates = loadTemplates()
        if let index = templates.firstIndex(where: { $0.id == templateId }) {
            templates[index].usageCount += 1
            templates[index].lastUsedAt = Date()
            saveTemplates(templates)
        }
    }

    func updateTemplateSortOrder(templateId: UUID, newSortOrder: Int) {
        var templates = loadTemplates()
        if let index = templates.firstIndex(where: { $0.id == templateId }) {
            templates[index].sortOrder = newSortOrder
            saveTemplates(templates)
        }
    }

    func reorderTemplates(_ templateIds: [UUID]) {
        var templates = loadTemplates()
        for (newOrder, templateId) in templateIds.enumerated() {
            if let index = templates.firstIndex(where: { $0.id == templateId }) {
                templates[index].sortOrder = newOrder
            }
        }
        saveTemplates(templates)
    }

    // MARK: - Collection Management

    func loadCollections() -> [PromptTemplateCollection] {
        guard fileManager.fileExists(atPath: collectionsFileURL.path) else {
            return []
        }

        do {
            let data = try Data(contentsOf: collectionsFileURL)
            let decoded = try decoder.decode([PromptTemplateCollection].self, from: data)
            return decoded
        } catch {
            return []
        }
    }

    func saveCollections(_ collections: [PromptTemplateCollection]) {
        do {
            let data = try encoder.encode(collections)
            try data.write(to: collectionsFileURL, options: [.atomic])
        } catch {
            // Persisting failures shouldn't crash the menu bar app; they can be logged later.
        }
    }

    func addCollection(_ collection: PromptTemplateCollection) {
        var collections = loadCollections()
        collections.append(collection)
        saveCollections(collections)
    }

    func updateCollection(_ collection: PromptTemplateCollection) {
        var collections = loadCollections()
        if let index = collections.firstIndex(where: { $0.id == collection.id }) {
            collections[index] = collection
            saveCollections(collections)
        }
    }

    func deleteCollection(_ collectionId: UUID) {
        var collections = loadCollections()
        collections.removeAll { $0.id == collectionId }
        saveCollections(collections)

        // Remove collectionId from all templates in this collection
        var templates = loadTemplates()
        for index in templates.indices {
            if templates[index].collectionId == collectionId {
                templates[index].collectionId = nil
            }
        }
        saveTemplates(templates)
    }

    func moveTemplateToCollection(templateId: UUID, collectionId: UUID?) {
        var templates = loadTemplates()
        if let index = templates.firstIndex(where: { $0.id == templateId }) {
            templates[index].collectionId = collectionId
            saveTemplates(templates)
        }
    }

    func reorderCollections(_ collectionIds: [UUID]) {
        var collections = loadCollections()
        for (newOrder, collectionId) in collectionIds.enumerated() {
            if let index = collections.firstIndex(where: { $0.id == collectionId }) {
                collections[index].sortOrder = newOrder
            }
        }
        saveCollections(collections)
    }

    private func seedDefaults() -> [PromptTemplate] {
        let defaults = defaultTemplates()
        saveTemplates(defaults)
        return defaults
    }

    private func defaultTemplates() -> [PromptTemplate] {
        return [
            PromptTemplate(
                id: UUID(),
                title: "Summarize",
                content: "Summarize the selected content in 3 bullet points.",
                tags: ["summary", "quick"],
                linkedApps: [.tracked(.chatGPT)],
                sortOrder: 1
            ),
            PromptTemplate(
                id: UUID(),
                title: "Polish Korean",
                content: "이 문장을 더 명확하고 자연스럽게 다듬어 주세요.",
                tags: ["ko", "edit"],
                linkedApps: [],
                sortOrder: 2
            ),
            PromptTemplate(
                id: UUID(),
                title: "Bug Hunt",
                content: "Review the code snippet for potential bugs and risky edge cases.",
                tags: ["code", "review"],
                linkedApps: [.tracked(.cursor), .tracked(.conductor)],
                sortOrder: 3
            )
        ]
    }
}
