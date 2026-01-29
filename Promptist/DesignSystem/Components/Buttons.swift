import SwiftUI

// MARK: - Action Button Variant

enum ActionButtonVariant {
    case primary
    case secondary
    case subtle
    case danger
}

// MARK: - Action Button

struct ActionButton: View {
    let title: String
    let icon: String?
    let variant: ActionButtonVariant
    let action: () -> Void

    @State private var isHovering = false
    @State private var isPressed = false

    init(
        _ title: String,
        icon: String? = nil,
        variant: ActionButtonVariant = .secondary,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.icon = icon
        self.variant = variant
        self.action = action
    }

    var body: some View {
        if #available(macOS 26.0, *) {
            glassButton
        } else {
            legacyButton
        }
    }

    @available(macOS 26.0, *)
    @ViewBuilder
    private var glassButton: some View {
        switch variant {
        case .primary:
            Button(action: action) { buttonLabel }
                .buttonStyle(.glassProminent)
        case .secondary:
            Button(action: action) { buttonLabel }
                .buttonStyle(.glass)
        case .subtle:
            Button(action: action) { buttonLabel }
                .buttonStyle(.plain)
        case .danger:
            legacyButton
        }
    }

    private var legacyButton: some View {
        Button(action: {
            isPressed = true
            action()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                isPressed = false
            }
        }) {
            buttonLabel
                .background(backgroundColor)
                .foregroundColor(foregroundColor)
                .cornerRadius(DesignTokens.Radius.md)
                .overlay(
                    RoundedRectangle(cornerRadius: DesignTokens.Radius.md)
                        .stroke(borderColor, lineWidth: variant == .subtle ? 0 : DesignTokens.BorderWidth.default)
                )
                .scaleEffect(isPressed ? 0.97 : 1.0)
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            withAnimation(DesignTokens.Animation.normal) {
                isHovering = hovering
            }
        }
        .animation(DesignTokens.Animation.fast, value: isPressed)
    }

    private var buttonLabel: some View {
        HStack(spacing: DesignTokens.Spacing.xs) {
            if let icon {
                Image(systemName: icon)
                    .font(.system(size: DesignTokens.IconSize.sm, weight: .medium))
            }
            Text(title)
                .font(DesignTokens.Typography.label())
        }
        .padding(.horizontal, DesignTokens.Spacing.md)
        .padding(.vertical, DesignTokens.Spacing.xs)
    }

    private var backgroundColor: Color {
        switch variant {
        case .primary:
            if isPressed {
                return DesignTokens.Colors.accentPressed
            } else if isHovering {
                return DesignTokens.Colors.accentHover
            } else {
                return DesignTokens.Colors.accentPrimary
            }
        case .secondary:
            if isPressed {
                return DesignTokens.Colors.pressedBackground
            } else if isHovering {
                return DesignTokens.Colors.hoverBackground
            } else {
                return DesignTokens.Colors.backgroundSecondary
            }
        case .subtle:
            if isPressed {
                return DesignTokens.Colors.pressedBackground
            } else if isHovering {
                return DesignTokens.Colors.hoverBackground
            } else {
                return Color.clear
            }
        case .danger:
            if isPressed {
                return DesignTokens.Colors.error.opacity(0.15)
            } else if isHovering {
                return DesignTokens.Colors.error.opacity(0.1)
            } else {
                return DesignTokens.Colors.backgroundSecondary
            }
        }
    }

    private var foregroundColor: Color {
        switch variant {
        case .primary:
            return .white
        case .secondary, .subtle:
            return DesignTokens.Colors.foregroundPrimary
        case .danger:
            return DesignTokens.Colors.error
        }
    }

    private var borderColor: Color {
        switch variant {
        case .primary:
            return Color.clear
        case .secondary:
            return isHovering ? DesignTokens.Colors.borderDefault : DesignTokens.Colors.borderSubtle
        case .subtle:
            return Color.clear
        case .danger:
            return isHovering ? DesignTokens.Colors.error.opacity(0.3) : DesignTokens.Colors.borderSubtle
        }
    }
}

// MARK: - Icon Button

struct IconButton: View {
    let icon: String
    let size: CGFloat
    let action: () -> Void

    @State private var isHovering = false

    init(icon: String, size: CGFloat = DesignTokens.IconSize.md, action: @escaping () -> Void) {
        self.icon = icon
        self.size = size
        self.action = action
    }

    var body: some View {
        if #available(macOS 26.0, *) {
            glassIconButton
        } else {
            legacyIconButton
        }
    }

    @available(macOS 26.0, *)
    private var glassIconButton: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: size, weight: .medium))
                .frame(width: size + 12, height: size + 12)
        }
        .buttonStyle(.glass)
    }

    private var legacyIconButton: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: size, weight: .medium))
                .foregroundColor(isHovering ? DesignTokens.Colors.foregroundPrimary : DesignTokens.Colors.foregroundSecondary)
                .frame(width: size + 12, height: size + 12)
                .background(
                    RoundedRectangle(cornerRadius: DesignTokens.Radius.sm)
                        .fill(isHovering ? DesignTokens.Colors.hoverBackground : Color.clear)
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
