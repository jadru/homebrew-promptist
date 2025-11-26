import SwiftUI

// MARK: - Prompt List Row

struct PromptListRow: View {
    let template: PromptTemplate
    let linkedAppsText: String?
    let isCompact: Bool
    let action: () -> Void

    @State private var isHovering = false

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: isCompact ? DesignTokens.Spacing.xs : DesignTokens.Spacing.sm) {
                HStack(alignment: .firstTextBaseline, spacing: DesignTokens.Spacing.sm) {
                    Text(template.title)
                        .font(DesignTokens.Typography.headline(isCompact ? 14 : 15))
                        .foregroundColor(DesignTokens.Colors.foregroundPrimary)
                        .lineLimit(1)

                    Spacer()

                    if let linkedAppsText {
                        Text(linkedAppsText)
                            .font(DesignTokens.Typography.caption(10))
                            .foregroundColor(DesignTokens.Colors.foregroundTertiary)
                            .lineLimit(1)
                    }
                }

                Text(template.content)
                    .font(DesignTokens.Typography.body(isCompact ? 12 : 13))
                    .foregroundColor(DesignTokens.Colors.foregroundSecondary)
                    .lineLimit(2)

                if !template.tags.isEmpty {
                    TagPillRow(tags: template.tags, isCompact: isCompact)
                }
            }
            .padding(.horizontal, DesignTokens.Spacing.md)
            .padding(.vertical, isCompact ? DesignTokens.Spacing.sm : DesignTokens.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: DesignTokens.Radius.md, style: .continuous)
                    .fill(isHovering ? DesignTokens.Colors.hoverBackground : Color.clear)
            )
            .overlay(
                RoundedRectangle(cornerRadius: DesignTokens.Radius.md, style: .continuous)
                    .stroke(
                        isHovering ? DesignTokens.Colors.borderDefault : DesignTokens.Colors.borderSubtle,
                        lineWidth: 0.5
                    )
            )
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            withAnimation(DesignTokens.Animation.normal) {
                isHovering = hovering
            }
        }
    }
}

// MARK: - Prompt Section Header

struct PromptSectionHeader: View {
    let title: String

    var body: some View {
        Text(title.uppercased())
            .font(DesignTokens.Typography.caption(DesignTokens.Typography.captionSmall, weight: .medium))
            .foregroundColor(DesignTokens.Colors.foregroundTertiary)
            .tracking(0.5)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, DesignTokens.Spacing.xxs)
            .padding(.top, DesignTokens.Spacing.sm)
            .padding(.bottom, DesignTokens.Spacing.xxs)
    }
}

// MARK: - Tag Pill Row

private struct TagPillRow: View {
    let tags: [String]
    let isCompact: Bool

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: DesignTokens.Spacing.xs) {
                ForEach(tags, id: \.self) { tag in
                    TagPill(text: tag, isCompact: isCompact)
                }
            }
        }
        .allowsHitTesting(false)
    }
}

private struct TagPill: View {
    let text: String
    let isCompact: Bool

    var body: some View {
        Text(text)
            .font(DesignTokens.Typography.caption(isCompact ? 10 : 11, weight: .medium))
            .foregroundColor(DesignTokens.Colors.accentPrimary)
            .padding(.horizontal, isCompact ? DesignTokens.Spacing.xs : DesignTokens.Spacing.sm)
            .padding(.vertical, DesignTokens.Spacing.xxs)
            .background(
                Capsule()
                    .fill(DesignTokens.Colors.accentPrimary.opacity(0.1))
            )
            .overlay(
                Capsule()
                    .stroke(DesignTokens.Colors.accentPrimary.opacity(0.2), lineWidth: 0.5)
            )
    }
}
