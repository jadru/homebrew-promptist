//
//  CollectionRail.swift
//  Promptist
//
//  Horizontal scrolling collection filter rail.
//  Shows user collections with template counts.
//

import SwiftUI

struct CollectionRail: View {
    @ObservedObject var viewModel: PromptListViewModel
    @State private var showAddCollection = false
    @State private var newCollectionName = ""

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: DesignTokens.Spacing.sm) {
                // "All" chip
                CollectionChip(
                    name: "All",
                    icon: "tray.full",
                    count: nil,
                    isSelected: viewModel.filterState.selectedCollectionId == nil,
                    onSelect: { viewModel.selectCollection(nil) }
                )

                if !viewModel.allCollections.isEmpty {
                    Divider()
                        .frame(height: 20)
                        .padding(.horizontal, DesignTokens.Spacing.xs)
                }

                // User collections
                ForEach(viewModel.allCollections.sorted { $0.sortOrder < $1.sortOrder }) { collection in
                    CollectionChip(
                        name: collection.name,
                        icon: "folder",
                        count: viewModel.templateCount(forCollection: collection.id),
                        isSelected: viewModel.filterState.selectedCollectionId == collection.id,
                        onSelect: { viewModel.selectCollection(collection.id) }
                    )
                    .contextMenu {
                        Button("Rename...") {
                            // Rename handled by parent view
                        }
                        Divider()
                        Button("Delete", role: .destructive) {
                            viewModel.deleteCollection(collection.id)
                        }
                    }
                }

                // Add collection button
                Button(action: { showAddCollection = true }) {
                    HStack(spacing: 4) {
                        Image(systemName: "plus.circle")
                            .font(.system(size: 12))
                        Text("New")
                            .font(DesignTokens.Typography.label())
                    }
                    .foregroundColor(DesignTokens.Colors.accentPrimary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, DesignTokens.Spacing.md)
            .padding(.vertical, DesignTokens.Spacing.sm)
        }
        .background(DesignTokens.Colors.backgroundElevated)
        .sheet(isPresented: $showAddCollection) {
            CollectionEditorView(
                collectionName: $newCollectionName,
                isEditing: false,
                onCreate: {
                    let name = newCollectionName.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !name.isEmpty else { return }
                    let collection = PromptTemplateCollection(
                        name: name,
                        sortOrder: viewModel.nextCollectionSortOrder
                    )
                    viewModel.addCollection(collection)
                    newCollectionName = ""
                    showAddCollection = false
                },
                onCancel: {
                    newCollectionName = ""
                    showAddCollection = false
                }
            )
        }
    }
}

// MARK: - Collection Chip

struct CollectionChip: View {
    let name: String
    let icon: String
    var count: Int?
    let isSelected: Bool
    let onSelect: () -> Void

    @State private var isHovering = false

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 11))

                Text(name)
                    .font(DesignTokens.Typography.label())
                    .lineLimit(1)

                if let count = count, count > 0 {
                    Text("(\(count))")
                        .font(DesignTokens.Typography.caption(10))
                        .foregroundColor(isSelected ? .white.opacity(0.7) : DesignTokens.Colors.foregroundTertiary)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(backgroundColor)
            )
            .foregroundColor(foregroundColor)
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            isHovering = hovering
        }
    }

    private var backgroundColor: Color {
        if isSelected {
            return DesignTokens.Colors.accentPrimary
        } else if isHovering {
            return DesignTokens.Colors.hoverBackground
        } else {
            return DesignTokens.Colors.backgroundSecondary
        }
    }

    private var foregroundColor: Color {
        if isSelected {
            return .white
        } else {
            return DesignTokens.Colors.foregroundPrimary
        }
    }
}
