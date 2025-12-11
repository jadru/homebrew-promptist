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
        HStack(spacing: DesignTokens.Spacing.md) {
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
                        .font(DesignTokens.Typography.label())
                }
                .padding(.horizontal, DesignTokens.Spacing.md)
                .padding(.vertical, DesignTokens.Spacing.sm)
                .background(DesignTokens.Colors.accentPrimary)
                .foregroundColor(.white)
                .cornerRadius(DesignTokens.Radius.md)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, DesignTokens.Spacing.lg)
        .padding(.vertical, DesignTokens.Spacing.md)
        .background(DesignTokens.Colors.backgroundElevated)
    }
}

// MARK: - Search Field

struct SearchField: View {
    @Binding var text: String
    @FocusState private var isFocused: Bool

    var body: some View {
        HStack(spacing: DesignTokens.Spacing.sm) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 13))
                .foregroundColor(DesignTokens.Colors.foregroundTertiary)

            TextField("Search templates...", text: $text)
                .textFieldStyle(.plain)
                .font(DesignTokens.Typography.body(13))
                .focused($isFocused)

            if !text.isEmpty {
                Button(action: { text = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 12))
                        .foregroundColor(DesignTokens.Colors.foregroundTertiary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, DesignTokens.Spacing.md)
        .padding(.vertical, DesignTokens.Spacing.sm)
        .background(
            RoundedRectangle(cornerRadius: DesignTokens.Radius.md)
                .fill(DesignTokens.Colors.backgroundSecondary)
        )
        .overlay(
            RoundedRectangle(cornerRadius: DesignTokens.Radius.md)
                .stroke(isFocused ? DesignTokens.Colors.accentPrimary : DesignTokens.Colors.borderSubtle, lineWidth: 1)
        )
    }
}

// MARK: - App Filter Toggle

struct AppFilterToggle: View {
    @ObservedObject var viewModel: PromptListViewModel

    var body: some View {
        HStack(spacing: DesignTokens.Spacing.sm) {
            // Auto-detect toggle
            Button(action: { viewModel.toggleAutoDetectApp() }) {
                HStack(spacing: 4) {
                    Image(systemName: viewModel.filterState.autoDetectedApp ? "scope" : "scope")
                        .font(.system(size: 12))
                    Text("Auto")
                        .font(DesignTokens.Typography.label())
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(viewModel.filterState.autoDetectedApp ? DesignTokens.Colors.accentPrimary.opacity(0.15) : DesignTokens.Colors.backgroundSecondary)
                )
                .foregroundColor(viewModel.filterState.autoDetectedApp ? DesignTokens.Colors.accentPrimary : DesignTokens.Colors.foregroundSecondary)
            }
            .buttonStyle(.plain)

            // Current app indicator
            if let appFilter = viewModel.detectedAppFilter,
               let displayName = appFilter.displayName ?? appFilter.trackedApp?.displayName {
                HStack(spacing: 4) {
                    Circle()
                        .fill(DesignTokens.Colors.success)
                        .frame(width: 6, height: 6)
                    Text(displayName)
                        .font(DesignTokens.Typography.caption(11))
                        .foregroundColor(DesignTokens.Colors.foregroundSecondary)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    Capsule()
                        .fill(DesignTokens.Colors.backgroundSecondary)
                )
            }
        }
    }
}
