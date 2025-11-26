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
        HStack(spacing: DesignTokens.Spacing.xs) {
            if let icon = app.icon {
                Image(nsImage: icon)
                    .resizable()
                    .scaledToFit()
                    .frame(width: DesignTokens.IconSize.sm, height: DesignTokens.IconSize.sm)
                    .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.xs, style: .continuous))
            }

            Text(app.name)
                .font(DesignTokens.Typography.label(DesignTokens.Typography.labelSmall))
                .foregroundColor(DesignTokens.Colors.foregroundPrimary)
                .lineLimit(1)

            if showRemoveButton, let onRemove {
                Button(action: onRemove) {
                    Image(systemName: "xmark")
                        .font(.system(size: DesignTokens.IconSize.xs, weight: .semibold))
                        .foregroundColor(DesignTokens.Colors.foregroundSecondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, DesignTokens.Spacing.sm)
        .padding(.vertical, DesignTokens.Spacing.xxs)
        .background(
            Capsule()
                .fill(isHovering ? DesignTokens.Colors.hoverBackground : DesignTokens.Colors.backgroundSecondary)
        )
        .overlay(
            Capsule()
                .stroke(DesignTokens.Colors.borderSubtle, lineWidth: 0.5)
        )
        .onHover { hovering in
            withAnimation(DesignTokens.Animation.normal) {
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
            HStack(spacing: DesignTokens.Spacing.xs) {
                ForEach(apps) { app in
                    AppPill(
                        app: app,
                        showRemoveButton: showRemoveButtons,
                        onRemove: onRemove != nil ? { onRemove?(app) } : nil
                    )
                }

                if let onAdd {
                    Button(action: onAdd) {
                        HStack(spacing: DesignTokens.Spacing.xxs) {
                            Image(systemName: "plus")
                                .font(.system(size: DesignTokens.IconSize.xs, weight: .semibold))
                            Text("Add")
                                .font(DesignTokens.Typography.label(DesignTokens.Typography.labelSmall))
                        }
                        .foregroundColor(DesignTokens.Colors.foregroundSecondary)
                        .padding(.horizontal, DesignTokens.Spacing.sm)
                        .padding(.vertical, DesignTokens.Spacing.xxs)
                        .background(
                            Capsule()
                                .strokeBorder(DesignTokens.Colors.borderDefault, lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}
