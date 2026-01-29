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
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(borderColor, lineWidth: variant == .subtle ? 0 : 1)
                )
                .scaleEffect(isPressed ? 0.97 : 1.0)
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                isHovering = hovering
            }
        }
        .animation(.easeInOut(duration: 0.15), value: isPressed)
    }

    private var buttonLabel: some View {
        HStack(spacing: 6) {
            if let icon {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .medium))
            }
            Text(title)
                .font(.system(size: 12, weight: .medium))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
    }

    private var backgroundColor: Color {
        switch variant {
        case .primary:
            if isPressed {
                return Color.accentColor.opacity(0.8)
            } else if isHovering {
                return Color.accentColor.opacity(0.9)
            } else {
                return Color.accentColor
            }
        case .secondary:
            if isPressed {
                return Color.primary.opacity(0.12)
            } else if isHovering {
                return Color.primary.opacity(0.08)
            } else {
                return Color.primary.opacity(0.05)
            }
        case .subtle:
            if isPressed {
                return Color.primary.opacity(0.12)
            } else if isHovering {
                return Color.primary.opacity(0.08)
            } else {
                return Color.clear
            }
        case .danger:
            if isPressed {
                return Color.red.opacity(0.15)
            } else if isHovering {
                return Color.red.opacity(0.1)
            } else {
                return Color.primary.opacity(0.05)
            }
        }
    }

    private var foregroundColor: Color {
        switch variant {
        case .primary:
            return .white
        case .secondary, .subtle:
            return Color.primary
        case .danger:
            return Color.red
        }
    }

    private var borderColor: Color {
        switch variant {
        case .primary:
            return Color.clear
        case .secondary:
            return isHovering ? Color.primary.opacity(0.15) : Color.primary.opacity(0.1)
        case .subtle:
            return Color.clear
        case .danger:
            return isHovering ? Color.red.opacity(0.3) : Color.primary.opacity(0.1)
        }
    }
}

// MARK: - Icon Button

struct IconButton: View {
    let icon: String
    let size: CGFloat
    let action: () -> Void

    @State private var isHovering = false

    init(icon: String, size: CGFloat = 16, action: @escaping () -> Void) {
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
                .foregroundColor(isHovering ? Color.primary : Color.secondary)
                .frame(width: size + 12, height: size + 12)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(isHovering ? Color.primary.opacity(0.08) : Color.clear)
                )
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                isHovering = hovering
            }
        }
    }
}
