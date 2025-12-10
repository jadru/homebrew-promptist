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
    var onQuit: (() -> Void)? = nil

    @EnvironmentObject private var languageSettings: LanguageSettings

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

            // More menu button (vertical ellipsis)
            Menu {
                Button(action: onManage) {
                    Label(languageSettings.localized("launcher.menu.manage_templates"), systemImage: "doc.text")
                }

                Divider()

                Button(role: .destructive, action: { onQuit?() ?? quitApp() }) {
                    Label(languageSettings.localized("launcher.menu.quit"), systemImage: "power")
                }
            } label: {
                Image(systemName: "ellipsis")
                    .rotationEffect(.degrees(90))
                    .foregroundColor(tokens.Colors.secondaryText)
                    .font(.system(size: 14, weight: .medium))
                    .frame(width: 32, height: 32)
                    .background(tokens.Colors.searchBackground)
                    .cornerRadius(8)
            }
            .menuStyle(.borderlessButton)
            .menuIndicator(.hidden)
            .fixedSize()
        }
        .padding(.top, tokens.Layout.searchPadding)
        .padding(.bottom, 8)
    }

    private func quitApp() {
        NSApplication.shared.terminate(nil)
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
            .environmentObject(LanguageSettings())
        }
    }

    return PreviewWrapper()
}
