import SwiftUI

struct ShortcutBadge: View {
    let count: Int
    let action: () -> Void

    @State private var isHovering = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 2) {
                Image(systemName: "command")
                    .font(.system(size: 10, weight: .medium))
                Text("\(count)")
                    .font(DesignTokens.Typography.caption(10, weight: .medium))
            }
            .foregroundColor(DesignTokens.Colors.accentPrimary)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(
                Capsule()
                    .fill(
                        isHovering ?
                            DesignTokens.Colors.accentPrimary.opacity(0.15) :
                            DesignTokens.Colors.accentPrimary.opacity(0.1)
                    )
            )
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            withAnimation(DesignTokens.Animation.fast) {
                isHovering = hovering
            }
        }
        .help("View shortcuts for this template")
    }
}
