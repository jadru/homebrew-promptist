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

/// Complete design token system for Promptist
/// Features a modern dark blue color palette inspired by premium macOS apps
/// Supports both light and dark modes with blue-tinted aesthetics
enum DesignTokens {

    // MARK: - Colors

    enum Colors {

        // MARK: - Blue Palette (Core Brand Colors)

        enum Blue {
            // Dark backgrounds
            static let navy950 = Color(hex: "#0a0e1a")      // Deepest navy
            static let navy900 = Color(hex: "#0f1629")      // Primary dark bg
            static let navy850 = Color(hex: "#141c33")      // Secondary dark bg
            static let navy800 = Color(hex: "#1a2541")      // Tertiary dark bg
            static let navy700 = Color(hex: "#243352")      // Elevated surfaces
            static let navy600 = Color(hex: "#2e4163")      // Borders, dividers

            // Accent blues
            static let accent500 = Color(hex: "#4a7dff")    // Primary accent
            static let accent400 = Color(hex: "#6b9aff")    // Accent hover
            static let accent300 = Color(hex: "#8fb3ff")    // Light accent
            static let accent200 = Color(hex: "#b3cdff")    // Very light accent

            // Text on dark
            static let text100 = Color(hex: "#e8ecf4")      // Primary text
            static let text200 = Color(hex: "#b4bfd4")      // Secondary text
            static let text300 = Color(hex: "#7b8aa8")      // Tertiary text
            static let text400 = Color(hex: "#4d5b78")      // Disabled text

            // Light mode - clean white-based palette
            static let lightBg = Color(hex: "#ffffff")      // Light mode primary bg (pure white)
            static let lightBg2 = Color(hex: "#f9fafb")     // Light mode secondary bg (near white)
            static let lightBg3 = Color(hex: "#f3f4f6")     // Light mode tertiary bg (subtle gray)
            static let lightBorder = Color(hex: "#e5e7eb")  // Light mode borders (neutral gray)

            // Light mode highlights (subtle blue tints for special elements)
            static let lightHighlight = Color(hex: "#eff6ff")  // Very subtle blue highlight
            static let lightHighlightHover = Color(hex: "#dbeafe")  // Hover state highlight
        }

        // MARK: - Dynamic Colors (Appearance-aware)

        /// Main window background
        static var backgroundPrimary: Color {
            if isLiquidGlassAvailable {
                return Color.clear
            }
            return Color(nsColor: NSColor(name: nil) { appearance in
                appearance.isDark ? NSColor.fromSwiftUI(Blue.navy900) : NSColor.fromSwiftUI(Blue.lightBg)
            })
        }

        /// Secondary surface (cards, panels)
        static var backgroundSecondary: Color {
            if isLiquidGlassAvailable {
                return Color(nsColor: NSColor(name: nil) { appearance in
                    appearance.isDark
                        ? NSColor.fromSwiftUI(Color.white.opacity(0.05))
                        : NSColor.fromSwiftUI(Color.black.opacity(0.03))
                })
            }
            return Color(nsColor: NSColor(name: nil) { appearance in
                appearance.isDark ? NSColor.fromSwiftUI(Blue.navy850) : NSColor.fromSwiftUI(Blue.lightBg2)
            })
        }

        /// Tertiary surface (nested cards, hover states)
        static var backgroundTertiary: Color {
            if isLiquidGlassAvailable {
                return Color(nsColor: NSColor(name: nil) { appearance in
                    appearance.isDark
                        ? NSColor.fromSwiftUI(Color.white.opacity(0.08))
                        : NSColor.fromSwiftUI(Color.black.opacity(0.05))
                })
            }
            return Color(nsColor: NSColor(name: nil) { appearance in
                appearance.isDark ? NSColor.fromSwiftUI(Blue.navy800) : NSColor.fromSwiftUI(Blue.lightBg3)
            })
        }

        /// Elevated surface (modals, popovers)
        static var backgroundElevated: Color {
            if isLiquidGlassAvailable {
                return Color(nsColor: NSColor(name: nil) { appearance in
                    appearance.isDark
                        ? NSColor.fromSwiftUI(Color.white.opacity(0.1))
                        : NSColor.fromSwiftUI(Color.black.opacity(0.03))
                })
            }
            return Color(nsColor: NSColor(name: nil) { appearance in
                appearance.isDark ? NSColor.fromSwiftUI(Blue.navy700) : NSColor.white
            })
        }

        /// Search bar / input background
        static var backgroundInput: Color {
            if isLiquidGlassAvailable {
                return Color(nsColor: NSColor(name: nil) { appearance in
                    appearance.isDark
                        ? NSColor.fromSwiftUI(Color.white.opacity(0.06))
                        : NSColor.fromSwiftUI(Color.black.opacity(0.04))
                })
            }
            return Color(nsColor: NSColor(name: nil) { appearance in
                appearance.isDark ? NSColor.fromSwiftUI(Blue.navy800.opacity(0.6)) : NSColor.fromSwiftUI(Blue.lightBg3)
            })
        }

        // MARK: Foreground Colors

        /// Primary text color
        static var foregroundPrimary: Color {
            Color(nsColor: NSColor(name: nil) { appearance in
                appearance.isDark ? NSColor.fromSwiftUI(Blue.text100) : NSColor(hex: 0x111827)  // Near black
            })
        }

        /// Secondary text color (less emphasis)
        static var foregroundSecondary: Color {
            Color(nsColor: NSColor(name: nil) { appearance in
                appearance.isDark ? NSColor.fromSwiftUI(Blue.text200) : NSColor(hex: 0x4b5563)  // Dark gray
            })
        }

        /// Tertiary text color (least emphasis)
        static var foregroundTertiary: Color {
            Color(nsColor: NSColor(name: nil) { appearance in
                appearance.isDark ? NSColor.fromSwiftUI(Blue.text300) : NSColor(hex: 0x6b7280)  // Medium gray
            })
        }

        /// Disabled text
        static var foregroundDisabled: Color {
            Color(nsColor: NSColor(name: nil) { appearance in
                appearance.isDark ? NSColor.fromSwiftUI(Blue.text400) : NSColor(hex: 0x9ca3af)  // Light gray
            })
        }

        // MARK: Borders

        /// Subtle border (cards, inputs)
        static var borderSubtle: Color {
            if isLiquidGlassAvailable {
                return Color(nsColor: NSColor(name: nil) { appearance in
                    appearance.isDark
                        ? NSColor.fromSwiftUI(Color.white.opacity(0.1))
                        : NSColor.fromSwiftUI(Color.black.opacity(0.06))
                })
            }
            return Color(nsColor: NSColor(name: nil) { appearance in
                appearance.isDark ? NSColor.fromSwiftUI(Blue.navy600.opacity(0.5)) : NSColor.fromSwiftUI(Blue.lightBorder.opacity(0.5))
            })
        }

        /// Default border
        static var borderDefault: Color {
            if isLiquidGlassAvailable {
                return Color(nsColor: NSColor(name: nil) { appearance in
                    appearance.isDark
                        ? NSColor.fromSwiftUI(Color.white.opacity(0.15))
                        : NSColor.fromSwiftUI(Color.black.opacity(0.1))
                })
            }
            return Color(nsColor: NSColor(name: nil) { appearance in
                appearance.isDark ? NSColor.fromSwiftUI(Blue.navy600) : NSColor.fromSwiftUI(Blue.lightBorder)
            })
        }

        /// Strong border (focus, emphasis)
        static var borderStrong: Color {
            Color(nsColor: NSColor(name: nil) { appearance in
                appearance.isDark ? NSColor.fromSwiftUI(Blue.accent500.opacity(0.6)) : NSColor.fromSwiftUI(Blue.accent500.opacity(0.4))
            })
        }

        /// Focus ring color
        static var borderFocus: Color {
            Blue.accent500
        }

        // MARK: Interactive States

        /// Hover state background
        static var hoverBackground: Color {
            if isLiquidGlassAvailable {
                return Color(nsColor: NSColor(name: nil) { appearance in
                    appearance.isDark
                        ? NSColor.fromSwiftUI(Color.white.opacity(0.12))
                        : NSColor.fromSwiftUI(Color.black.opacity(0.06))
                })
            }
            return Color(nsColor: NSColor(name: nil) { appearance in
                appearance.isDark ? NSColor.fromSwiftUI(Blue.navy700.opacity(0.6)) : NSColor.fromSwiftUI(Blue.lightBg3)
            })
        }

        /// Pressed state background
        static var pressedBackground: Color {
            if isLiquidGlassAvailable {
                return Color(nsColor: NSColor(name: nil) { appearance in
                    appearance.isDark
                        ? NSColor.fromSwiftUI(Color.white.opacity(0.18))
                        : NSColor.fromSwiftUI(Color.black.opacity(0.1))
                })
            }
            return Color(nsColor: NSColor(name: nil) { appearance in
                appearance.isDark ? NSColor.fromSwiftUI(Blue.navy700.opacity(0.8)) : NSColor.fromSwiftUI(Blue.lightBorder)
            })
        }

        /// Selected state background (for list items)
        static var selectedBackground: Color {
            if isLiquidGlassAvailable {
                return Color.accentColor.opacity(0.12)
            }
            return Color(nsColor: NSColor(name: nil) { appearance in
                appearance.isDark
                    ? NSColor.fromSwiftUI(Blue.accent500.opacity(0.15))
                    : NSColor.fromSwiftUI(Blue.lightHighlight)
            })
        }

        /// Selected state border
        static var selectedBorder: Color {
            Color(nsColor: NSColor(name: nil) { appearance in
                appearance.isDark
                    ? NSColor.fromSwiftUI(Blue.accent500.opacity(0.4))
                    : NSColor.fromSwiftUI(Blue.accent500.opacity(0.25))  // Subtle blue border
            })
        }

        // MARK: Accent Colors

        /// Primary accent (brand color, CTAs)
        static let accentPrimary = Blue.accent500

        /// Accent hover state
        static let accentHover = Blue.accent400

        /// Accent pressed state
        static let accentPressed: Color = {
            Color(nsColor: NSColor.fromSwiftUI(Blue.accent500).blended(
                withFraction: 0.2,
                of: .black
            ) ?? NSColor.fromSwiftUI(Blue.accent500))
        }()

        /// Light accent for badges, tags
        static let accentLight = Blue.accent200

        /// Accent text color
        static var accentText: Color {
            Color(nsColor: NSColor(name: nil) { appearance in
                appearance.isDark ? NSColor.fromSwiftUI(Blue.accent400) : NSColor.fromSwiftUI(Blue.accent500)
            })
        }

        // MARK: Semantic Colors

        static var success: Color {
            Color(nsColor: NSColor(name: nil) { appearance in
                appearance.isDark ? NSColor(hex: 0x4ade80) : NSColor(hex: 0x22c55e)
            })
        }

        static var warning: Color {
            Color(nsColor: NSColor(name: nil) { appearance in
                appearance.isDark ? NSColor(hex: 0xfbbf24) : NSColor(hex: 0xf59e0b)
            })
        }

        static var error: Color {
            Color(nsColor: NSColor(name: nil) { appearance in
                appearance.isDark ? NSColor(hex: 0xf87171) : NSColor(hex: 0xef4444)
            })
        }

        static var info: Color {
            Blue.accent400
        }

        // MARK: Static Grey Palette (Fallback/Legacy)

        enum Grey {
            static let grey50 = Color(hex: "#FAFAFA")
            static let grey100 = Color(hex: "#F5F5F5")
            static let grey200 = Color(hex: "#EBEBF0")
            static let grey300 = Color(hex: "#D1D1D6")
            static let grey400 = Color(hex: "#AEAEB2")
            static let grey500 = Color(hex: "#8E8E93")
            static let grey600 = Color(hex: "#6E6E73")
            static let grey700 = Color(hex: "#48484A")
            static let grey800 = Color(hex: "#3A3A3C")
            static let grey900 = Color(hex: "#2C2C2E")
            static let grey950 = Color(hex: "#1C1C1E")
        }

        // MARK: Shortcut Badge Colors

        static var shortcutBadgeBackground: Color {
            Color(nsColor: NSColor(name: nil) { appearance in
                appearance.isDark ? NSColor.fromSwiftUI(Blue.navy700) : NSColor.fromSwiftUI(Blue.lightHighlight)
            })
        }

        static var shortcutBadgeText: Color {
            Color(nsColor: NSColor(name: nil) { appearance in
                appearance.isDark ? NSColor.fromSwiftUI(Blue.accent400) : NSColor.fromSwiftUI(Blue.accent500)
            })
        }

        // MARK: Card Colors (for light mode)

        static var cardBackground: Color {
            if isLiquidGlassAvailable {
                return Color(nsColor: NSColor(name: nil) { appearance in
                    appearance.isDark
                        ? NSColor.fromSwiftUI(Color.white.opacity(0.07))
                        : NSColor.fromSwiftUI(Color.white.opacity(0.85))
                })
            }
            return Color(nsColor: NSColor(name: nil) { appearance in
                appearance.isDark ? NSColor.fromSwiftUI(Blue.navy850) : NSColor.white
            })
        }

        static var cardBorder: Color {
            if isLiquidGlassAvailable {
                return Color(nsColor: NSColor(name: nil) { appearance in
                    appearance.isDark
                        ? NSColor.fromSwiftUI(Color.white.opacity(0.1))
                        : NSColor.fromSwiftUI(Color.black.opacity(0.06))
                })
            }
            return Color(nsColor: NSColor(name: nil) { appearance in
                appearance.isDark ? NSColor.fromSwiftUI(Blue.navy600.opacity(0.5)) : NSColor.fromSwiftUI(Blue.lightBorder)
            })
        }
    }

    // MARK: - Typography

    enum Typography {

        // MARK: Font Sizes

        static let displayLarge: CGFloat = 28
        static let displayMedium: CGFloat = 24
        static let displaySmall: CGFloat = 20

        static let headlineLarge: CGFloat = 18
        static let headlineMedium: CGFloat = 16
        static let headlineSmall: CGFloat = 14

        static let bodyLarge: CGFloat = 15
        static let bodyMedium: CGFloat = 14
        static let bodySmall: CGFloat = 13

        static let labelLarge: CGFloat = 13
        static let labelMedium: CGFloat = 12
        static let labelSmall: CGFloat = 11

        static let captionLarge: CGFloat = 12
        static let captionMedium: CGFloat = 11
        static let captionSmall: CGFloat = 10

        // MARK: Font Weights

        static let weightThin: Font.Weight = .thin
        static let weightRegular: Font.Weight = .regular
        static let weightMedium: Font.Weight = .medium
        static let weightSemibold: Font.Weight = .semibold
        static let weightBold: Font.Weight = .bold

        // MARK: Line Heights

        static let lineHeightTight: CGFloat = 1.2
        static let lineHeightNormal: CGFloat = 1.5
        static let lineHeightRelaxed: CGFloat = 1.75

        // MARK: Fonts

        static func display(_ size: CGFloat = displayMedium, weight: Font.Weight = .bold) -> Font {
            .system(size: size, weight: weight)
        }

        static func headline(_ size: CGFloat = headlineMedium, weight: Font.Weight = .semibold) -> Font {
            .system(size: size, weight: weight)
        }

        static func body(_ size: CGFloat = bodyMedium, weight: Font.Weight = .regular) -> Font {
            .system(size: size, weight: weight)
        }

        static func label(_ size: CGFloat = labelMedium, weight: Font.Weight = .medium) -> Font {
            .system(size: size, weight: weight)
        }

        static func caption(_ size: CGFloat = captionMedium, weight: Font.Weight = .regular) -> Font {
            .system(size: size, weight: weight)
        }

        static func mono(_ size: CGFloat = bodyMedium, weight: Font.Weight = .regular) -> Font {
            .system(size: size, weight: weight, design: .monospaced)
        }
    }

    // MARK: - Spacing

    enum Spacing {
        static let micro: CGFloat = 2
        static let xxs: CGFloat = 4
        static let xs: CGFloat = 6
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        static let xl: CGFloat = 20
        static let xxl: CGFloat = 24
        static let xxxl: CGFloat = 32
        static let huge: CGFloat = 40
        static let massive: CGFloat = 48

        // MARK: Adaptive Spacing for Liquid Glass (macOS 26+)

        /// Returns larger spacing on macOS 26+ for liquid glass aesthetics
        static func adaptive(_ base: CGFloat) -> CGFloat {
            if isLiquidGlassAvailable {
                return base * 1.25
            }
            return base
        }

        static var adaptiveSm: CGFloat { adaptive(sm) }
        static var adaptiveMd: CGFloat { adaptive(md) }
        static var adaptiveLg: CGFloat { adaptive(lg) }
        static var adaptiveXl: CGFloat { adaptive(xl) }
    }

    // MARK: - Radius

    enum Radius {
        static let none: CGFloat = 0
        static let xs: CGFloat = 4
        static let sm: CGFloat = 6
        static let md: CGFloat = 8
        static let lg: CGFloat = 10
        static let xl: CGFloat = 12
        static let xxl: CGFloat = 16
        static let full: CGFloat = 9999

        // MARK: Adaptive Radius for Liquid Glass (macOS 26+)

        static func adaptive(_ base: CGFloat) -> CGFloat {
            if isLiquidGlassAvailable {
                return base * 1.25
            }
            return base
        }

        static var adaptiveMd: CGFloat { adaptive(md) }
        static var adaptiveLg: CGFloat { adaptive(lg) }
        static var adaptiveXl: CGFloat { adaptive(xl) }
    }

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

        static var xl: (color: Color, radius: CGFloat, x: CGFloat, y: CGFloat) {
            if isLiquidGlassAvailable {
                return (color: Color.black.opacity(0.1), radius: 12, x: 0, y: 4)
            }
            return (color: Color.black.opacity(0.3), radius: 30, x: 0, y: 10)
        }

        /// Glow effect for selected/focused items
        static var glow: (color: Color, radius: CGFloat, x: CGFloat, y: CGFloat) {
            if isLiquidGlassAvailable {
                return (color: Colors.Blue.accent500.opacity(0.15), radius: 8, x: 0, y: 0)
            }
            return (color: Colors.Blue.accent500.opacity(0.3), radius: 12, x: 0, y: 0)
        }
    }

    // MARK: - Icon Sizes

    enum IconSize {
        static let xs: CGFloat = 12
        static let sm: CGFloat = 14
        static let md: CGFloat = 16
        static let lg: CGFloat = 20
        static let xl: CGFloat = 24
        static let xxl: CGFloat = 32
    }

    // MARK: - Layout

    enum Layout {
        static let maxContentWidth: CGFloat = 1200
        static let contentWidthNarrow: CGFloat = 640
        static let contentWidthMedium: CGFloat = 800
        static let contentWidthWide: CGFloat = 1000

        static var edgeInsetTight: EdgeInsets {
            let spacing = isLiquidGlassAvailable ? Spacing.md : Spacing.sm
            return EdgeInsets(top: spacing, leading: spacing, bottom: spacing, trailing: spacing)
        }

        static var edgeInsetNormal: EdgeInsets {
            let spacing = isLiquidGlassAvailable ? Spacing.lg : Spacing.md
            return EdgeInsets(top: spacing, leading: spacing, bottom: spacing, trailing: spacing)
        }

        static var edgeInsetComfortable: EdgeInsets {
            let spacing = isLiquidGlassAvailable ? Spacing.xl : Spacing.lg
            return EdgeInsets(top: spacing, leading: spacing, bottom: spacing, trailing: spacing)
        }
    }

    // MARK: - Animation

    enum Animation {
        /// Fast transitions (hover states, micro-interactions) - ~150ms
        static let fast: SwiftUI.Animation = .easeInOut(duration: 0.15)

        /// Normal transitions (standard UI changes) - ~200ms
        static let normal: SwiftUI.Animation = .easeInOut(duration: 0.2)

        /// Slow transitions (major UI changes) - ~300ms
        static let slow: SwiftUI.Animation = .easeInOut(duration: 0.3)

        /// Smooth spring (subtle, not bouncy)
        static let spring: SwiftUI.Animation = .spring(response: 0.3, dampingFraction: 0.8)

        /// Bouncy spring for selections
        static let bouncy: SwiftUI.Animation = .spring(response: 0.35, dampingFraction: 0.7)

        /// Glass-optimized spring for macOS 26+ interactions
        static var glassSpring: SwiftUI.Animation {
            isLiquidGlassAvailable
                ? .spring(response: 0.4, dampingFraction: 0.75)
                : spring
        }
    }

    // MARK: - Border Width

    enum BorderWidth {
        static var `default`: CGFloat {
            isLiquidGlassAvailable ? 0.5 : 1.0
        }

        static var selected: CGFloat {
            isLiquidGlassAvailable ? 1.0 : 1.5
        }

        static var subtle: CGFloat {
            isLiquidGlassAvailable ? 0.0 : 0.5
        }
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
    /// Note: Uses the standard SwiftUI-to-AppKit bridge
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
            self.background(DesignTokens.Colors.backgroundElevated)
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

// MARK: - Promptist Card Background

struct PrompistCardBackground<Content: View>: View {
    let content: Content
    let padding: EdgeInsets
    let cornerRadius: CGFloat
    let showBorder: Bool
    let isSelected: Bool

    init(
        padding: EdgeInsets = DesignTokens.Layout.edgeInsetNormal,
        cornerRadius: CGFloat = DesignTokens.Radius.lg,
        showBorder: Bool = true,
        isSelected: Bool = false,
        @ViewBuilder content: () -> Content
    ) {
        self.content = content()
        self.padding = padding
        self.cornerRadius = cornerRadius
        self.showBorder = showBorder
        self.isSelected = isSelected
    }

    var body: some View {
        content
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(isSelected ? DesignTokens.Colors.selectedBackground : DesignTokens.Colors.backgroundSecondary)
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(
                        isSelected ? DesignTokens.Colors.selectedBorder : (showBorder ? DesignTokens.Colors.borderSubtle : .clear),
                        lineWidth: isSelected ? DesignTokens.BorderWidth.selected : DesignTokens.BorderWidth.default
                    )
            )
            .shadow(
                color: isSelected ? DesignTokens.Shadow.glow.color : .clear,
                radius: DesignTokens.Shadow.glow.radius,
                x: 0,
                y: 0
            )
    }
}
