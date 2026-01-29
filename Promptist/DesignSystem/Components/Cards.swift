import SwiftUI

// MARK: - Card Background

struct CardBackground<Content: View>: View {
    let content: Content
    let padding: EdgeInsets
    let elevation: ShadowElevation

    enum ShadowElevation {
        case none
        case sm
        case md
        case lg

        var shadow: (color: Color, radius: CGFloat, x: CGFloat, y: CGFloat) {
            switch self {
            case .none: return DesignTokens.Shadow.none
            case .sm: return DesignTokens.Shadow.sm
            case .md: return DesignTokens.Shadow.md
            case .lg: return DesignTokens.Shadow.lg
            }
        }
    }

    init(
        padding: EdgeInsets = DesignTokens.Layout.edgeInsetNormal,
        elevation: ShadowElevation = .sm,
        @ViewBuilder content: () -> Content
    ) {
        self.content = content()
        self.padding = padding
        self.elevation = elevation
    }

    var body: some View {
        content
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: DesignTokens.Radius.lg, style: .continuous)
                    .fill(DesignTokens.Colors.backgroundElevated)
            )
            .overlay(
                RoundedRectangle(cornerRadius: DesignTokens.Radius.lg, style: .continuous)
                    .stroke(DesignTokens.Colors.borderSubtle, lineWidth: DesignTokens.BorderWidth.default)
            )
            .shadow(
                color: elevation.shadow.color,
                radius: elevation.shadow.radius,
                x: elevation.shadow.x,
                y: elevation.shadow.y
            )
    }
}

// MARK: - List Card Row

struct ListCardRow<Content: View>: View {
    let content: Content
    let isHoverable: Bool
    let action: (() -> Void)?

    @State private var isHovering = false

    init(
        isHoverable: Bool = true,
        action: (() -> Void)? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.content = content()
        self.isHoverable = isHoverable
        self.action = action
    }

    var body: some View {
        Group {
            if let action {
                Button(action: action) {
                    rowContent
                }
                .buttonStyle(.plain)
            } else {
                rowContent
            }
        }
        .onHover { hovering in
            if isHoverable {
                withAnimation(DesignTokens.Animation.normal) {
                    isHovering = hovering
                }
            }
        }
    }

    private var rowContent: some View {
        content
            .padding(.horizontal, DesignTokens.Spacing.md)
            .padding(.vertical, DesignTokens.Spacing.sm)
            .background(
                RoundedRectangle(cornerRadius: DesignTokens.Radius.md, style: .continuous)
                    .fill(isHovering ? DesignTokens.Colors.hoverBackground : Color.clear)
            )
            .overlay(
                RoundedRectangle(cornerRadius: DesignTokens.Radius.md, style: .continuous)
                    .stroke(
                        isHovering ? DesignTokens.Colors.borderDefault : DesignTokens.Colors.borderSubtle,
                        lineWidth: DesignTokens.BorderWidth.subtle
                    )
            )
    }
}
