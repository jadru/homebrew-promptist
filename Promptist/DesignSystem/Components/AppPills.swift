import SwiftUI

// MARK: - App Pill

struct AppPill: View {
    let app: AppInfo
    let showRemoveButton: Bool
    let onRemove: (() -> Void)?

    @State private var isHovering = false

    init(app: AppInfo, showRemoveButton: Bool = false, onRemove: (() -> Void)? = nil) {
        self.app = app
        self.showRemoveButton = showRemoveButton
        self.onRemove = onRemove
    }

    var body: some View {
        HStack(spacing: 6) {
            if let icon = app.icon {
                Image(nsImage: icon)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 14, height: 14)
                    .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
            }

            Text(app.name)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(.primary)
                .lineLimit(1)

            if showRemoveButton, let onRemove {
                Button(action: onRemove) {
                    Image(systemName: "xmark")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            Capsule()
                .fill(isHovering ? AnyShapeStyle(Color.primary.opacity(0.08)) : AnyShapeStyle(.quaternary))
        )
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                isHovering = hovering
            }
        }
    }
}

// MARK: - App Pill Row

struct AppPillRow: View {
    let apps: [AppInfo]
    let showRemoveButtons: Bool
    let onRemove: ((AppInfo) -> Void)?
    let onAdd: (() -> Void)?

    init(
        apps: [AppInfo],
        showRemoveButtons: Bool = false,
        onRemove: ((AppInfo) -> Void)? = nil,
        onAdd: (() -> Void)? = nil
    ) {
        self.apps = apps
        self.showRemoveButtons = showRemoveButtons
        self.onRemove = onRemove
        self.onAdd = onAdd
    }

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                ForEach(apps) { app in
                    AppPill(
                        app: app,
                        showRemoveButton: showRemoveButtons,
                        onRemove: onRemove != nil ? { onRemove?(app) } : nil
                    )
                }

                if let onAdd {
                    Button(action: onAdd) {
                        HStack(spacing: 4) {
                            Image(systemName: "plus")
                                .font(.system(size: 12, weight: .semibold))
                            Text("Add")
                                .font(.system(size: 11, weight: .medium))
                        }
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .strokeBorder(Color.primary.opacity(0.15), lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}
