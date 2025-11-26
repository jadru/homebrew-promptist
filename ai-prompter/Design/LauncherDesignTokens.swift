//
//  LauncherDesignTokens.swift
//  ai-prompter
//
//  Minimal design tokens for the prompt launcher UI
//

import SwiftUI

struct LauncherDesignTokens {
    // MARK: - Layout
    struct Layout {
        static let popoverWidth: CGFloat = 540
        static let popoverMinHeight: CGFloat = 200
        static let popoverMaxHeight: CGFloat = 600
        static let popoverCornerRadius: CGFloat = 12

        static let searchBarHeight: CGFloat = 44
        static let rowHeight: CGFloat = 48
        static let rowCompactHeight: CGFloat = 44

        static let horizontalPadding: CGFloat = 12
        static let verticalPadding: CGFloat = 8
        static let searchPadding: CGFloat = 16

        static let rowSpacing: CGFloat = 2
        static let tagSpacing: CGFloat = 6
    }

    // MARK: - Colors
    struct Colors {
        // Background
        static let popoverBackground = Color(nsColor: .windowBackgroundColor)
        static let searchBackground = Color(nsColor: .controlBackgroundColor)

        // Row states
        static let rowHover = Color.primary.opacity(0.05)
        static let rowSelected = Color.accentColor.opacity(0.12)
        static let rowPressed = Color.accentColor.opacity(0.18)

        // Text
        static let primaryText = Color.primary
        static let secondaryText = Color.secondary
        static let tertiaryText = Color.primary.opacity(0.5)

        // Accent
        static let accent = Color.accentColor

        // Tag
        static let tagBackground = Color.accentColor.opacity(0.1)
        static let tagText = Color.accentColor

        // Separator
        static let separator = Color.primary.opacity(0.08)
    }

    // MARK: - Typography
    struct Typography {
        // Search
        static let searchFont = Font.system(size: 15, weight: .regular)
        static let searchPlaceholderColor = Color.secondary

        // Prompt row
        static let rowTitleFont = Font.system(size: 14, weight: .semibold)
        static let rowSubtitleFont = Font.system(size: 12, weight: .regular)

        // Tag
        static let tagFont = Font.system(size: 10, weight: .medium)

        // Empty state
        static let emptyStateFont = Font.system(size: 13, weight: .regular)
    }

    // MARK: - Shadows
    struct Shadows {
        static let popoverShadow: (color: Color, radius: CGFloat, x: CGFloat, y: CGFloat) = (
            color: Color.black.opacity(0.15),
            radius: 20,
            x: 0,
            y: 8
        )
    }

    // MARK: - Animation
    struct Animation {
        static let hoverDuration: Double = 0.15
        static let selectionDuration: Double = 0.12
        static let searchFilterDuration: Double = 0.2

        static let hoverAnimation = SwiftUI.Animation.easeOut(duration: hoverDuration)
        static let selectionAnimation = SwiftUI.Animation.easeInOut(duration: selectionDuration)
    }

    // MARK: - Interaction
    struct Interaction {
        static let rowHoverScale: CGFloat = 1.0 // Keep at 1.0 for minimal movement
        static let rowPressedScale: CGFloat = 0.995
    }
}
