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
                    .font(.system(size: 10, weight: .medium))
            }
            .foregroundStyle(.accent)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(
                Capsule()
                    .fill(
                        isHovering ?
                            Color.accentColor.opacity(0.15) :
                            Color.accentColor.opacity(0.1)
                    )
            )
            .liquidGlass(.clear)
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovering = hovering
            }
        }
        .help("View shortcuts for this template")
    }
}
