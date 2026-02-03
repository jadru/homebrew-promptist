import SwiftUI
import AppKit

// MARK: - OS Version Check

/// Check if running on macOS 26 or later (Tahoe with Liquid Glass)
var isLiquidGlassAvailable: Bool {
    if #available(macOS 26.0, *) {
        return true
    }
    return false
}

// MARK: - Design Tokens

/// Retained design tokens for Promptist.
/// Most tokens have been replaced by system styles (`.primary`, `.secondary`, `.quaternary`, etc.).
/// Only Shadow tokens remain for CardBackground elevation support.
enum DesignTokens {

    // MARK: - Shadows

    enum Shadow {
        static let none: (color: Color, radius: CGFloat, x: CGFloat, y: CGFloat) = (
            color: .clear, radius: 0, x: 0, y: 0
        )

        static var sm: (color: Color, radius: CGFloat, x: CGFloat, y: CGFloat) {
            if isLiquidGlassAvailable { return none }
            return (color: Color.black.opacity(0.15), radius: 4, x: 0, y: 2)
        }

        static var md: (color: Color, radius: CGFloat, x: CGFloat, y: CGFloat) {
            if isLiquidGlassAvailable {
                return (color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
            }
            return (color: Color.black.opacity(0.2), radius: 12, x: 0, y: 4)
        }

        static var lg: (color: Color, radius: CGFloat, x: CGFloat, y: CGFloat) {
            if isLiquidGlassAvailable {
                return (color: Color.black.opacity(0.08), radius: 8, x: 0, y: 3)
            }
            return (color: Color.black.opacity(0.25), radius: 20, x: 0, y: 6)
        }

        static let glassCard: (color: Color, radius: CGFloat, x: CGFloat, y: CGFloat) = (
            color: Color.black.opacity(0.06), radius: 6, x: 0, y: 2
        )
    }
}

// MARK: - Color Extensions

extension Color {
    /// Initialize Color from hex string
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }

    /// Initialize Color from hex integer
    init(hex: Int, alpha: Double = 1.0) {
        let red = Double((hex >> 16) & 0xFF) / 255.0
        let green = Double((hex >> 8) & 0xFF) / 255.0
        let blue = Double(hex & 0xFF) / 255.0

        self.init(
            .sRGB,
            red: red,
            green: green,
            blue: blue,
            opacity: alpha
        )
    }
}

// MARK: - NSColor Extensions

extension NSColor {
    /// Creates an NSColor from a SwiftUI Color
    static func fromSwiftUI(_ color: Color) -> NSColor {
        return NSColor(color)
    }

    convenience init(hex: Int, alpha: CGFloat = 1.0) {
        let red = CGFloat((hex >> 16) & 0xFF) / 255.0
        let green = CGFloat((hex >> 8) & 0xFF) / 255.0
        let blue = CGFloat(hex & 0xFF) / 255.0
        self.init(srgbRed: red, green: green, blue: blue, alpha: alpha)
    }
}

extension NSAppearance {
    var isDark: Bool {
        bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
    }
}

// MARK: - Liquid Glass View Modifier (macOS 26+)

/// Glass variant for Liquid Glass effects
enum GlassVariant {
    /// Standard glass - balanced transparency for general navigation elements
    case regular
    /// Clear glass - higher transparency for media-rich backgrounds
    case clear
    /// Prominent glass - tinted blue for primary call-to-action elements
    case prominent
    /// Tinted glass - glass with custom color tint for selected/active states
    case tinted(Color)
}

struct LiquidGlassModifier: ViewModifier {
    let variant: GlassVariant
    let isEnabled: Bool

    func body(content: Content) -> some View {
        if isEnabled {
            if #available(macOS 26.0, *) {
                applyGlass(content)
            } else {
                content
            }
        } else {
            content
        }
    }

    @available(macOS 26.0, *)
    @ViewBuilder
    private func applyGlass(_ content: Content) -> some View {
        switch variant {
        case .regular:
            content.glassEffect()
        case .clear:
            content.glassEffect(.clear)
        case .prominent:
            content.glassEffect(.regular.tint(.blue))
        case .tinted(let color):
            content.glassEffect(.regular.tint(color))
        }
    }
}

extension View {
    /// Applies Liquid Glass effect on macOS 26+
    /// - Parameters:
    ///   - variant: The glass style variant (regular, clear, or prominent)
    ///   - enabled: Whether the effect is active
    func liquidGlass(_ variant: GlassVariant = .regular, enabled: Bool = true) -> some View {
        modifier(LiquidGlassModifier(variant: variant, isEnabled: enabled))
    }

    /// Applies navigation-layer glass background on macOS 26+, opaque fallback on older OS
    @ViewBuilder
    func navigationBackground() -> some View {
        if #available(macOS 26.0, *) {
            self.glassEffect(.regular, in: Rectangle())
        } else {
            self.background(Color(nsColor: .windowBackgroundColor))
        }
    }
}

// MARK: - Glass Surface & Card Modifiers (macOS 26+)

extension View {
    /// Glass card background - for content cards with rounded corners
    /// macOS 26+: `.glassEffect()` / Fallback: `.regularMaterial`
    @ViewBuilder
    func glassCardBackground(cornerRadius: CGFloat = 10) -> some View {
        if #available(macOS 26.0, *) {
            self
                .background(
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(.clear)
                        .glassEffect(in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
                )
        } else {
            self
                .background(
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(.regularMaterial)
                )
                .shadow(
                    color: DesignTokens.Shadow.glassCard.color,
                    radius: DesignTokens.Shadow.glassCard.radius,
                    x: DesignTokens.Shadow.glassCard.x,
                    y: DesignTokens.Shadow.glassCard.y
                )
        }
    }

    /// Glass interactive row - for list rows with selected/hovered states
    /// Uses a stable single-view tree (no ViewBuilder branching) to prevent hover animation loops.
    /// Inside GlassEffectContainer, simple fills look glassy without needing per-row .glassEffect().
    func glassInteractiveRow(
        isSelected: Bool = false,
        isHovered: Bool = false,
        tint: Color = .accentColor,
        cornerRadius: CGFloat = 8
    ) -> some View {
        self.background(
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(isSelected ? tint.opacity(0.15) : (isHovered ? Color.primary.opacity(0.08) : Color.clear))
        )
    }

    /// Glass surface - for panels, sidebars, and large surface areas
    /// macOS 26+: `.ultraThinMaterial` for subtle frost / Fallback: `.quaternary`
    /// Note: Avoids `.glassEffect()` here to prevent glass-on-glass artifacts inside GlassEffectContainer.
    @ViewBuilder
    func glassSurface() -> some View {
        if #available(macOS 26.0, *) {
            self.background(.ultraThinMaterial)
        } else {
            self.background(.quaternary)
        }
    }

    /// Glass circle background - for icon containers
    @ViewBuilder
    func glassCircleBackground(size: CGFloat = 40, tint: Color? = nil) -> some View {
        if #available(macOS 26.0, *) {
            self
                .frame(width: size, height: size)
                .background(
                    Circle()
                        .fill(.clear)
                        .glassEffect(
                            tint.map { .regular.tint($0) } ?? .clear,
                            in: Circle()
                        )
                )
        } else {
            self
                .frame(width: size, height: size)
                .background(
                    Circle()
                        .fill(tint?.opacity(0.12) ?? Color.primary.opacity(0.06))
                )
        }
    }
}

// MARK: - Glass Effect Container (macOS 26+)

/// Wraps content in GlassEffectContainer on macOS 26+, pass-through on older OS.
/// Use this to group multiple adjacent glass elements and prevent glass-on-glass artifacts.
struct GlassContainer<Content: View>: View {
    let spacing: CGFloat?
    let content: Content

    init(spacing: CGFloat? = nil, @ViewBuilder content: () -> Content) {
        self.spacing = spacing
        self.content = content()
    }

    var body: some View {
        if #available(macOS 26.0, *) {
            GlassEffectContainer(spacing: spacing) { content }
        } else {
            content
        }
    }
}
