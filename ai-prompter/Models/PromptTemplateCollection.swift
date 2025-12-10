//
//  PromptTemplateCollection.swift
//  ai-prompter
//
//  Represents a collection that can contain multiple prompt templates
//

import Foundation

/// Represents a collection for organizing prompt templates
struct PromptTemplateCollection: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var sortOrder: Int

    init(
        id: UUID = UUID(),
        name: String,
        sortOrder: Int = 0
    ) {
        self.id = id
        self.name = name
        self.sortOrder = sortOrder
    }
}
