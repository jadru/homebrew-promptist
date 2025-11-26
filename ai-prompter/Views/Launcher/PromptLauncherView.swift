//
//  PromptLauncherView.swift
//  ai-prompter
//
//  Minimal prompt launcher popover - Raycast-style command palette
//

import SwiftUI
import AppKit
import UserNotifications

struct PromptLauncherView: View {
    @EnvironmentObject private var appContext: AppContextService

    @StateObject private var viewModel: PromptLauncherViewModel
    @FocusState private var searchFocused: Bool
    @Environment(\.openWindow) private var openWindow

    private let tokens = LauncherDesignTokens.self

    init(repository: PromptTemplateRepository = FilePromptTemplateRepository()) {
        _viewModel = StateObject(wrappedValue: PromptLauncherViewModel(
            repository: repository,
            appContext: AppContextService()
        ))
    }

    var body: some View {
        VStack(spacing: 0) {
            // Search bar
            PromptSearchBar(
                searchText: $viewModel.searchText,
                isFocused: $searchFocused
            )

            // Thin separator
            Divider()
                .background(tokens.Colors.separator)

            // Prompt list
            PromptList(
                viewModel: viewModel,
                onExecute: executePrompt
            )
        }
        .frame(width: tokens.Layout.popoverWidth)
        .frame(
            minHeight: tokens.Layout.popoverMinHeight,
            maxHeight: tokens.Layout.popoverMaxHeight
        )
        .background(tokens.Colors.popoverBackground)
        .onAppear {
            searchFocused = true
            viewModel.refresh()
        }
        .onKeyPress(.upArrow) {
            viewModel.moveSelectionUp()
            return .handled
        }
        .onKeyPress(.downArrow) {
            viewModel.moveSelectionDown()
            return .handled
        }
        .onKeyPress(.return) {
            if let prompt = viewModel.executeSelected() {
                executePrompt(prompt)
            }
            return .handled
        }
        .onKeyPress(.escape) {
            closePopover()
            return .handled
        }
    }

    // MARK: - Actions

    private func executePrompt(_ prompt: PromptTemplate) {
        // Copy to clipboard
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(prompt.content, forType: .string)

        // Show notification
        showNotification(for: prompt)

        // Close popover
        closePopover()
    }

    private func closePopover() {
        // Close the menu bar extra popover
        NSApp.sendAction(#selector(NSStatusBarButton.performClick(_:)), to: nil, from: nil)
    }

    private func openManagerWindow() {
        openWindow(id: "manager")
        closePopover()
    }

    private func showNotification(for prompt: PromptTemplate) {
        let content = UNMutableNotificationContent()
        content.title = "Prompt Copied"
        content.body = prompt.title
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )

        UNUserNotificationCenter.current().add(request)
    }
}

// MARK: - Preview

#Preview {
    PromptLauncherView(repository: FilePromptTemplateRepository())
        .environmentObject(AppContextService())
        .frame(width: LauncherDesignTokens.Layout.popoverWidth)
}
