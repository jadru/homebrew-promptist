//
//  PromptPreviewPanel.swift
//  ai-prompter
//
//  Side panel showing full prompt content preview on hover
//

import SwiftUI

struct PromptPreviewPanel: View {
    let prompt: PromptTemplate?
    let shortcut: TemplateShortcut?

    @EnvironmentObject private var languageSettings: LanguageSettings

    private let tokens = LauncherDesignTokens.self

    var body: some View {
        Group {
            if let prompt = prompt {
                previewContent(for: prompt)
            } else {
                emptyState
            }
        }
        .frame(width: Layout.panelWidth)
        .frame(maxHeight: .infinity)
        .background(tokens.Colors.popoverBackground)
    }

    // MARK: - Preview Content

    @ViewBuilder
    private func previewContent(for prompt: PromptTemplate) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            header(for: prompt)

            Divider()
                .padding(.horizontal, Layout.padding)

            // Content
            ScrollView {
                VStack(alignment: .leading, spacing: Layout.sectionSpacing) {
                    // Prompt content
                    contentSection(prompt.content)

                    // Tags
                    if !prompt.tags.isEmpty {
                        tagsSection(prompt.tags)
                    }

                    // Metadata
                    metadataSection(for: prompt)
                }
                .padding(Layout.padding)
            }
        }
    }

    // MARK: - Header

    @ViewBuilder
    private func header(for prompt: PromptTemplate) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(prompt.title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(tokens.Colors.primaryText)
                    .lineLimit(2)

                Spacer()

                // Shortcut badge
                if let shortcut = shortcut, shortcut.isEnabled {
                    ShortcutKeyBadge(keyCombo: shortcut.keyCombo)
                }
            }

            // Usage info
            if prompt.usageCount > 0 {
                Text(L("preview.usage_count", args: prompt.usageCount))
                    .font(.system(size: 11))
                    .foregroundColor(tokens.Colors.tertiaryText)
            }
        }
        .padding(Layout.padding)
    }

    // MARK: - Content Section

    @ViewBuilder
    private func contentSection(_ content: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(L("preview.content"))
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(tokens.Colors.tertiaryText)
                .textCase(.uppercase)

            Text(content)
                .font(.system(size: 13))
                .foregroundColor(tokens.Colors.primaryText)
                .textSelection(.enabled)
                .lineSpacing(4)
        }
    }

    // MARK: - Tags Section

    @ViewBuilder
    private func tagsSection(_ tags: [String]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(L("preview.tags"))
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(tokens.Colors.tertiaryText)
                .textCase(.uppercase)

            FlowLayout(spacing: 6) {
                ForEach(tags, id: \.self) { tag in
                    Text(tag)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(tokens.Colors.tagText)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(tokens.Colors.tagBackground)
                        .cornerRadius(4)
                }
            }
        }
    }

    // MARK: - Metadata Section

    @ViewBuilder
    private func metadataSection(for prompt: PromptTemplate) -> some View {
        if prompt.lastUsedAt != nil || !prompt.linkedApps.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                Text(L("preview.info"))
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(tokens.Colors.tertiaryText)
                    .textCase(.uppercase)

                VStack(alignment: .leading, spacing: 4) {
                    // Last used
                    if let lastUsed = prompt.lastUsedAt {
                        HStack(spacing: 6) {
                            Image(systemName: "clock")
                                .font(.system(size: 10))
                            Text(L("preview.last_used", args: lastUsed.relativeString))
                                .font(.system(size: 11))
                        }
                        .foregroundColor(tokens.Colors.secondaryText)
                    }

                    // Linked apps
                    if !prompt.linkedApps.isEmpty {
                        HStack(spacing: 6) {
                            Image(systemName: "app.badge")
                                .font(.system(size: 10))
                            Text(prompt.linkedApps.map { $0.displayName }.joined(separator: ", "))
                                .font(.system(size: 11))
                                .lineLimit(1)
                        }
                        .foregroundColor(tokens.Colors.secondaryText)
                    }
                }
            }
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 32, weight: .light))
                .foregroundColor(tokens.Colors.tertiaryText)

            Text(L("preview.empty"))
                .font(.system(size: 13))
                .foregroundColor(tokens.Colors.secondaryText)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }

    // MARK: - Localization

    private func L(_ key: String, args: Any...) -> String {
        let localized = languageSettings.localized(key)
        if args.isEmpty {
            return localized
        }
        return String(format: localized, args.map { $0 as! CVarArg })
    }

    // MARK: - Layout Constants

    private enum Layout {
        static let panelWidth: CGFloat = 280
        static let padding: CGFloat = 16
        static let sectionSpacing: CGFloat = 20
    }
}

// MARK: - Flow Layout

private struct FlowLayout: Layout {
    let spacing: CGFloat

    init(spacing: CGFloat = 8) {
        self.spacing = spacing
    }

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = arrange(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrange(proposal: proposal, subviews: subviews)
        for (index, frame) in result.frames.enumerated() {
            subviews[index].place(at: CGPoint(x: bounds.minX + frame.minX, y: bounds.minY + frame.minY), proposal: .unspecified)
        }
    }

    private func arrange(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, frames: [CGRect]) {
        let maxWidth = proposal.width ?? .infinity
        var frames: [CGRect] = []
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)

            if x + size.width > maxWidth && x > 0 {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }

            frames.append(CGRect(origin: CGPoint(x: x, y: y), size: size))
            rowHeight = max(rowHeight, size.height)
            x += size.width + spacing
        }

        let totalHeight = y + rowHeight
        return (CGSize(width: maxWidth, height: totalHeight), frames)
    }
}

// MARK: - Date Extension

private extension Date {
    var relativeString: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: self, relativeTo: Date())
    }
}

#Preview {
    HStack(spacing: 0) {
        // List placeholder
        Color.gray.opacity(0.1)
            .frame(width: 300)

        Divider()

        // Preview panel
        PromptPreviewPanel(
            prompt: PromptTemplate(
                id: UUID(),
                title: "Code Review Request",
                content: "Please review this code for:\n\n1. Best practices and patterns\n2. Potential bugs or edge cases\n3. Performance improvements\n4. Security vulnerabilities\n\nProvide specific suggestions with code examples where applicable.",
                tags: ["code", "review", "development"],
                linkedApps: [.tracked(.cursor)],
                sortOrder: 0,
                usageCount: 15,
                lastUsedAt: Date().addingTimeInterval(-3600)
            ),
            shortcut: TemplateShortcut(
                templateId: UUID(),
                keyCombo: KeyCombo(modifiers: [.command, .option], key: "R"),
                scope: .global
            )
        )
        .environmentObject(LanguageSettings())
    }
    .frame(height: 400)
}
