//
//  TemplateCard.swift
//  Promptist
//
//  Template card component for the Manager view.
//  Shows title, content preview, and app compatibility badges.
//  Does NOT show tags/keywords (per design spec).
//

import SwiftUI

struct TemplateCard: View {
    let template: PromptTemplate
    let categoryName: String?
    let onEdit: () -> Void
    let onDelete: () -> Void
    var onDrag: (() -> NSItemProvider)?

    @EnvironmentObject private var languageSettings: LanguageSettings
    @State private var isHovering = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Title row with app badges
            HStack(alignment: .top) {
                Text(template.title.isEmpty ? languageSettings.localized("template.untitled") : template.title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)

                Spacer()

                // App compatibility badges
                if !template.linkedApps.isEmpty {
                    HStack(spacing: 4) {
                        ForEach(template.linkedApps.prefix(3), id: \.id) { app in
                            AppBadge(app: app)
                        }
                        if template.linkedApps.count > 3 {
                            Text("+\(template.linkedApps.count - 3)")
                                .font(.system(size: 9))
                                .foregroundStyle(.tertiary)
                        }
                    }
                }
            }

            // Content preview
            Text(template.content)
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
                .lineLimit(2)
                .multilineTextAlignment(.leading)

            // Category badge (if available)
            if let categoryName = categoryName {
                HStack(spacing: 4) {
                    Image(systemName: "folder")
                        .font(.system(size: 9))
                    Text(categoryName)
                        .font(.system(size: 10))
                }
                .foregroundStyle(.tertiary)
                .padding(.top, 2)
            }

            // Actions (visible on hover)
            if isHovering {
                HStack {
                    Spacer()

                    Button(action: onEdit) {
                        Image(systemName: "square.and.pencil")
                            .font(.system(size: 12))
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                    .help(languageSettings.localized("template.action.edit"))

                    Button(action: onDelete) {
                        Image(systemName: "trash")
                            .font(.system(size: 12))
                            .foregroundStyle(.red.opacity(0.8))
                    }
                    .buttonStyle(.plain)
                    .help(languageSettings.localized("template.action.delete"))
                }
                .padding(.top, 6)
            }
        }
        .padding(12)
        .frame(minHeight: 60)
        .background {
            if #available(macOS 26.0, *) {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(.clear)
                    .glassEffect(
                        isHovering ? .clear : .regular,
                        in: RoundedRectangle(cornerRadius: 10, style: .continuous)
                    )
            } else {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(isHovering ? AnyShapeStyle(Color.primary.opacity(0.06)) : AnyShapeStyle(.regularMaterial))
            }
        }
        .contentShape(Rectangle())
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovering = hovering
            }
        }
        .onDrag {
            onDrag?() ?? NSItemProvider()
        }
    }
}

// MARK: - App Badge

struct AppBadge: View {
    let app: PromptAppTarget

    var body: some View {
        Text(initial)
            .font(.system(size: 9, weight: .bold))
            .foregroundStyle(.white)
            .frame(width: 18, height: 18)
            .background(
                Circle()
                    .fill(badgeColor)
            )
            .help(app.displayName)
    }

    private var initial: String {
        String(app.displayName.prefix(1)).uppercased()
    }

    private var badgeColor: Color {
        // Generate a consistent color based on the app name
        let hash = app.displayName.hashValue
        let hue = Double(abs(hash) % 360) / 360.0
        return Color(hue: hue, saturation: 0.6, brightness: 0.7)
    }
}

// MARK: - Template List View

struct TemplateListView: View {
    let templates: [PromptTemplate]
    @ObservedObject var viewModel: PromptListViewModel
    let onEdit: (PromptTemplate) -> Void
    let onDelete: (PromptTemplate) -> Void

    var body: some View {
        if templates.isEmpty {
            EmptyTemplateState(
                hasFilters: viewModel.filterState.hasActiveFilters,
                onClearFilters: { viewModel.resetFilters() }
            )
        } else {
            ScrollView {
                LazyVStack(spacing: 8) {
                    ForEach(templates) { template in
                        TemplateCard(
                            template: template,
                            categoryName: categoryName(for: template),
                            onEdit: { onEdit(template) },
                            onDelete: { onDelete(template) },
                            onDrag: {
                                NSItemProvider(object: template.id.uuidString as NSString)
                            }
                        )
                    }
                }
                .padding(12)
            }
        }
    }

    private func categoryName(for template: PromptTemplate) -> String? {
        guard let categoryId = template.categoryId else { return nil }
        return viewModel.categoryPath(for: categoryId)
    }
}

// MARK: - Empty State

struct EmptyTemplateState: View {
    let hasFilters: Bool
    let onClearFilters: () -> Void
    @EnvironmentObject private var languageSettings: LanguageSettings

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: hasFilters ? "magnifyingglass" : "doc.text")
                .font(.system(size: 40))
                .foregroundStyle(.tertiary)
                .glassCircleBackground(size: 72)

            Text(hasFilters ? languageSettings.localized("manager.empty.no_matches") : languageSettings.localized("manager.empty.no_templates"))
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(.secondary)

            Text(hasFilters ? languageSettings.localized("manager.empty.no_matches_hint") : languageSettings.localized("manager.empty.no_templates_hint"))
                .font(.system(size: 13))
                .foregroundStyle(.tertiary)

            if hasFilters {
                Button(action: onClearFilters) {
                    Text(languageSettings.localized("manager.empty.clear_filters"))
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.accent)
                }
                .buttonStyle(.plain)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(40)
    }
}
