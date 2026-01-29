//
//  TopFilterBar.swift
//  Promptist
//
//  Top bar containing search and app filter toggle.
//

import SwiftUI

struct TopFilterBar: View {
    @ObservedObject var viewModel: PromptListViewModel
    let onNewPrompt: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            // Search bar
            SearchField(text: $viewModel.filterState.searchText)
                .frame(maxWidth: 300)

            Spacer()

            // App filter toggle
            AppFilterToggle(viewModel: viewModel)

            // New Prompt button
            Button(action: onNewPrompt) {
                HStack(spacing: 6) {
                    Image(systemName: "plus")
                        .font(.system(size: 12, weight: .semibold))
                    Text("New Prompt")
                        .font(.system(size: 12, weight: .medium))
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.accentColor)
                .foregroundStyle(.white)
                .cornerRadius(8)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .navigationBackground()
    }
}

// MARK: - Search Field

struct SearchField: View {
    @Binding var text: String
    @FocusState private var isFocused: Bool

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 13))
                .foregroundStyle(.tertiary)

            TextField("Search templates...", text: $text)
                .textFieldStyle(.plain)
                .font(.system(size: 13))
                .focused($isFocused)

            if !text.isEmpty {
                Button(action: { text = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 12))
                        .foregroundStyle(.tertiary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(.quaternary)
        )
    }
}

// MARK: - App Filter Toggle

struct AppFilterToggle: View {
    @ObservedObject var viewModel: PromptListViewModel

    var body: some View {
        HStack(spacing: 8) {
            // Auto-detect toggle
            Button(action: { viewModel.toggleAutoDetectApp() }) {
                HStack(spacing: 4) {
                    Image(systemName: viewModel.filterState.autoDetectedApp ? "scope" : "scope")
                        .font(.system(size: 12))
                    Text("Auto")
                        .font(.system(size: 12, weight: .medium))
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(viewModel.filterState.autoDetectedApp ? AnyShapeStyle(Color.accentColor.opacity(0.15)) : AnyShapeStyle(.quaternary))
                )
                .foregroundStyle(viewModel.filterState.autoDetectedApp ? Color.accentColor : .secondary)
            }
            .buttonStyle(.plain)

            // Current app indicator
            if let appFilter = viewModel.detectedAppFilter,
               let displayName = appFilter.displayName ?? appFilter.trackedApp?.displayName {
                HStack(spacing: 4) {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 6, height: 6)
                    Text(displayName)
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    Capsule()
                        .fill(.quaternary)
                )
            }
        }
    }
}
