//
//  PromptLauncherView.swift
//  Promptist
//
//  Promptist Launcher - Minimal prompt launcher popover - Raycast-style command palette
//

import SwiftUI
import AppKit
import UserNotifications

struct PromptLauncherView: View {
    @EnvironmentObject private var appContext: AppContextService
    @EnvironmentObject private var executionService: PromptExecutionService
    @EnvironmentObject private var languageSettings: LanguageSettings

    @StateObject private var viewModel: PromptLauncherViewModel
    @FocusState private var searchFocused: Bool
    @Environment(\.openWindow) private var openWindow

    // Variable input dialog state
    @State private var showVariableDialog = false
    @State private var pendingExecution: PromptExecutionService.ParsedExecution?
    @State private var variableDialogWindow: NSWindow?

    // Preview panel position state
    @State private var previewOnLeft = false
    @State private var lastCheckedFrame: CGRect = .zero

    private let tokens = LauncherDesignTokens.self

    init(repository: PromptTemplateRepository = FilePromptTemplateRepository()) {
        _viewModel = StateObject(wrappedValue: PromptLauncherViewModel(
            repository: repository,
            appContext: AppContextService()
        ))
    }

    var body: some View {
        GlassContainer {
            HStack(spacing: 0) {
                // Preview panel on left (when needed)
                if viewModel.previewPrompt != nil && previewOnLeft {
                    PromptPreviewPanel(
                        prompt: viewModel.previewPrompt,
                        shortcut: viewModel.previewShortcut
                    )

                    Divider()
                }

                // Main launcher content
                VStack(spacing: 0) {
                    // Search bar
                    PromptSearchBar(
                        searchText: $viewModel.searchText,
                        isFocused: $searchFocused,
                        onManage: openManagerWindow
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

                // Preview panel on right (default)
                if viewModel.previewPrompt != nil && !previewOnLeft {
                    Divider()

                    PromptPreviewPanel(
                        prompt: viewModel.previewPrompt,
                        shortcut: viewModel.previewShortcut
                    )
                }
            }
        }
        .frame(
            minHeight: tokens.Layout.popoverMinHeight,
            maxHeight: tokens.Layout.popoverMaxHeight
        )
        .background(tokens.Colors.popoverBackground)
        .onAppear {
            searchFocused = true
            viewModel.refresh()
            // Schedule preview position check without causing layout loops
            DispatchQueue.main.async {
                updatePreviewPositionIfNeeded()
            }
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
        .onChange(of: showVariableDialog) { _, newValue in
            if newValue {
                showVariableDialogWindow()
            } else {
                closeVariableDialogWindow()
            }
        }
    }

    // MARK: - Actions

    private func executePrompt(_ prompt: PromptTemplate) {
        Task {
            let result = await executionService.prepareExecution(for: prompt)

            switch result {
            case .directCopy(let resolvedContent):
                copyAndFinish(resolvedContent, prompt: prompt)

            case .needsInput(let parsed):
                // Set pending execution and show dialog immediately
                await MainActor.run {
                    pendingExecution = parsed
                    showVariableDialog = true
                }
            }
        }
    }

    private func completeVariableExecution(parsed: PromptExecutionService.ParsedExecution, userContext: VariableResolutionContext) {
        // Close dialog first
        showVariableDialog = false
        pendingExecution = nil

        // Then copy and finish
        let resolved = executionService.completeExecution(parsed: parsed, userContext: userContext)
        copyAndFinish(resolved, prompt: parsed.prompt)
    }

    private func copyAndFinish(_ content: String, prompt: PromptTemplate) {
        // Copy to clipboard
        executionService.copyToClipboard(content)

        // Increment usage count
        viewModel.incrementUsageCount(for: prompt.id)

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

    // MARK: - Variable Dialog Window

    private func showVariableDialogWindow() {
        guard let parsed = pendingExecution else { return }

        // Close existing window if any
        closeVariableDialogWindow()

        // Create the dialog content view
        let dialogView = VariableInputDialog(
            promptTitle: parsed.prompt.title,
            clipboardHistory: parsed.parseResult.hasClipboardVariable ? executionService.currentClipboardHistory : nil,
            inputQuestions: parsed.parseResult.uniqueInputQuestions,
            onComplete: { userContext in
                completeVariableExecution(parsed: parsed, userContext: userContext)
            },
            onCancel: {
                showVariableDialog = false
                pendingExecution = nil
            }
        )
        .environmentObject(appContext)
        .environmentObject(executionService)
        .environmentObject(languageSettings)

        // Create hosting controller
        let hostingController = NSHostingController(rootView: dialogView)
        hostingController.sizingOptions = [.intrinsicContentSize]

        // Pre-render to get proper size and avoid layout shift
        hostingController.view.layoutSubtreeIfNeeded()
        let contentSize = hostingController.view.fittingSize

        // Create window
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: contentSize.width, height: contentSize.height),
            styleMask: [.titled],
            backing: .buffered,
            defer: false
        )

        window.contentViewController = hostingController
        window.isReleasedWhenClosed = false
        window.level = .floating  // Keep above menu bar popover
        window.title = "Variable Input"
        window.titlebarAppearsTransparent = true
        window.titleVisibility = .hidden
        window.isMovableByWindowBackground = true

        // Center on screen
        window.center()

        // Show window
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)

        variableDialogWindow = window
    }

    private func closeVariableDialogWindow() {
        variableDialogWindow?.close()
        variableDialogWindow = nil
    }

    // MARK: - Preview Panel Position

    private func updatePreviewPositionIfNeeded() {
        // Get the menu bar window frame directly without GeometryReader
        guard let window = NSApp.windows.first(where: { window in
            String(describing: type(of: window)).contains("MenuBarExtraWindow")
        }) else {
            return
        }

        let frame = window.frame

        // Only update if the frame has actually changed significantly
        // This prevents infinite loops from minor floating-point variations
        let threshold: CGFloat = 1.0
        guard abs(frame.origin.x - lastCheckedFrame.origin.x) > threshold ||
              abs(frame.origin.y - lastCheckedFrame.origin.y) > threshold ||
              abs(frame.width - lastCheckedFrame.width) > threshold ||
              abs(frame.height - lastCheckedFrame.height) > threshold else {
            return
        }

        lastCheckedFrame = frame

        // Get the screen containing this window
        guard let screen = NSScreen.screens.first(where: { screen in
            screen.frame.intersects(frame)
        }) ?? NSScreen.main else {
            return
        }

        let previewPanelWidth: CGFloat = 280  // PromptPreviewPanel.Layout.panelWidth
        let screenRight = screen.visibleFrame.maxX
        let popoverRight = frame.maxX

        // Calculate available space on the right
        let rightSpace = screenRight - popoverRight

        // If not enough space on the right for preview panel, show on left
        let needsLeftPosition = rightSpace < previewPanelWidth + 20  // 20pt buffer

        // Only update state if it actually needs to change
        if needsLeftPosition != previewOnLeft {
            previewOnLeft = needsLeftPosition
        }
    }
}

// MARK: - Preview

#Preview {
    let permissionManager = AccessibilityPermissionManager()
    let clipboardHistory = ClipboardHistoryManager()
    let selectionGrabber = SelectionGrabber(permissionManager: permissionManager)
    let executionService = PromptExecutionService(
        selectionGrabber: selectionGrabber,
        clipboardHistory: clipboardHistory
    )

    return PromptLauncherView(repository: FilePromptTemplateRepository())
        .environmentObject(AppContextService())
        .environmentObject(executionService)
        .environmentObject(LanguageSettings())
        .frame(width: LauncherDesignTokens.Layout.popoverWidth)
}
