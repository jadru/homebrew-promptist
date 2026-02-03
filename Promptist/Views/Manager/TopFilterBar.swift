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
    @EnvironmentObject private var languageSettings: LanguageSettings

    var body: some View {
        HStack(spacing: 12) {
            // Search bar
            SearchField(text: $viewModel.filterState.searchText)
                .frame(maxWidth: 300)

            Spacer()

            // App filter toggle
            AppFilterToggle(viewModel: viewModel)

            // New Prompt button
            ActionButton(
                languageSettings.localized("prompt_manager.toolbar.new_prompt"),
                icon: "plus",
                variant: .primary,
                action: onNewPrompt
            )
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .navigationBackground()
    }
}

// MARK: - Search Field

struct SearchField: View {
    @Binding var text: String
    @EnvironmentObject private var languageSettings: LanguageSettings
    @FocusState private var isFocused: Bool

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 13))
                .foregroundStyle(.tertiary)

            TextField(languageSettings.localized("search.templates.placeholder"), text: $text)
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
    @EnvironmentObject private var languageSettings: LanguageSettings

    var body: some View {
        HStack(spacing: 8) {
            // Auto-detect toggle
            Button(action: { viewModel.toggleAutoDetectApp() }) {
                HStack(spacing: 4) {
                    Image(systemName: viewModel.filterState.autoDetectedApp ? "scope" : "scope")
                        .font(.system(size: 12))
                    Text(languageSettings.localized("filter.auto"))
                        .font(.system(size: 12, weight: .medium))
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(viewModel.filterState.autoDetectedApp ? Color.accentColor.opacity(0.15) : Color.primary.opacity(0.06))
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
                        .fill(Color.primary.opacity(0.06))
                )
            }
        }
    }
}
