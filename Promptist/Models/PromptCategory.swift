//
//  PromptCategory.swift
//  Promptist
//
//  Represents a category for classifying prompt templates with hierarchical support.
//

import Foundation

/// Represents a category for classifying prompt templates.
/// Categories support a 2-level hierarchy: major categories (parentId == nil) and subcategories.
struct PromptCategory: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var parentId: UUID?      // nil = root (major category)
    var sortOrder: Int
    var icon: String         // SF Symbol name

    init(
        id: UUID = UUID(),
        name: String,
        parentId: UUID? = nil,
        sortOrder: Int = 0,
        icon: String = "folder"
    ) {
        self.id = id
        self.name = name
        self.parentId = parentId
        self.sortOrder = sortOrder
        self.icon = icon
    }

    /// Whether this is a root (major) category
    var isRootCategory: Bool { parentId == nil }
}

// MARK: - Default System Categories

/// Provides the default category hierarchy for the app.
/// 6 major categories with 28 subcategories total.
enum DefaultCategories {

    /// Creates the complete default category hierarchy.
    /// Returns a tuple of (allCategories, generalQAId) where generalQAId is used for migration.
    static func createDefaultHierarchy() -> (categories: [PromptCategory], generalQACategoryId: UUID) {
        var categories: [PromptCategory] = []
        var sortOrder = 0

        // Helper to create a major category with subcategories
        func addMajorCategory(
            name: String,
            icon: String,
            subcategories: [(name: String, icon: String)]
        ) -> UUID {
            let majorId = UUID()
            categories.append(PromptCategory(
                id: majorId,
                name: name,
                parentId: nil,
                sortOrder: sortOrder,
                icon: icon
            ))
            sortOrder += 1

            var subSortOrder = 0
            for sub in subcategories {
                categories.append(PromptCategory(
                    id: UUID(),
                    name: sub.name,
                    parentId: majorId,
                    sortOrder: subSortOrder,
                    icon: sub.icon
                ))
                subSortOrder += 1
            }

            return majorId
        }

        // 1. Coding
        _ = addMajorCategory(
            name: "Coding",
            icon: "chevron.left.forwardslash.chevron.right",
            subcategories: [
                ("Code Review", "eye.circle"),
                ("Debugging", "ant"),
                ("Refactoring", "arrow.triangle.2.circlepath"),
                ("Testing", "checkmark.shield"),
                ("Explain Code", "questionmark.circle"),
                ("Generate Code", "wand.and.stars"),
                ("Documentation", "doc.text")
            ]
        )

        // 2. Writing & Communication
        _ = addMajorCategory(
            name: "Writing & Communication",
            icon: "pencil.and.outline",
            subcategories: [
                ("Rewrite / Polish", "paintbrush"),
                ("Formal Writing", "doc.richtext"),
                ("Creative Writing", "sparkles"),
                ("Email", "envelope"),
                ("Translation", "globe"),
                ("Summarization", "text.alignleft")
            ]
        )

        // 3. Productivity
        _ = addMajorCategory(
            name: "Productivity",
            icon: "bolt.circle",
            subcategories: [
                ("Task Automation", "gear"),
                ("Meeting Notes", "note.text"),
                ("Brainstorming", "lightbulb"),
                ("Planning", "calendar"),
                ("Decision Support", "scale.3d")
            ]
        )

        // 4. Research & Analysis
        _ = addMajorCategory(
            name: "Research & Analysis",
            icon: "magnifyingglass.circle",
            subcategories: [
                ("Information Extraction", "doc.text.magnifyingglass"),
                ("Comparison", "arrow.left.arrow.right"),
                ("Market/Topic Research", "chart.bar.xaxis"),
                ("Critical Review", "text.badge.checkmark")
            ]
        )

        // 5. Image / Media Generation
        _ = addMajorCategory(
            name: "Image / Media Generation",
            icon: "photo.artframe",
            subcategories: [
                ("Image", "photo"),
                ("Video", "video"),
                ("Audio", "waveform")
            ]
        )

        // 6. General Utilities - capture the General Q&A id for migration
        let generalUtilitiesId = addMajorCategory(
            name: "General Utilities",
            icon: "square.grid.2x2",
            subcategories: [
                ("General Q&A", "questionmark.bubble"),
                ("Quick Commands", "command"),
                ("Daily Tools", "wrench.and.screwdriver")
            ]
        )

        // Find the General Q&A category id (first subcategory of General Utilities)
        let generalQAId = categories.first { $0.parentId == generalUtilitiesId && $0.name == "General Q&A" }?.id ?? UUID()

        return (categories, generalQAId)
    }
}
