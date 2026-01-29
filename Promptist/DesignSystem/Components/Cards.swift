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
            case .none: return (color: .clear, radius: 0, x: 0, y: 0)
            case .sm: return DesignTokens.Shadow.sm
            case .md: return DesignTokens.Shadow.md
            case .lg: return DesignTokens.Shadow.lg
            }
        }
    }

    init(
        padding: EdgeInsets = EdgeInsets(top: 12, leading: 12, bottom: 12, trailing: 12),
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
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(.regularMaterial)
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
                withAnimation(.easeInOut(duration: 0.2)) {
                    isHovering = hovering
                }
            }
        }
    }

    private var rowContent: some View {
        content
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(isHovering ? Color.primary.opacity(0.06) : Color.clear)
            )
    }
}
