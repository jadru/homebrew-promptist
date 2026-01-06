import Foundation

protocol PromptTemplateRepository {
    func loadTemplates() -> [PromptTemplate]
    func saveTemplates(_ templates: [PromptTemplate])
    func deleteTemplate(_ templateId: UUID)
    func deleteTemplates(_ templateIds: [UUID])
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

    // Category Management
    func loadCategories() -> [PromptCategory]
    func saveCategories(_ categories: [PromptCategory])
    func addCategory(_ category: PromptCategory)
    func updateCategory(_ category: PromptCategory)
    func deleteCategory(_ categoryId: UUID)
    func moveTemplateToCategory(templateId: UUID, categoryId: UUID?)
    func reorderCategories(_ categoryIds: [UUID])
    func generalQACategoryId() -> UUID?

    // Migration
    func migrateToV2IfNeeded()
}

/// Persists templates to a JSON file in Application Support.
final class FilePromptTemplateRepository: PromptTemplateRepository {
    private let fileURL: URL
    private let collectionsFileURL: URL
    private let categoriesFileURL: URL
    private let fileManager: FileManager
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    /// Shortcut store for cascade delete operations
    private lazy var shortcutStore: ShortcutStore = FileShortcutStore()

    init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
        let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let directory = appSupport.appendingPathComponent("Promptist", isDirectory: true)
        fileURL = directory.appendingPathComponent("templates.json", isDirectory: false)
        collectionsFileURL = directory.appendingPathComponent("collections.json", isDirectory: false)
        categoriesFileURL = directory.appendingPathComponent("categories.json", isDirectory: false)

        if !fileManager.fileExists(atPath: directory.path) {
            try? fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        }

        // Migrate legacy groups.json to collections.json if needed
        migrateGroupsToCollectionsIfNeeded(directory: directory)

        // Run v2 migration (categories + template categoryId assignment)
        migrateToV2IfNeeded()
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
            AppLogger.logPersistence("Loaded \(decoded.count) templates")
            return decoded.isEmpty ? seedDefaults() : decoded
        } catch {
            AppLogger.logPersistence("Failed to load templates, using defaults", level: .error, error: error)
            return seedDefaults()
        }
    }

    func saveTemplates(_ templates: [PromptTemplate]) {
        do {
            let data = try encoder.encode(templates)
            try data.write(to: fileURL, options: [.atomic])
            AppLogger.logPersistence("Saved \(templates.count) templates")
        } catch {
            AppLogger.logPersistence("Failed to save templates", level: .error, error: error)
        }
    }

    func deleteTemplate(_ templateId: UUID) {
        deleteTemplates([templateId])
    }

    func deleteTemplates(_ templateIds: [UUID]) {
        guard !templateIds.isEmpty else { return }

        var templates = loadTemplates()
        let initialCount = templates.count

        templates.removeAll { templateIds.contains($0.id) }

        let removedCount = initialCount - templates.count
        if removedCount > 0 {
            saveTemplates(templates)

            // Cascade delete: remove associated shortcuts
            shortcutStore.removeShortcuts(forTemplateIds: templateIds)

            AppLogger.logPersistence("Deleted \(removedCount) templates with cascade shortcut cleanup")
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
            AppLogger.logPersistence("Loaded \(decoded.count) collections")
            return decoded
        } catch {
            AppLogger.logPersistence("Failed to load collections", level: .error, error: error)
            return []
        }
    }

    func saveCollections(_ collections: [PromptTemplateCollection]) {
        do {
            let data = try encoder.encode(collections)
            try data.write(to: collectionsFileURL, options: [.atomic])
            AppLogger.logPersistence("Saved \(collections.count) collections")
        } catch {
            AppLogger.logPersistence("Failed to save collections", level: .error, error: error)
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
                keywords: ["summary", "quick"],
                linkedApps: [.tracked(.chatGPT)],
                sortOrder: 1
            ),
            PromptTemplate(
                id: UUID(),
                title: "Polish Korean",
                content: "이 문장을 더 명확하고 자연스럽게 다듬어 주세요.",
                keywords: ["ko", "edit"],
                linkedApps: [],
                sortOrder: 2
            ),
            PromptTemplate(
                id: UUID(),
                title: "Bug Hunt",
                content: "Review the code snippet for potential bugs and risky edge cases.",
                keywords: ["code", "review"],
                linkedApps: [.tracked(.cursor), .tracked(.conductor)],
                sortOrder: 3
            )
        ]
    }

    // MARK: - Category Management

    func loadCategories() -> [PromptCategory] {
        guard fileManager.fileExists(atPath: categoriesFileURL.path) else {
            let (defaults, _) = DefaultCategories.createDefaultHierarchy()
            saveCategories(defaults)
            return defaults
        }

        do {
            let data = try Data(contentsOf: categoriesFileURL)
            let decoded = try decoder.decode([PromptCategory].self, from: data)
            AppLogger.logPersistence("Loaded \(decoded.count) categories")
            return decoded.isEmpty ? seedDefaultCategories() : decoded
        } catch {
            AppLogger.logPersistence("Failed to load categories", level: .error, error: error)
            return seedDefaultCategories()
        }
    }

    func saveCategories(_ categories: [PromptCategory]) {
        do {
            let data = try encoder.encode(categories)
            try data.write(to: categoriesFileURL, options: [.atomic])
            AppLogger.logPersistence("Saved \(categories.count) categories")
        } catch {
            AppLogger.logPersistence("Failed to save categories", level: .error, error: error)
        }
    }

    func addCategory(_ category: PromptCategory) {
        var categories = loadCategories()
        categories.append(category)
        saveCategories(categories)
    }

    func updateCategory(_ category: PromptCategory) {
        var categories = loadCategories()
        if let index = categories.firstIndex(where: { $0.id == category.id }) {
            categories[index] = category
            saveCategories(categories)
        }
    }

    func deleteCategory(_ categoryId: UUID) {
        var categories = loadCategories()

        // Find all child categories to also delete
        let childIds = categories.filter { $0.parentId == categoryId }.map { $0.id }
        let idsToDelete = [categoryId] + childIds

        // Find fallback category (General Q&A) before deletion
        let fallbackCategoryId = categories.first { $0.name == "General Q&A" && $0.parentId != nil }?.id

        categories.removeAll { idsToDelete.contains($0.id) }
        saveCategories(categories)

        // Reassign templates from deleted categories to General Q&A (or nil as last resort)
        var templates = loadTemplates()
        var modified = false
        for index in templates.indices {
            if let templateCategoryId = templates[index].categoryId,
               idsToDelete.contains(templateCategoryId) {
                templates[index].categoryId = fallbackCategoryId
                modified = true
            }
        }
        if modified {
            saveTemplates(templates)
        }
    }

    func moveTemplateToCategory(templateId: UUID, categoryId: UUID?) {
        var templates = loadTemplates()
        if let index = templates.firstIndex(where: { $0.id == templateId }) {
            templates[index].categoryId = categoryId
            saveTemplates(templates)
        }
    }

    func reorderCategories(_ categoryIds: [UUID]) {
        var categories = loadCategories()
        for (newOrder, categoryId) in categoryIds.enumerated() {
            if let index = categories.firstIndex(where: { $0.id == categoryId }) {
                categories[index].sortOrder = newOrder
            }
        }
        saveCategories(categories)
    }

    private func seedDefaultCategories() -> [PromptCategory] {
        let (defaults, _) = DefaultCategories.createDefaultHierarchy()
        saveCategories(defaults)
        return defaults
    }

    // MARK: - V2 Migration

    func migrateToV2IfNeeded() {
        guard !UserDefaults.standard.bool(forKey: UserDefaultsKeys.v2MigrationComplete) else { return }

        // 1. Ensure default categories exist
        let (defaultCategories, generalQAId) = DefaultCategories.createDefaultHierarchy()

        // Check if categories file exists, if not create it
        if !fileManager.fileExists(atPath: categoriesFileURL.path) {
            saveCategories(defaultCategories)
        }

        // Verify categories were actually saved before proceeding
        let savedCategories = loadCategories()
        guard savedCategories.contains(where: { $0.id == generalQAId }) else {
            // Abort migration - don't mark as complete if categories weren't saved
            return
        }

        // 2. Assign all existing templates without categoryId to "General Q&A"
        var templates = loadTemplates()
        var modified = false

        for index in templates.indices {
            if templates[index].categoryId == nil {
                templates[index].categoryId = generalQAId
                modified = true
            }
        }

        if modified {
            saveTemplates(templates)
        }

        // 3. Mark migration as complete
        UserDefaults.standard.set(true, forKey: UserDefaultsKeys.v2MigrationComplete)
        AppLogger.logPersistence("V2 migration completed successfully")
    }

    /// Get the General Q&A category ID for fallback assignments
    func generalQACategoryId() -> UUID? {
        let categories = loadCategories()
        // Find General Q&A (it's a subcategory with parentId != nil)
        return categories.first { $0.name == "General Q&A" && $0.parentId != nil }?.id
    }
}
