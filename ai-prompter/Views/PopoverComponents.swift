import SwiftUI

/// Search bar with a lightweight container to visually group controls at the top of the popover.
struct SearchBarView: View {
    @Binding var text: String
    var placeholder: String = "Search prompts…"
    var onSubmit: () -> Void
    var manageAction: (() -> Void)?
    var manageLabel: String = "Manage"

    var body: some View {
        VStack(spacing: DesignTokens.Spacing.sm) {
            HStack(spacing: DesignTokens.Spacing.md) {
                HStack(spacing: DesignTokens.Spacing.xs) {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(DesignTokens.Colors.foregroundSecondary)

                    TextField(placeholder, text: $text)
                        .textFieldStyle(.plain)
                        .font(DesignTokens.Typography.body())
                        .onSubmit(onSubmit)
                        .disableAutocorrection(true)
                }
                .padding(.horizontal, DesignTokens.Spacing.md)
                .padding(.vertical, DesignTokens.Spacing.xs)
                .background(
                    RoundedRectangle(cornerRadius: DesignTokens.Radius.lg, style: .continuous)
                        .fill(DesignTokens.Colors.backgroundElevated)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: DesignTokens.Radius.lg, style: .continuous)
                        .stroke(DesignTokens.Colors.borderSubtle, lineWidth: 0.8)
                )

                if let manageAction {
                    Button(action: manageAction) {
                        Label(manageLabel, systemImage: "slider.horizontal.3")
                            .labelStyle(.titleAndIcon)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                    .tint(DesignTokens.Colors.accentPrimary.opacity(0.9))
                }
            }
        }
        .padding(.horizontal, DesignTokens.Spacing.md)
        .padding(.vertical, DesignTokens.Spacing.xs)
        .background(
            RoundedRectangle(cornerRadius: DesignTokens.Radius.xl, style: .continuous)
                .fill(DesignTokens.Colors.backgroundSecondary)
                .shadow(color: DesignTokens.Shadow.sm.color, radius: DesignTokens.Shadow.sm.radius, y: DesignTokens.Shadow.sm.y)
        )
    }
}

/// Segmented control for filtering templates by their source app.
struct AppFilterSegmentView: View {
    enum Segment: Hashable {
        case chatGPT
        case warp
        case cursor
        case all
    }

    var selection: PromptQuickFilter
    var currentTrackedApp: TrackedApp?
    var onSelect: (PromptQuickFilter) -> Void
    @State private var hoveredSegment: Segment?

    var body: some View {
        HStack(spacing: DesignTokens.Spacing.xs) {
            ForEach([Segment.chatGPT, .warp, .cursor, .all], id: \.self) { segment in
                segmentButton(for: segment)
            }
        }
        .padding(DesignTokens.Spacing.sm)
        .background(
            RoundedRectangle(cornerRadius: DesignTokens.Radius.xl, style: .continuous)
                .fill(DesignTokens.Colors.backgroundSecondary)
        )
        .overlay(
            RoundedRectangle(cornerRadius: DesignTokens.Radius.xl, style: .continuous)
                .stroke(DesignTokens.Colors.borderSubtle, lineWidth: 0.8)
        )
    }

    private func segmentButton(for segment: Segment) -> some View {
        let active = isSelected(segment)
        let hovering = hoveredSegment == segment

        return Button {
            onSelect(filter(for: segment))
        } label: {
            Text(label(for: segment))
                .font(DesignTokens.Typography.label(DesignTokens.Typography.labelMedium, weight: .semibold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, DesignTokens.Spacing.xs)
                .padding(.horizontal, DesignTokens.Spacing.sm)
                .foregroundColor(active ? DesignTokens.Colors.foregroundPrimary : DesignTokens.Colors.foregroundSecondary)
                .background(
                    Capsule()
                        .fill(
                            active
                            ? DesignTokens.Colors.selectedBackground
                            : (hovering ? DesignTokens.Colors.hoverBackground : Color.clear)
                        )
                )
                .overlay(
                    Capsule()
                        .stroke(
                            active ? DesignTokens.Colors.accentPrimary.opacity(0.3) : DesignTokens.Colors.borderSubtle.opacity(0.5),
                            lineWidth: active ? 1 : 0.5
                        )
                )
        }
        .buttonStyle(.plain)
        .controlSize(.small)
        .onHover { isHovering in
            hoveredSegment = isHovering ? segment : nil
        }
        .animation(DesignTokens.Animation.normal, value: hovering)
    }

    private func isSelected(_ segment: Segment) -> Bool {
        switch selection {
        case .all:
            return segment == .all
        case .app(let app):
            guard let mapped = mappedSegment(for: app) else { return segment == .all }
            return segment == mapped
        case .currentApp:
            guard
                let app = currentTrackedApp,
                let mapped = mappedSegment(for: app)
            else { return segment == .all }
            return segment == mapped
        }
    }

    private func mappedSegment(for app: TrackedApp) -> Segment? {
        switch app {
        case .chatGPT:
            return .chatGPT
        case .warp:
            return .warp
        case .cursor:
            return .cursor
        default:
            return nil
        }
    }

    private func filter(for segment: Segment) -> PromptQuickFilter {
        switch segment {
        case .chatGPT:
            return .app(.chatGPT)
        case .warp:
            return .app(.warp)
        case .cursor:
            return .app(.cursor)
        case .all:
            return .all
        }
    }

    private func label(for segment: Segment) -> String {
        switch segment {
        case .chatGPT: return "ChatGPT"
        case .warp: return "Warp"
        case .cursor: return "Cursor"
        case .all: return "All"
        }
    }
}

/// Compact macOS-friendly section header.
struct SectionHeaderView: View {
    var title: String

    var body: some View {
        Text(title.uppercased())
            .font(DesignTokens.Typography.caption(DesignTokens.Typography.captionSmall, weight: .medium))
            .foregroundColor(DesignTokens.Colors.foregroundTertiary)
            .tracking(0.5)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, DesignTokens.Spacing.xxs)
            .padding(.bottom, DesignTokens.Spacing.micro)
    }
}

/// Individual template row tuned for popover density and scan-ability.
struct TemplateRowView: View {
    let template: PromptTemplate
    let linkedAppsText: String?
    let isCompact: Bool
    let onTap: () -> Void

    @State private var isHovering = false
    @State private var showHoverPopover = false
    @State private var hoverPreviewWorkItem: DispatchWorkItem?

    private var titleFont: Font { DesignTokens.Typography.headline(isCompact ? 15 : 16) }
    private var descriptionFont: Font { DesignTokens.Typography.body(isCompact ? 12 : 13) }
    private var verticalSpacing: CGFloat { isCompact ? DesignTokens.Spacing.xxs : DesignTokens.Spacing.xs }
    private var rowPadding: CGFloat { isCompact ? DesignTokens.Spacing.xs : DesignTokens.Spacing.sm }

    var body: some View {
        Button {
            cancelHoverPreview()
            showHoverPopover = false
            onTap()
        } label: {
            VStack(alignment: .leading, spacing: verticalSpacing) {
                HStack(alignment: .firstTextBaseline, spacing: DesignTokens.Spacing.sm) {
                    Text(template.title)
                        .font(titleFont)
                        .foregroundColor(DesignTokens.Colors.foregroundPrimary)
                        .lineLimit(1)

                    Spacer()

                    if let linkedAppsText {
                        Text(linkedAppsText)
                            .font(DesignTokens.Typography.caption(DesignTokens.Typography.captionSmall))
                            .foregroundColor(DesignTokens.Colors.foregroundTertiary)
                            .multilineTextAlignment(.trailing)
                            .lineLimit(1)
                    }
                }

                Text(template.content)
                    .font(descriptionFont)
                    .foregroundColor(DesignTokens.Colors.foregroundSecondary)
                    .lineLimit(2)
                    .lineSpacing(isCompact ? 1 : 2)

                if !template.tags.isEmpty {
                    TemplateTagsView(tags: template.tags, scale: isCompact ? 0.85 : 1.0)
                }
            }
            .padding(.vertical, rowPadding)
            .padding(.horizontal, DesignTokens.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: DesignTokens.Radius.lg, style: .continuous)
                    .fill(isHovering ? DesignTokens.Colors.hoverBackground : DesignTokens.Colors.backgroundSecondary.opacity(0.5))
            )
            .overlay(
                RoundedRectangle(cornerRadius: DesignTokens.Radius.lg, style: .continuous)
                    .stroke(isHovering ? DesignTokens.Colors.borderDefault : DesignTokens.Colors.borderSubtle, lineWidth: 0.5)
            )
            .animation(DesignTokens.Animation.normal, value: isHovering)
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            isHovering = hovering
            if hovering {
                scheduleHoverPreview()
            } else {
                cancelHoverPreview()
                showHoverPopover = false
            }
        }
        .popover(
            isPresented: $showHoverPopover,
            attachmentAnchor: .rect(.bounds),
            arrowEdge: .trailing
        ) {
            HoverPreview(text: template.content)
        }
        .onDisappear {
            cancelHoverPreview()
            showHoverPopover = false
        }
    }

    private func scheduleHoverPreview() {
        cancelHoverPreview()

        var workItem: DispatchWorkItem?
        workItem = DispatchWorkItem {
            guard workItem?.isCancelled == false else { return }
            if isHovering {
                showHoverPopover = true
            }
        }

        hoverPreviewWorkItem = workItem
        if let workItem {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0, execute: workItem)
        }
    }

    private func cancelHoverPreview() {
        hoverPreviewWorkItem?.cancel()
        hoverPreviewWorkItem = nil
    }
}

private struct HoverPreview: View {
    let text: String

    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
            Text(text)
                .font(DesignTokens.Typography.body())
                .foregroundColor(DesignTokens.Colors.foregroundPrimary)
                .multilineTextAlignment(.leading)
        }
        .padding(DesignTokens.Spacing.md)
        .frame(maxWidth: 260, alignment: .leading)
    }
}

/// Tag pills tuned for macOS small chip sizing.
private struct TemplateTagsView: View {
    let tags: [String]
    let scale: CGFloat

    var body: some View {
        let pillFont: Font = DesignTokens.Typography.caption(11, weight: .medium)

        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: DesignTokens.Spacing.xs * scale) {
                ForEach(tags, id: \.self) { tag in
                    Text(tag)
                        .font(pillFont)
                        .padding(.vertical, DesignTokens.Spacing.xxs * scale)
                        .padding(.horizontal, DesignTokens.Spacing.sm * scale)
                        .background(
                            Capsule()
                                .fill(DesignTokens.Colors.accentPrimary.opacity(0.1))
                        )
                        .overlay(
                            Capsule()
                                .stroke(DesignTokens.Colors.accentPrimary.opacity(0.2), lineWidth: 0.5)
                        )
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .allowsHitTesting(false)
    }
}
