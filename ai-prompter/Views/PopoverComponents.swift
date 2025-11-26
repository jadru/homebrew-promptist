import SwiftUI

/// Search bar with a lightweight container to visually group controls at the top of the popover.
struct SearchBarView: View {
    @Binding var text: String
    var placeholder: String = "Search prompts…"
    var onSubmit: () -> Void
    var manageAction: (() -> Void)?
    var manageLabel: String = "Manage"

    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 10) {
                HStack(spacing: 6) {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(.secondary)

                    TextField(placeholder, text: $text)
                        .textFieldStyle(.plain)
                        .font(.system(size: 14))
                        .onSubmit(onSubmit)
                        .disableAutocorrection(true)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(Color(nsColor: .textBackgroundColor))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(Color.primary.opacity(0.08), lineWidth: 0.8)
                )

                if let manageAction {
                    Button(action: manageAction) {
                        Label(manageLabel, systemImage: "slider.horizontal.3")
                            .labelStyle(.titleAndIcon)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                    .tint(.accentColor.opacity(0.9))
                }
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color(nsColor: .controlBackgroundColor))
                .shadow(color: Color.black.opacity(0.05), radius: 10, y: 2)
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
        HStack(spacing: 6) {
            ForEach([Segment.chatGPT, .warp, .cursor, .all], id: \.self) { segment in
                segmentButton(for: segment)
            }
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(nsColor: .controlBackgroundColor))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Color.primary.opacity(0.06), lineWidth: 0.8)
        )
    }

    private func segmentButton(for segment: Segment) -> some View {
        let active = isSelected(segment)
        let hovering = hoveredSegment == segment

        return Button {
            onSelect(filter(for: segment))
        } label: {
            Text(label(for: segment))
                .font(.system(size: 13, weight: .semibold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 6)
                .padding(.horizontal, 8)
                .foregroundStyle(active ? Color.primary : Color.primary.opacity(0.8))
                .background(
                    Capsule()
                        .fill(
                            active
                            ? Color.accentColor.opacity(0.18)
                            : (hovering ? Color.primary.opacity(0.06) : Color.primary.opacity(0.03))
                        )
                )
                .overlay(
                    Capsule()
                        .stroke(Color.primary.opacity(active ? 0.15 : 0.1), lineWidth: 0.8)
                )
        }
        .buttonStyle(.plain)
        .controlSize(.small)
        .onHover { isHovering in
            hoveredSegment = isHovering ? segment : nil
        }
        .animation(.easeInOut(duration: 0.12), value: hovering)
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
            .font(.caption2.smallCaps())
            .foregroundStyle(.secondary.opacity(0.8))
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, 4)
            .padding(.bottom, 2)
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

    private var titleFont: Font { .system(size: isCompact ? 15 : 16, weight: .semibold) }
    private var descriptionFont: Font { .system(size: isCompact ? 12 : 13) }
    private var verticalSpacing: CGFloat { isCompact ? 5 : 6 }
    private var rowPadding: CGFloat { isCompact ? 7 : 9 }

    var body: some View {
        Button {
            cancelHoverPreview()
            showHoverPopover = false
            onTap()
        } label: {
            VStack(alignment: .leading, spacing: verticalSpacing) {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text(template.title)
                        .font(titleFont)
                        .foregroundStyle(.primary)
                        .lineLimit(1)

                    Spacer()

                    if let linkedAppsText {
                        Text(linkedAppsText)
                            .font(.caption2)
                            .foregroundStyle(.secondary.opacity(0.6))
                            .multilineTextAlignment(.trailing)
                            .lineLimit(1)
                    }
                }

                Text(template.content)
                    .font(descriptionFont)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .lineSpacing(isCompact ? 1 : 2)

                if !template.tags.isEmpty {
                    TemplateTagsView(tags: template.tags, scale: isCompact ? 0.85 : 1.0)
                }
            }
            .padding(.vertical, rowPadding)
            .padding(.horizontal, 10)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(isHovering ? Color.primary.opacity(0.04) : Color.primary.opacity(0.02))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(Color.primary.opacity(isHovering ? 0.12 : 0.06), lineWidth: 0.9)
            )
            .animation(.easeInOut(duration: 0.15), value: isHovering)
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
        VStack(alignment: .leading, spacing: 8) {
            Text(text)
                .font(.subheadline)
                .foregroundColor(.primary)
                .multilineTextAlignment(.leading)
        }
        .padding(12)
        .frame(maxWidth: 260, alignment: .leading)
    }
}

/// Tag pills tuned for macOS small chip sizing.
private struct TemplateTagsView: View {
    let tags: [String]
    let scale: CGFloat

    var body: some View {
        let pillFont: Font = .system(size: 11, weight: .medium)

        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6 * scale) {
                ForEach(tags, id: \.self) { tag in
                    Text(tag)
                        .font(pillFont)
                        .padding(.vertical, 3 * scale)
                        .padding(.horizontal, 8 * scale)
                        .background(
                            Capsule()
                                .fill(Color.accentColor.opacity(0.12))
                        )
                        .overlay(
                            Capsule()
                                .stroke(Color.accentColor.opacity(0.3), lineWidth: 0.5)
                        )
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .allowsHitTesting(false)
    }
}
