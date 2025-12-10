//
//  CollectionRow.swift
//  ai-prompter
//
//  Collection row with folder icon and arrow for navigation
//

import SwiftUI

struct CollectionRow: View {
    let collection: PromptTemplateCollection
    let promptCount: Int
    let onTap: () -> Void

    @State private var isHovered: Bool = false

    private let tokens = LauncherDesignTokens.self

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Folder icon
                Image(systemName: "folder.fill")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(tokens.Colors.accent)

                // Collection name
                Text(collection.name)
                    .font(tokens.Typography.rowTitleFont)
                    .foregroundColor(tokens.Colors.primaryText)
                    .lineLimit(1)

                Spacer()

                // Prompt count
                Text("\(promptCount)")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(tokens.Colors.secondaryText)

                // Arrow icon
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(tokens.Colors.secondaryText)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .frame(height: tokens.Layout.rowHeight)
            .background(
                backgroundColor
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            withAnimation(tokens.Animation.hoverAnimation) {
                isHovered = hovering
            }
        }
    }

    private var backgroundColor: Color {
        if isHovered {
            return tokens.Colors.rowHover
        }
        return Color.clear
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
