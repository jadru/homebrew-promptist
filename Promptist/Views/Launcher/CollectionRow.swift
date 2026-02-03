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
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.accent)
                    .glassCircleBackground(size: 32, tint: .accentColor)

                Text(collection.name)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)

                Spacer()

                Text("\(promptCount)")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(
                        Capsule()
                            .fill(Color.primary.opacity(0.06))
                    )

                Image(systemName: "chevron.right")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.tertiary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .glassInteractiveRow(isHovered: isHovered, cornerRadius: 8)
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
