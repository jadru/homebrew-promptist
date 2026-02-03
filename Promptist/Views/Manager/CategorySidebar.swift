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
    @EnvironmentObject private var languageSettings: LanguageSettings
    @State private var expandedCategories: Set<UUID> = []

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                Text(languageSettings.localized("category.sidebar.title"))
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.primary)
                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)

            Divider()

            // "All Categories" option
            CategoryRow(
                name: languageSettings.localized("category.all"),
                icon: "square.grid.2x2",
                count: viewModel.allTemplates.count,
                isSelected: viewModel.filterState.selectedCategoryId == nil,
                hasChildren: false,
                isExpanded: false,
                onSelect: { viewModel.selectCategory(nil) },
                onToggleExpand: nil
            )

            Divider()
                .padding(.vertical, 6)

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
        .glassSurface()
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
                    withAnimation(.easeInOut(duration: 0.15)) {
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
        HStack(spacing: 8) {
            // Expand/collapse button for parent categories
            if hasChildren {
                Button(action: { onToggleExpand?() }) {
                    Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(.tertiary)
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
                .foregroundStyle(isSelected ? Color.accentColor : .secondary)
                .frame(width: 18)

            // Name
            Text(name)
                .font(.system(size: 13))
                .foregroundStyle(isSelected ? Color.accentColor : .primary)
                .lineLimit(1)

            Spacer()

            // Count badge
            if count > 0 {
                Text("\(count)")
                    .font(.system(size: 10))
                    .foregroundStyle(.tertiary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(countBadgeBackground)
            }
        }
        .padding(.horizontal, 12)
        .padding(.leading, CGFloat(indentLevel) * 20)
        .padding(.vertical, 8)
        .glassInteractiveRow(isSelected: isSelected, isHovered: isHovering, cornerRadius: 6)
        .contentShape(Rectangle())
        .onTapGesture {
            onSelect()
        }
        .onHover { hovering in
            isHovering = hovering
        }
    }

    // Count badge glass
    private var countBadgeBackground: some View {
        Group {
            if #available(macOS 26.0, *) {
                Capsule()
                    .fill(.clear)
                    .glassEffect(.clear, in: Capsule())
            } else {
                Capsule()
                    .fill(.quaternary)
            }
        }
    }
}
