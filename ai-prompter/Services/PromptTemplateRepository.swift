import Foundation

protocol PromptTemplateRepository {
    func loadTemplates() -> [PromptTemplate]
    func saveTemplates(_ templates: [PromptTemplate])
}

/// Persists templates to a JSON file in Application Support.
final class FilePromptTemplateRepository: PromptTemplateRepository {
    private let fileURL: URL
    private let fileManager: FileManager
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
        let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let directory = appSupport.appendingPathComponent("ai-prompter", isDirectory: true)
        fileURL = directory.appendingPathComponent("templates.json", isDirectory: false)

        if !fileManager.fileExists(atPath: directory.path) {
            try? fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        }
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
