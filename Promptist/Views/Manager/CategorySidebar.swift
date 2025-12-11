//
//  CategorySidebar.swift
//  Promptist
//
//  Left sidebar for hierarchical category navigation.
//  Shows major categories with expandable subcategories.
//

import SwiftUI

struct CategorySidebar: View {
    @ObservedObject var viewModel: PromptListViewModel
    @State private var expandedCategories: Set<UUID> = []

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                Text("Categories")
                    .font(DesignTokens.Typography.headline(14, weight: .semibold))
                    .foregroundColor(DesignTokens.Colors.foregroundPrimary)
                Spacer()
            }
            .padding(.horizontal, DesignTokens.Spacing.md)
            .padding(.vertical, DesignTokens.Spacing.sm)

            Divider()

            // "All Categories" option
            CategoryRow(
                name: "All Categories",
                icon: "square.grid.2x2",
                count: viewModel.allTemplates.count,
                isSelected: viewModel.filterState.selectedCategoryId == nil,
                hasChildren: false,
                isExpanded: false,
                onSelect: { viewModel.selectCategory(nil) },
                onToggleExpand: nil
            )

            Divider()
                .padding(.vertical, DesignTokens.Spacing.xs)

            // Category list
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(viewModel.rootCategories) { category in
                        CategoryRowWithChildren(
                            category: category,
                            viewModel: viewModel,
                            expandedCategories: $expandedCategories
                        )
                    }
                }
            }

            Spacer()
        }
        .frame(width: 220)
        .background(DesignTokens.Colors.backgroundSecondary)
    }
}

// MARK: - Category Row with Children

struct CategoryRowWithChildren: View {
    let category: PromptCategory
    @ObservedObject var viewModel: PromptListViewModel
    @Binding var expandedCategories: Set<UUID>

    private var children: [PromptCategory] {
        viewModel.childCategories(of: category.id)
    }

    private var isExpanded: Bool {
        expandedCategories.contains(category.id)
    }

    private var isSelected: Bool {
        viewModel.filterState.selectedCategoryId == category.id
    }

    private var isChildSelected: Bool {
        guard let selectedId = viewModel.filterState.selectedCategoryId else { return false }
        return children.contains { $0.id == selectedId }
    }

    var body: some View {
        VStack(spacing: 0) {
            CategoryRow(
                name: category.name,
                icon: category.icon,
                count: viewModel.templateCount(for: category.id),
                isSelected: isSelected,
                hasChildren: !children.isEmpty,
                isExpanded: isExpanded,
                onSelect: { viewModel.selectCategory(category.id) },
                onToggleExpand: children.isEmpty ? nil : {
                    withAnimation(DesignTokens.Animation.fast) {
                        if isExpanded {
                            expandedCategories.remove(category.id)
                        } else {
                            expandedCategories.insert(category.id)
                        }
                    }
                }
            )

            if isExpanded {
                ForEach(children) { child in
                    CategoryRow(
                        name: child.name,
                        icon: child.icon,
                        count: viewModel.templateCount(for: child.id),
                        isSelected: viewModel.filterState.selectedCategoryId == child.id,
                        hasChildren: false,
                        isExpanded: false,
                        indentLevel: 1,
                        onSelect: { viewModel.selectCategory(child.id) },
                        onToggleExpand: nil
                    )
                }
            }
        }
        .onAppear {
            // Auto-expand if a child is selected
            if isChildSelected && !isExpanded {
                expandedCategories.insert(category.id)
            }
        }
    }
}

// MARK: - Category Row

struct CategoryRow: View {
    let name: String
    let icon: String
    var count: Int = 0
    let isSelected: Bool
    let hasChildren: Bool
    let isExpanded: Bool
    var indentLevel: Int = 0
    let onSelect: () -> Void
    let onToggleExpand: (() -> Void)?

    @State private var isHovering = false

    var body: some View {
        HStack(spacing: DesignTokens.Spacing.sm) {
            // Expand/collapse button for parent categories
            if hasChildren {
                Button(action: { onToggleExpand?() }) {
                    Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(DesignTokens.Colors.foregroundTertiary)
                        .frame(width: 16, height: 16)
                }
                .buttonStyle(.plain)
            } else {
                Spacer()
                    .frame(width: 16)
            }

            // Icon
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(isSelected ? DesignTokens.Colors.accentPrimary : DesignTokens.Colors.foregroundSecondary)
                .frame(width: 18)

            // Name
            Text(name)
                .font(DesignTokens.Typography.body(13))
                .foregroundColor(isSelected ? DesignTokens.Colors.accentPrimary : DesignTokens.Colors.foregroundPrimary)
                .lineLimit(1)

            Spacer()

            // Count badge
            if count > 0 {
                Text("\(count)")
                    .font(DesignTokens.Typography.caption(10))
                    .foregroundColor(DesignTokens.Colors.foregroundTertiary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(
                        Capsule()
                            .fill(DesignTokens.Colors.backgroundTertiary)
                    )
            }
        }
        .padding(.horizontal, DesignTokens.Spacing.md)
        .padding(.leading, CGFloat(indentLevel) * 20)
        .padding(.vertical, DesignTokens.Spacing.sm)
        .background(
            RoundedRectangle(cornerRadius: DesignTokens.Radius.sm)
                .fill(backgroundColor)
        )
        .contentShape(Rectangle())
        .onTapGesture {
            onSelect()
        }
        .onHover { hovering in
            isHovering = hovering
        }
    }

    private var backgroundColor: Color {
        if isSelected {
            return DesignTokens.Colors.selectedBackground
        } else if isHovering {
            return DesignTokens.Colors.hoverBackground
        } else {
            return .clear
        }
    }
}
