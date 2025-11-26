import SwiftUI

// MARK: - Reference Implementation for Redesigned Prompt Manager

/// This file serves as a reference implementation showing how to use the new design system.
/// Copy relevant parts into the actual PromptManagerView.swift

// MARK: - Prompt Manager Row (for Manager View)

struct PromptManagerRow: View {
    let template: PromptTemplate
    let onEdit: () -> Void
    let onDelete: () -> Void

    @State private var isHovering = false

    var body: some View {
        HStack(alignment: .top, spacing: DesignTokens.Spacing.md) {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                HStack {
                    Text(template.title)
                        .font(DesignTokens.Typography.headline())
                        .foregroundColor(DesignTokens.Colors.foregroundPrimary)

                    Spacer()

                    if !template.linkedApps.isEmpty {
                        AppPillRow(
                            apps: template.linkedApps.map { target in
                                AppInfo(name: target.displayName, bundleId: nil, isCustom: false)
                            }
                        )
                    }
                }

                if !template.tags.isEmpty {
                    Text(template.tags.joined(separator: ", "))
                        .font(DesignTokens.Typography.caption())
                        .foregroundColor(DesignTokens.Colors.foregroundSecondary)
                }

                Text(template.content)
                    .font(DesignTokens.Typography.body(DesignTokens.Typography.bodySmall))
                    .foregroundColor(DesignTokens.Colors.foregroundSecondary)
                    .lineLimit(3)
            }

            if isHovering {
                HStack(spacing: DesignTokens.Spacing.xs) {
                    IconButton(icon: "square.and.pencil", action: onEdit)
                    IconButton(icon: "trash", action: onDelete)
                }
                .transition(.opacity)
            }
        }
        .padding(DesignTokens.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: DesignTokens.Radius.lg, style: .continuous)
                .fill(isHovering ? DesignTokens.Colors.backgroundSecondary : DesignTokens.Colors.backgroundElevated)
        )
        .overlay(
            RoundedRectangle(cornerRadius: DesignTokens.Radius.lg, style: .continuous)
                .stroke(
                    isHovering ? DesignTokens.Colors.borderDefault : DesignTokens.Colors.borderSubtle,
                    lineWidth: 1
                )
        )
        .onHover { hovering in
            withAnimation(DesignTokens.Animation.normal) {
                isHovering = hovering
            }
        }
    }
}

// MARK: - Dynamic Filter Bar

struct DynamicFilterBar: View {
    let templates: [PromptTemplate]
    @Binding var selectedFilter: String?

    var appFilters: [(app: String, count: Int)] {
        var appCounts: [String: Int] = [:]

        for template in templates {
            for app in template.linkedApps {
                let name = app.displayName
                appCounts[name, default: 0] += 1
            }
        }

        return appCounts
            .sorted { $0.value > $1.value } // Sort by count (most used first)
            .map { (app: $0.key, count: $0.value) }
    }

    var body: some View {
        if !appFilters.isEmpty {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: DesignTokens.Spacing.xs) {
                    // All filter
                    FilterChip(
                        title: "All",
                        isSelected: selectedFilter == nil,
                        action: { selectedFilter = nil }
                    )

                    // Dynamic app filters
                    ForEach(appFilters, id: \.app) { filter in
                        FilterChip(
                            title: "\(filter.app) (\(filter.count))",
                            isSelected: selectedFilter == filter.app,
                            action: { selectedFilter = filter.app }
                        )
                    }
                }
                .padding(.horizontal, DesignTokens.Spacing.md)
            }
        }
    }
}

// MARK: - Filter Chip

private struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    @State private var isHovering = false

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(DesignTokens.Typography.label())
                .foregroundColor(
                    isSelected
                        ? DesignTokens.Colors.foregroundPrimary
                        : DesignTokens.Colors.foregroundSecondary
                )
                .padding(.horizontal, DesignTokens.Spacing.md)
                .padding(.vertical, DesignTokens.Spacing.xs)
                .background(
                    Capsule()
                        .fill(
                            isSelected
                                ? DesignTokens.Colors.selectedBackground
                                : (isHovering ? DesignTokens.Colors.hoverBackground : DesignTokens.Colors.backgroundSecondary)
                        )
                )
                .overlay(
                    Capsule()
                        .stroke(
                            isSelected ? DesignTokens.Colors.accentPrimary.opacity(0.3) : DesignTokens.Colors.borderSubtle,
                            lineWidth: isSelected ? 1 : 0.5
                        )
                )
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            withAnimation(DesignTokens.Animation.normal) {
                isHovering = hovering
            }
        }
    }
}

// MARK: - Example Layout Structure

/*
 Example of how to structure the redesigned PromptManagerView:

 VStack(spacing: 0) {
     // Toolbar with search, filters, density toggle, new button
     ManageToolbar(
         searchText: $searchText,
         isCompactMode: $isCompactMode,
         onNewPrompt: presentCreateEditor
     )

     Separator()

     // Dynamic filters
     DynamicFilterBar(
         templates: viewModel.allTemplates,
         selectedFilter: $selectedAppFilter
     )
     .padding(.vertical, DesignTokens.Spacing.sm)

     Separator()

     // Content area with custom ScrollView
     ScrollView {
         LazyVStack(spacing: DesignTokens.Spacing.md, pinnedViews: [.sectionHeaders]) {
             if !linkedTemplates.isEmpty {
                 Section {
                     templateList(linkedTemplates)
                 } header: {
                     PromptSectionHeader(title: "Current App")
                         .padding(.horizontal, DesignTokens.Spacing.lg)
                         .background(DesignTokens.Colors.backgroundPrimary)
                 }
             }

             if !generalTemplates.isEmpty {
                 Section {
                     templateList(generalTemplates)
                 } header: {
                     PromptSectionHeader(title: "All Templates")
                         .padding(.horizontal, DesignTokens.Spacing.lg)
                         .background(DesignTokens.Colors.backgroundPrimary)
                 }
             }

             if displayedTemplates.isEmpty {
                 EmptyStateView(
                     icon: "doc.text.magnifyingglass",
                     title: "No prompts found",
                     description: "Try adjusting your search or filters",
                     actionLabel: nil,
                     action: nil
                 )
             }
         }
         .padding(DesignTokens.Spacing.lg)
     }
 }
 .background(DesignTokens.Colors.backgroundPrimary)

 private func templateList(_ templates: [PromptTemplate]) -> some View {
     VStack(spacing: DesignTokens.Spacing.sm) {
         ForEach(templates) { template in
             PromptManagerRow(template: template) {
                 presentEditEditor(for: template)
             } onDelete: {
                 templatePendingDeletion = template
                 showDeleteConfirmation = true
             }
         }
     }
 }
 */
