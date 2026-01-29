//
//  CollectionRow.swift
//  Promptist
//
//  Collection row with folder icon and arrow for navigation
//

import SwiftUI

struct CollectionRow: View {
    let collection: PromptTemplateCollection
    let promptCount: Int
    let onTap: () -> Void

    @State private var isHovered: Bool = false

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                Image(systemName: "folder.fill")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(.accent)

                Text(collection.name)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)

                Spacer()

                Text("\(promptCount)")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.secondary)

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .frame(height: 48)
            .background(isHovered ? Color.primary.opacity(0.08) : Color.clear)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            withAnimation(.easeOut(duration: 0.15)) {
                isHovered = hovering
            }
        }
    }
}

#Preview {
    VStack(spacing: 0) {
        CollectionRow(
            collection: PromptTemplateCollection(name: "Development", sortOrder: 0),
            promptCount: 5,
            onTap: {
                print("Tapped Development")
            }
        )
        CollectionRow(
            collection: PromptTemplateCollection(name: "Writing", sortOrder: 1),
            promptCount: 3,
            onTap: {
                print("Tapped Writing")
            }
        )
    }
    .frame(width: 540)
    .background(Color(nsColor: .windowBackgroundColor))
}
