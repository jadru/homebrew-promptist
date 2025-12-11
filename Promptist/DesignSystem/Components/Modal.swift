import SwiftUI

// MARK: - Modal Sheet Container

struct ModalSheetContainer<Content: View>: View {
    let title: String
    let subtitle: String?
    let onClose: () -> Void
    let content: Content

    init(
        title: String,
        subtitle: String? = nil,
        onClose: @escaping () -> Void,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.subtitle = subtitle
        self.onClose = onClose
        self.content = content()
    }

    var body: some View {
        VStack(spacing: 0) {
            header

            Separator()

            ScrollView {
                content
                    .padding(DesignTokens.Spacing.lg)
            }
        }
        .background(DesignTokens.Colors.backgroundElevated)
        .frame(minWidth: 480, minHeight: 560)
    }

    private var header: some View {
        HStack(spacing: DesignTokens.Spacing.md) {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.xxs) {
                Text(title)
                    .font(DesignTokens.Typography.headline(DesignTokens.Typography.headlineLarge))
                    .foregroundColor(DesignTokens.Colors.foregroundPrimary)

                if let subtitle {
                    Text(subtitle)
                        .font(DesignTokens.Typography.caption())
                        .foregroundColor(DesignTokens.Colors.foregroundSecondary)
                }
            }

            Spacer()

            IconButton(icon: "xmark", action: onClose)
        }
        .padding(DesignTokens.Spacing.lg)
    }
}
