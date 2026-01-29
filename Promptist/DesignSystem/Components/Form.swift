import SwiftUI

// MARK: - Search Bar

struct SearchBar: View {
    @Binding var text: String
    let placeholder: String
    let onSubmit: () -> Void

    @State private var isFocused = false

    init(
        text: Binding<String>,
        placeholder: String = "Search...",
        onSubmit: @escaping () -> Void = {}
    ) {
        self._text = text
        self.placeholder = placeholder
        self.onSubmit = onSubmit
    }

    var body: some View {
        HStack(spacing: DesignTokens.Spacing.xs) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: DesignTokens.IconSize.sm, weight: .medium))
                .foregroundColor(DesignTokens.Colors.foregroundSecondary)

            TextField(placeholder, text: $text)
                .textFieldStyle(.plain)
                .font(DesignTokens.Typography.body())
                .onSubmit(onSubmit)
                .disableAutocorrection(true)

            if !text.isEmpty {
                Button {
                    text = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: DesignTokens.IconSize.sm))
                        .foregroundColor(DesignTokens.Colors.foregroundTertiary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, DesignTokens.Spacing.md)
        .padding(.vertical, DesignTokens.Spacing.xs)
        .background(
            RoundedRectangle(cornerRadius: DesignTokens.Radius.md, style: .continuous)
                .fill(DesignTokens.Colors.backgroundSecondary)
        )
        .overlay(
            RoundedRectangle(cornerRadius: DesignTokens.Radius.md, style: .continuous)
                .stroke(
                    isFocused ? DesignTokens.Colors.accentPrimary : DesignTokens.Colors.borderSubtle,
                    lineWidth: isFocused ? DesignTokens.BorderWidth.selected : DesignTokens.BorderWidth.default
                )
        )
    }
}

// MARK: - Settings Toggle Row

struct SettingsToggleRow: View {
    let title: String
    let description: String?
    @Binding var isOn: Bool

    init(title: String, description: String? = nil, isOn: Binding<Bool>) {
        self.title = title
        self.description = description
        self._isOn = isOn
    }

    var body: some View {
        HStack(alignment: .top, spacing: DesignTokens.Spacing.md) {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.xxs) {
                Text(title)
                    .font(DesignTokens.Typography.body())
                    .foregroundColor(DesignTokens.Colors.foregroundPrimary)

                if let description {
                    Text(description)
                        .font(DesignTokens.Typography.caption())
                        .foregroundColor(DesignTokens.Colors.foregroundSecondary)
                }
            }

            Spacer()

            Toggle("", isOn: $isOn)
                .toggleStyle(.switch)
                .labelsHidden()
        }
        .padding(.horizontal, DesignTokens.Spacing.md)
        .padding(.vertical, DesignTokens.Spacing.sm)
    }
}

// MARK: - Filter Segmented Control

struct FilterSegmentedControl: View {
    let options: [String]
    @Binding var selectedIndex: Int

    @State private var hoveredIndex: Int?

    var body: some View {
        HStack(spacing: DesignTokens.Spacing.xxs) {
            ForEach(Array(options.enumerated()), id: \.offset) { index, option in
                segmentButton(option, index: index)
            }
        }
        .padding(DesignTokens.Spacing.xxs)
        .background(
            RoundedRectangle(cornerRadius: DesignTokens.Radius.md, style: .continuous)
                .fill(DesignTokens.Colors.backgroundSecondary)
        )
    }

    private func segmentButton(_ title: String, index: Int) -> some View {
        Button {
            withAnimation(DesignTokens.Animation.normal) {
                selectedIndex = index
            }
        } label: {
            Text(title)
                .font(DesignTokens.Typography.label(DesignTokens.Typography.labelMedium, weight: .medium))
                .foregroundColor(
                    selectedIndex == index
                        ? DesignTokens.Colors.foregroundPrimary
                        : DesignTokens.Colors.foregroundSecondary
                )
                .padding(.horizontal, DesignTokens.Spacing.md)
                .padding(.vertical, DesignTokens.Spacing.xs)
                .background(
                    RoundedRectangle(cornerRadius: DesignTokens.Radius.sm, style: .continuous)
                        .fill(
                            selectedIndex == index
                                ? DesignTokens.Colors.backgroundElevated
                                : (hoveredIndex == index ? DesignTokens.Colors.hoverBackground : Color.clear)
                        )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: DesignTokens.Radius.sm, style: .continuous)
                        .stroke(
                            selectedIndex == index ? DesignTokens.Colors.borderDefault : Color.clear,
                            lineWidth: DesignTokens.BorderWidth.subtle
                        )
                )
                .liquidGlass(enabled: selectedIndex == index)
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            hoveredIndex = hovering ? index : nil
        }
    }
}
