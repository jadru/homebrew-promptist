//
//  PromptTemplateGroup.swift
//  ai-prompter
//
//  Represents a folder/group that can contain multiple prompt templates
//

import Foundation

/// Represents a group/folder for organizing prompt templates
struct PromptTemplateGroup: Identifiable, Codable, Hashable {
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
