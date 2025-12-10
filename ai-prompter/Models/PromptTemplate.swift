import Foundation

/// Represents a reusable prompt a user can copy quickly.
struct PromptTemplate: Identifiable, Codable, Hashable {
    let id: UUID
    var title: String
    var content: String
    var tags: [String]
    var linkedApps: [PromptAppTarget]
    var sortOrder: Int
    var usageCount: Int
    var lastUsedAt: Date?
    var collectionId: UUID?

    enum CodingKeys: String, CodingKey {
        case id
        case title
        case content
        case tags
        case linkedApps
        case linkedTrackedApps // Legacy key for backward compatibility.
        case sortOrder
        case usageCount
        case lastUsedAt
        case collectionId
        case groupId // Legacy key for backward compatibility
    }

    init(
        id: UUID,
        title: String,
        content: String,
        tags: [String],
        linkedApps: [PromptAppTarget],
        sortOrder: Int,
        usageCount: Int = 0,
        lastUsedAt: Date? = nil,
        collectionId: UUID? = nil
    ) {
        self.id = id
        self.title = title
        self.content = content
        self.tags = tags
        self.linkedApps = linkedApps
        self.sortOrder = sortOrder
        self.usageCount = usageCount
        self.lastUsedAt = lastUsedAt
        self.collectionId = collectionId
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        content = try container.decode(String.self, forKey: .content)
        tags = try container.decode([String].self, forKey: .tags)
        sortOrder = try container.decode(Int.self, forKey: .sortOrder)
        usageCount = try container.decodeIfPresent(Int.self, forKey: .usageCount) ?? 0
        lastUsedAt = try container.decodeIfPresent(Date.self, forKey: .lastUsedAt)
        // Try new key first, fallback to legacy key
        collectionId = try container.decodeIfPresent(UUID.self, forKey: .collectionId)
            ?? container.decodeIfPresent(UUID.self, forKey: .groupId)

        if let decoded = try? container.decode([PromptAppTarget].self, forKey: .linkedApps) {
            linkedApps = decoded
        } else if let legacy = try? container.decode([TrackedApp].self, forKey: .linkedTrackedApps) {
            linkedApps = legacy.map { .tracked($0) }
        } else {
            linkedApps = []
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(title, forKey: .title)
        try container.encode(content, forKey: .content)
        try container.encode(tags, forKey: .tags)
        try container.encode(linkedApps, forKey: .linkedApps)
        try container.encode(sortOrder, forKey: .sortOrder)
        try container.encode(usageCount, forKey: .usageCount)
        try container.encodeIfPresent(lastUsedAt, forKey: .lastUsedAt)
        try container.encodeIfPresent(collectionId, forKey: .collectionId)
    }
}
