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
    @EnvironmentObject private var languageSettings: LanguageSettings
    @State private var showAddCollection = false
    @State private var newCollectionName = ""

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                // "All" chip
                CollectionChip(
                    name: languageSettings.localized("collection.filter.all.short"),
                    icon: "tray.full",
                    count: nil,
                    isSelected: viewModel.filterState.selectedCollectionId == nil,
                    onSelect: { viewModel.selectCollection(nil) }
                )

                if !viewModel.allCollections.isEmpty {
                    Divider()
                        .frame(height: 20)
                        .padding(.horizontal, 6)
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
                        Button(languageSettings.localized("collection.rename.ellipsis")) {
                            // Rename handled by parent view
                        }
                        Divider()
                        Button(languageSettings.localized("collection.delete"), role: .destructive) {
                            viewModel.deleteCollection(collection.id)
                        }
                    }
                }

                // Add collection button
                Button(action: { showAddCollection = true }) {
                    HStack(spacing: 4) {
                        Image(systemName: "plus.circle")
                            .font(.system(size: 12))
                        Text(languageSettings.localized("collection.new"))
                            .font(.system(size: 12, weight: .medium))
                    }
                    .foregroundStyle(.accent)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
        }
        .navigationBackground()
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
                    .font(.system(size: 12, weight: .medium))
                    .lineLimit(1)

                if let count = count, count > 0 {
                    Text("(\(count))")
                        .font(.system(size: 10))
                        .foregroundStyle(isSelected ? AnyShapeStyle(Color.white.opacity(0.7)) : AnyShapeStyle(.tertiary))
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(backgroundColor)
            )
            .foregroundStyle(foregroundColor)
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            isHovering = hovering
        }
    }

    private var backgroundColor: Color {
        if isSelected {
            return Color.accentColor
        } else {
            return .clear
        }
    }

    private var foregroundColor: Color {
        if isSelected {
            return .white
        } else {
            return .primary
        }
    }
}
