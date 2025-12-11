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

                // Note: Keywords are NOT displayed in the UI per design spec.
                // They are only used for search matching.
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

