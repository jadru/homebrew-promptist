import SwiftUI

extension View {

    // MARK: - Card Style

    func cardStyle(
        padding: EdgeInsets = DesignTokens.Layout.edgeInsetNormal,
        elevation: CardBackground<AnyView>.ShadowElevation = .sm
    ) -> some View {
        self.modifier(CardStyleModifier(padding: padding, elevation: elevation))
    }

    // MARK: - Hover Effect

    func hoverEffect(
        scale: CGFloat = 1.0,
        opacity: Double = 1.0
    ) -> some View {
        self.modifier(HoverEffectModifier(scale: scale, opacity: opacity))
    }

    // MARK: - Button Variant

    func buttonVariant(_ variant: ActionButtonVariant) -> some View {
        self.modifier(ButtonVariantModifier(variant: variant))
    }
}

// MARK: - Card Style Modifier

private struct CardStyleModifier: ViewModifier {
    let padding: EdgeInsets
    let elevation: CardBackground<AnyView>.ShadowElevation

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: DesignTokens.Radius.lg, style: .continuous)
                    .fill(DesignTokens.Colors.backgroundElevated)
            )
            .overlay(
                RoundedRectangle(cornerRadius: DesignTokens.Radius.lg, style: .continuous)
                    .stroke(DesignTokens.Colors.borderSubtle, lineWidth: 1)
            )
            .shadow(
                color: elevation.shadow.color,
                radius: elevation.shadow.radius,
                x: elevation.shadow.x,
                y: elevation.shadow.y
            )
    }
}

// MARK: - Hover Effect Modifier

private struct HoverEffectModifier: ViewModifier {
    let scale: CGFloat
    let opacity: Double

    @State private var isHovering = false

    func body(content: Content) -> some View {
        content
            .scaleEffect(isHovering ? scale : 1.0)
            .opacity(isHovering ? opacity : 1.0)
            .onHover { hovering in
                withAnimation(DesignTokens.Animation.normal) {
                    isHovering = hovering
                }
            }
    }
}

// MARK: - Button Variant Modifier

private struct ButtonVariantModifier: ViewModifier {
    let variant: ActionButtonVariant

    func body(content: Content) -> some View {
        content
    }
}
