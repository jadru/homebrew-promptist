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

    @State private var isHovering = false

    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
            // Title row with app badges
            HStack(alignment: .top) {
                Text(template.title.isEmpty ? "Untitled" : template.title)
                    .font(DesignTokens.Typography.headline(14))
                    .foregroundColor(DesignTokens.Colors.foregroundPrimary)
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
                                .font(DesignTokens.Typography.caption(9))
                                .foregroundColor(DesignTokens.Colors.foregroundTertiary)
                        }
                    }
                }
            }

            // Content preview
            Text(template.content)
                .font(DesignTokens.Typography.body(12))
                .foregroundColor(DesignTokens.Colors.foregroundSecondary)
                .lineLimit(2)
                .multilineTextAlignment(.leading)

            // Category badge (if available)
            if let categoryName = categoryName {
                HStack(spacing: 4) {
                    Image(systemName: "folder")
                        .font(.system(size: 9))
                    Text(categoryName)
                        .font(DesignTokens.Typography.caption(10))
                }
                .foregroundColor(DesignTokens.Colors.foregroundTertiary)
                .padding(.top, 2)
            }

            // Actions (visible on hover)
            if isHovering {
                HStack {
                    Spacer()

                    Button(action: onEdit) {
                        Image(systemName: "square.and.pencil")
                            .font(.system(size: 12))
                            .foregroundColor(DesignTokens.Colors.foregroundSecondary)
                    }
                    .buttonStyle(.plain)
                    .help("Edit")

                    Button(action: onDelete) {
                        Image(systemName: "trash")
                            .font(.system(size: 12))
                            .foregroundColor(DesignTokens.Colors.error.opacity(0.8))
                    }
                    .buttonStyle(.plain)
                    .help("Delete")
                }
                .padding(.top, DesignTokens.Spacing.xs)
            }
        }
        .padding(DesignTokens.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: DesignTokens.Radius.lg)
                .fill(isHovering ? DesignTokens.Colors.backgroundSecondary : DesignTokens.Colors.backgroundElevated)
        )
        .overlay(
            RoundedRectangle(cornerRadius: DesignTokens.Radius.lg)
                .stroke(DesignTokens.Colors.borderSubtle, lineWidth: 1)
        )
        .contentShape(Rectangle())
        .onHover { hovering in
            withAnimation(DesignTokens.Animation.fast) {
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
            .foregroundColor(.white)
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
                LazyVStack(spacing: DesignTokens.Spacing.sm) {
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
                .padding(DesignTokens.Spacing.md)
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

    var body: some View {
        VStack(spacing: DesignTokens.Spacing.lg) {
            Image(systemName: hasFilters ? "magnifyingglass" : "doc.text")
                .font(.system(size: 40))
                .foregroundColor(DesignTokens.Colors.foregroundTertiary)

            Text(hasFilters ? "No matching templates" : "No templates yet")
                .font(DesignTokens.Typography.headline(16))
                .foregroundColor(DesignTokens.Colors.foregroundSecondary)

            Text(hasFilters ? "Try adjusting your filters" : "Create your first prompt template")
                .font(DesignTokens.Typography.body(13))
                .foregroundColor(DesignTokens.Colors.foregroundTertiary)

            if hasFilters {
                Button(action: onClearFilters) {
                    Text("Clear Filters")
                        .font(DesignTokens.Typography.label())
                        .foregroundColor(DesignTokens.Colors.accentPrimary)
                }
                .buttonStyle(.plain)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(DesignTokens.Spacing.xxxl)
    }
}
