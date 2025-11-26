import SwiftUI

// MARK: - Empty State View

struct EmptyStateView: View {
    let icon: String
    let title: String
    let description: String
    let action: (() -> Void)?
    let actionLabel: String?

    init(
        icon: String,
        title: String,
        description: String,
        actionLabel: String? = nil,
        action: (() -> Void)? = nil
    ) {
        self.icon = icon
        self.title = title
        self.description = description
        self.actionLabel = actionLabel
        self.action = action
    }

    var body: some View {
        VStack(spacing: DesignTokens.Spacing.lg) {
            Image(systemName: icon)
                .font(.system(size: DesignTokens.IconSize.xxl, weight: .light))
                .foregroundColor(DesignTokens.Colors.foregroundTertiary)

            VStack(spacing: DesignTokens.Spacing.xs) {
                Text(title)
                    .font(DesignTokens.Typography.headline(DesignTokens.Typography.headlineMedium))
                    .foregroundColor(DesignTokens.Colors.foregroundPrimary)

                Text(description)
                    .font(DesignTokens.Typography.body())
                    .foregroundColor(DesignTokens.Colors.foregroundSecondary)
                    .multilineTextAlignment(.center)
            }

            if let action, let actionLabel {
                ActionButton(actionLabel, icon: "plus", variant: .primary, action: action)
            }
        }
        .padding(DesignTokens.Spacing.xxxl)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
