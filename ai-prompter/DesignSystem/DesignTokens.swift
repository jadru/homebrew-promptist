import SwiftUI
import AppKit

// MARK: - Design Tokens

/// Complete design token system for AI Prompter
/// Inspired by Cursor, Linear, and GitHub Desktop's minimalist aesthetics
/// Priority: Blend naturally with macOS environment
enum DesignTokens {

    // MARK: - Colors

    enum Colors {

        // MARK: Background Layers

        /// Main window background (lightest surface)
        static let backgroundPrimary = Color(nsColor: .windowBackgroundColor)

        /// Secondary surface (cards, panels)
        static let backgroundSecondary = Color(nsColor: .controlBackgroundColor)

        /// Tertiary surface (nested cards, hover states)
        static let backgroundTertiary: Color = {
            #if os(macOS)
            return Color(nsColor: NSColor.controlBackgroundColor.blended(
                withFraction: 0.5,
                of: NSColor.windowBackgroundColor
            ) ?? .controlBackgroundColor)
            #else
            return Color(.systemGray6)
            #endif
        }()

        /// Elevated surface (modals, popovers)
        static let backgroundElevated = Color(nsColor: .textBackgroundColor)

        // MARK: Foreground Colors

        /// Primary text color
        static let foregroundPrimary = Color(nsColor: .labelColor)

        /// Secondary text color (less emphasis)
        static let foregroundSecondary = Color(nsColor: .secondaryLabelColor)

        /// Tertiary text color (least emphasis)
        static let foregroundTertiary = Color(nsColor: .tertiaryLabelColor)

        /// Disabled text
        static let foregroundDisabled = Color(nsColor: .quaternaryLabelColor)

        // MARK: Borders

        /// Subtle border (cards, inputs)
        static let borderSubtle = Color(nsColor: .separatorColor).opacity(0.5)

        /// Default border
        static let borderDefault = Color(nsColor: .separatorColor)

        /// Strong border (focus, emphasis)
        static let borderStrong = Color(nsColor: .separatorColor).opacity(1.5)

        // MARK: Interactive States

        /// Hover state background
        static let hoverBackground: Color = {
            #if os(macOS)
            return Color(nsColor: NSColor.controlBackgroundColor.blended(
                withFraction: 0.3,
                of: NSColor.systemGray
            ) ?? .controlBackgroundColor)
            #else
            return Color(.systemGray5)
            #endif
        }()

        /// Pressed state background
        static let pressedBackground: Color = {
            #if os(macOS)
            return Color(nsColor: NSColor.controlBackgroundColor.blended(
                withFraction: 0.5,
                of: NSColor.systemGray
            ) ?? .controlBackgroundColor)
            #else
            return Color(.systemGray4)
            #endif
        }()

        /// Selected state background
        static let selectedBackground = Color.accentColor.opacity(0.12)

        // MARK: Accent Colors

        /// Primary accent (brand color, CTAs)
        static let accentPrimary = Color.accentColor

        /// Accent hover state
        static let accentHover: Color = {
            #if os(macOS)
            return Color(nsColor: NSColor(Color.accentColor).blended(
                withFraction: 0.15,
                of: .black
            ) ?? NSColor(Color.accentColor))
            #else
            return Color.accentColor.opacity(0.85)
            #endif
        }()

        /// Accent pressed state
        static let accentPressed: Color = {
            #if os(macOS)
            return Color(nsColor: NSColor(Color.accentColor).blended(
                withFraction: 0.25,
                of: .black
            ) ?? NSColor(Color.accentColor))
            #else
            return Color.accentColor.opacity(0.75)
            #endif
        }()

        // MARK: Semantic Colors

        static let success = Color.green
        static let warning = Color.orange
        static let error = Color.red
        static let info = Color.blue

        // MARK: Static Grey Palette (App-specific consistency)

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
    }

    // MARK: - Shadows

    enum Shadow {
        static let none: (color: Color, radius: CGFloat, x: CGFloat, y: CGFloat) = (
            color: .clear, radius: 0, x: 0, y: 0
        )

        static let sm: (color: Color, radius: CGFloat, x: CGFloat, y: CGFloat) = (
            color: Color.black.opacity(0.04), radius: 2, x: 0, y: 1
        )

        static let md: (color: Color, radius: CGFloat, x: CGFloat, y: CGFloat) = (
            color: Color.black.opacity(0.06), radius: 8, x: 0, y: 2
        )

        static let lg: (color: Color, radius: CGFloat, x: CGFloat, y: CGFloat) = (
            color: Color.black.opacity(0.08), radius: 16, x: 0, y: 4
        )

        static let xl: (color: Color, radius: CGFloat, x: CGFloat, y: CGFloat) = (
            color: Color.black.opacity(0.1), radius: 24, x: 0, y: 8
        )
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

        static let edgeInsetTight: EdgeInsets = EdgeInsets(
            top: Spacing.sm, leading: Spacing.sm, bottom: Spacing.sm, trailing: Spacing.sm
        )

        static let edgeInsetNormal: EdgeInsets = EdgeInsets(
            top: Spacing.md, leading: Spacing.md, bottom: Spacing.md, trailing: Spacing.md
        )

        static let edgeInsetComfortable: EdgeInsets = EdgeInsets(
            top: Spacing.lg, leading: Spacing.lg, bottom: Spacing.lg, trailing: Spacing.lg
        )
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
