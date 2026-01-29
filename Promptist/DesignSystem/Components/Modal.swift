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
                    .padding(16)
            }
        }
        .frame(minWidth: 480, minHeight: 560)
    }

    private var header: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.primary)

                if let subtitle {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            IconButton(icon: "xmark", action: onClose)
        }
        .padding(16)
    }
}
