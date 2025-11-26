//
//  PromptRow.swift
//  ai-prompter
//
//  Minimal prompt row with hover and selection states
//

import SwiftUI

struct PromptRow: View {
    let prompt: PromptTemplate
    let isSelected: Bool
    let onExecute: () -> Void

    @State private var isHovered = false

    private let tokens = LauncherDesignTokens.self

    var body: some View {
        Button(action: onExecute) {
            HStack(spacing: 12) {
                // Content
                VStack(alignment: .leading, spacing: 4) {
                    // Title
                    Text(prompt.title)
                        .font(tokens.Typography.rowTitleFont)
                        .foregroundColor(tokens.Colors.primaryText)
                        .lineLimit(1)
                        .truncationMode(.tail)

                    // Subtitle (content preview)
                    if !prompt.content.isEmpty {
                        Text(prompt.content)
                            .font(tokens.Typography.rowSubtitleFont)
                            .foregroundColor(tokens.Colors.secondaryText)
                            .lineLimit(1)
                            .truncationMode(.tail)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                // Tags (show on hover or when selected)
                if (isHovered || isSelected) && !prompt.tags.isEmpty {
                    HStack(spacing: tokens.Layout.tagSpacing) {
                        ForEach(prompt.tags.prefix(2), id: \.self) { tag in
                            TagPill(text: tag)
                        }

                        if prompt.tags.count > 2 {
                            Text("+\(prompt.tags.count - 2)")
                                .font(tokens.Typography.tagFont)
                                .foregroundColor(tokens.Colors.tertiaryText)
                        }
                    }
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
                }
            }
            .padding(.horizontal, tokens.Layout.horizontalPadding)
            .padding(.vertical, tokens.Layout.verticalPadding)
            .frame(height: tokens.Layout.rowHeight)
            .background(rowBackground)
            .contentShape(Rectangle())
        }
        .buttonStyle(PromptRowButtonStyle(isSelected: isSelected))
        .onHover { hovering in
            withAnimation(tokens.Animation.hoverAnimation) {
                isHovered = hovering
            }
        }
    }

    @ViewBuilder
    private var rowBackground: some View {
        if isSelected {
            tokens.Colors.rowSelected
        } else if isHovered {
            tokens.Colors.rowHover
        } else {
            Color.clear
        }
    }
}

// MARK: - Tag Pill

private struct TagPill: View {
    let text: String

    private let tokens = LauncherDesignTokens.self

    var body: some View {
        Text(text)
            .font(tokens.Typography.tagFont)
            .foregroundColor(tokens.Colors.tagText)
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(tokens.Colors.tagBackground)
            .cornerRadius(4)
    }
}

// MARK: - Button Style

private struct PromptRowButtonStyle: ButtonStyle {
    let isSelected: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? LauncherDesignTokens.Interaction.rowPressedScale : 1.0)
            .animation(LauncherDesignTokens.Animation.selectionAnimation, value: configuration.isPressed)
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: LauncherDesignTokens.Layout.rowSpacing) {
        // Normal state
        PromptRow(
            prompt: PromptTemplate(
                id: UUID(),
                title: "Code Review",
                content: "Please review this code for best practices and potential issues.",
                tags: ["dev", "review"],
                linkedApps: [],
                sortOrder: 0
            ),
            isSelected: false,
            onExecute: {}
        )

        // Selected state
        PromptRow(
            prompt: PromptTemplate(
                id: UUID(),
                title: "Debug This",
                content: "Help me debug this issue I'm experiencing with...",
                tags: ["debug", "help", "urgent"],
                linkedApps: [],
                sortOrder: 1
            ),
            isSelected: true,
            onExecute: {}
        )

        // No content
        PromptRow(
            prompt: PromptTemplate(
                id: UUID(),
                title: "Short Prompt",
                content: "",
                tags: [],
                linkedApps: [],
                sortOrder: 2
            ),
            isSelected: false,
            onExecute: {}
        )

        // Long title
        PromptRow(
            prompt: PromptTemplate(
                id: UUID(),
                title: "This is a very long prompt title that should be truncated properly",
                content: "This is also a very long content preview that should be truncated to a single line without overflowing the container",
                tags: ["long", "test", "example", "many", "tags"],
                linkedApps: [],
                sortOrder: 3
            ),
            isSelected: false,
            onExecute: {}
        )
    }
    .frame(width: 540)
    .background(Color(nsColor: .windowBackgroundColor))
    .padding()
}
