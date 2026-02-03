//
//  PromptRow.swift
//  Promptist
//
//  Minimal prompt row with hover and selection states
//

import SwiftUI

struct PromptRow: View {
    let prompt: PromptTemplate
    let isSelected: Bool
    let shortcut: TemplateShortcut?
    let onExecute: () -> Void
    let onHover: ((Bool) -> Void)?

    @State private var isHovered = false
    @State private var showCopied = false

    @EnvironmentObject private var languageSettings: LanguageSettings

    init(
        prompt: PromptTemplate,
        isSelected: Bool,
        shortcut: TemplateShortcut? = nil,
        onExecute: @escaping () -> Void,
        onHover: ((Bool) -> Void)? = nil
    ) {
        self.prompt = prompt
        self.isSelected = isSelected
        self.shortcut = shortcut
        self.onExecute = onExecute
        self.onHover = onHover
    }

    var body: some View {
        Button(action: handleExecute) {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(prompt.title)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                        .truncationMode(.tail)

                    if !prompt.content.isEmpty {
                        Text(prompt.content)
                            .font(.system(size: 12))
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                            .truncationMode(.tail)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                if let shortcut = shortcut, shortcut.isEnabled {
                    ShortcutKeyBadge(keyCombo: shortcut.keyCombo)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .glassInteractiveRow(isSelected: isSelected, isHovered: isHovered, cornerRadius: 8)
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .contentShape(Rectangle())
            .overlay(copiedOverlay)
        }
        .buttonStyle(PromptRowButtonStyle(isSelected: isSelected))
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityHint(languageSettings.localized("accessibility.prompt_row_hint"))
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
        .onHover { hovering in
            withAnimation(.easeOut(duration: 0.15)) {
                isHovered = hovering
            }
            onHover?(hovering)
        }
    }

    private var accessibilityLabel: String {
        var label = prompt.title
        if !prompt.content.isEmpty {
            label += ", " + prompt.content.prefix(50)
        }
        if let shortcut = shortcut, shortcut.isEnabled {
            label += ", " + languageSettings.localized("accessibility.shortcut_prefix") + " " + shortcut.keyCombo.displayString
        }
        return label
    }

    @ViewBuilder
    private var copiedOverlay: some View {
        if showCopied {
            ZStack {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(.ultraThinMaterial)

                Text(languageSettings.localized("prompt_row.copied"))
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.primary)
            }
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .transition(.opacity)
        }
    }

    private func handleExecute() {
        withAnimation(.easeInOut(duration: 0.2)) {
            showCopied = true
        }

        Task { @MainActor in
            try? await Task.sleep(for: .seconds(0.2))
            withAnimation(.easeInOut(duration: 0.2)) {
                showCopied = false
            }
            try? await Task.sleep(for: .seconds(0.2))
            onExecute()
        }
    }

}

// MARK: - Button Style

private struct PromptRowButtonStyle: ButtonStyle {
    let isSelected: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.995 : 1.0)
            .animation(.easeInOut(duration: 0.12), value: configuration.isPressed)
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 2) {
        // Normal state
        PromptRow(
            prompt: PromptTemplate(
                id: UUID(),
                title: "Code Review",
                content: "Please review this code for best practices and potential issues.",
                keywords: ["dev", "review"],
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
                keywords: ["debug", "help", "urgent"],
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
                keywords: [],
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
                keywords: ["long", "test", "example", "many"],
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
