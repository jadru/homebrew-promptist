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

    var body: some View {
        HStack(spacing: 12) {
            // Search field
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                    .font(.system(size: 14, weight: .medium))

                TextField("Search prompts...", text: $searchText)
                    .textFieldStyle(.plain)
                    .font(.system(size: 15))
                    .focused($isFocused)
                    .submitLabel(.search)

                if !searchText.isEmpty {
                    Button(action: {
                        searchText = ""
                        isFocused = true
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.tertiary)
                            .font(.system(size: 14, weight: .medium))
                    }
                    .buttonStyle(.plain)
                    .help("Clear search")
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .liquidGlass(.clear)

            // More menu button
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
                    .foregroundStyle(.secondary)
                    .font(.system(size: 14, weight: .medium))
                    .frame(width: 32, height: 32)
                    .liquidGlass(.clear)
            }
            .menuStyle(.borderlessButton)
            .menuIndicator(.hidden)
            .fixedSize()
        }
        .padding(.horizontal, 12)
        .padding(.top, 16)
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
