//
//  PromptSearchBar.swift
//  Promptist
//
//  Minimal search bar for Promptist Launcher
//

import SwiftUI

struct PromptSearchBar: View {
    @Binding var searchText: String
    @FocusState.Binding var isFocused: Bool
    let onManage: () -> Void

    private let tokens = LauncherDesignTokens.self

    var body: some View {
        HStack(spacing: 12) {
            // Search field
            HStack(spacing: 8) {
                // Search icon
                Image(systemName: "magnifyingglass")
                    .foregroundColor(tokens.Colors.secondaryText)
                    .font(.system(size: 14, weight: .medium))

                // Text field
                TextField("Search prompts...", text: $searchText)
                    .textFieldStyle(.plain)
                    .font(tokens.Typography.searchFont)
                    .focused($isFocused)
                    .submitLabel(.search)

                // Clear button (only when text is present)
                if !searchText.isEmpty {
                    Button(action: {
                        searchText = ""
                        isFocused = true
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(tokens.Colors.tertiaryText)
                            .font(.system(size: 14, weight: .medium))
                    }
                    .buttonStyle(.plain)
                    .help("Clear search")
                }
            }
            .padding(.horizontal, tokens.Layout.horizontalPadding)
            .padding(.vertical, 10)
            .background(tokens.Colors.searchBackground)
            .cornerRadius(8)

            // Manage button
            Button(action: onManage) {
                Image(systemName: "slider.horizontal.3")
                    .foregroundColor(tokens.Colors.secondaryText)
                    .font(.system(size: 14, weight: .medium))
                    .frame(width: 32, height: 32)
                    .background(tokens.Colors.searchBackground)
                    .cornerRadius(8)
            }
            .buttonStyle(.plain)
            .help("Manage Prompts")
        }
        .padding(.top, tokens.Layout.searchPadding)
        .padding(.bottom, 8)
    }
}

// MARK: - Preview

#Preview {
    struct PreviewWrapper: View {
        @State private var searchText = ""
        @FocusState private var isFocused: Bool

        var body: some View {
            VStack(spacing: 20) {
                PromptSearchBar(
                    searchText: $searchText,
                    isFocused: $isFocused,
                    onManage: { print("Manage tapped") }
                )

                PromptSearchBar(
                    searchText: .constant("fuzzy search"),
                    isFocused: $isFocused,
                    onManage: { print("Manage tapped") }
                )
            }
            .frame(width: 540)
            .background(Color(nsColor: .windowBackgroundColor))
        }
    }

    return PreviewWrapper()
}
