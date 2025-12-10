//
//  VariableInputDialog.swift
//  Promptist
//
//  Unified dialog for clipboard selection and input fields when executing prompts with variables
//

import SwiftUI
import AppKit

struct VariableInputDialog: View {
    let promptTitle: String
    let clipboardHistory: [ClipboardEntry]?
    let inputQuestions: [String]
    let onComplete: (VariableResolutionContext) -> Void
    let onCancel: () -> Void

    @State private var selectedClipboardId: UUID?
    @State private var inputResponses: [String: String] = [:]
    @FocusState private var focusedField: String?
    @State private var isWindowActive = false
    @EnvironmentObject private var languageSettings: LanguageSettings

    init(
        promptTitle: String,
        clipboardHistory: [ClipboardEntry]?,
        inputQuestions: [String],
        onComplete: @escaping (VariableResolutionContext) -> Void,
        onCancel: @escaping () -> Void
    ) {
        self.promptTitle = promptTitle
        self.clipboardHistory = clipboardHistory
        self.inputQuestions = inputQuestions
        self.onComplete = onComplete
        self.onCancel = onCancel

        // Initialize input responses
        var initialResponses: [String: String] = [:]
        for question in inputQuestions {
            initialResponses[question] = ""
        }
        _inputResponses = State(initialValue: initialResponses)

        // Select first clipboard entry by default
        if let first = clipboardHistory?.first {
            _selectedClipboardId = State(initialValue: first.id)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            header

            Divider()

            // Content
            ScrollView {
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.lg) {
                    // Clipboard selection
                    if let history = clipboardHistory, !history.isEmpty {
                        clipboardSection(history: history)
                    }

                    // Input fields
                    if !inputQuestions.isEmpty {
                        inputSection
                    }
                }
                .padding(DesignTokens.Spacing.lg)
            }

            Divider()

            // Footer
            footer
        }
        .background(DesignTokens.Colors.backgroundElevated)
        .frame(width: 480)
        .frame(minHeight: 280, maxHeight: 560)
        .interactiveDismissDisabled(false)
        .onAppear {
            // Ensure app is active and window receives focus
            activateWindowAndFocus()
            // Monitor window activation to restore focus if needed
            startMonitoringWindowActivation()
        }
        .onChange(of: isWindowActive) { _, newValue in
            if newValue, let firstQuestion = inputQuestions.first {
                // Restore focus when window becomes active
                focusedField = firstQuestion
            }
        }
    }

    // MARK: - Window Activation

    private func activateWindowAndFocus() {
        // Try multiple times with increasing delays to ensure focus is set
        // This handles the case where the window takes time to fully present
        for delay in [0.0, 0.05, 0.1, 0.2] {
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                // Activate the app
                NSApp.activate(ignoringOtherApps: true)

                // Find the dialog window (either sheet or floating window)
                if let dialogWindow = findDialogWindow() {
                    dialogWindow.makeKey()

                    // Only reset first responder on later attempts
                    if delay >= 0.05 {
                        dialogWindow.makeFirstResponder(nil)
                        dialogWindow.recalculateKeyViewLoop()
                    }

                    isWindowActive = true
                }

                // Set focus on first input field
                if let firstQuestion = inputQuestions.first {
                    focusedField = firstQuestion
                }
            }
        }
    }

    private func findDialogWindow() -> NSWindow? {
        // Try to find sheet first
        if let sheet = NSApp.windows.first(where: { $0.isSheet }) {
            return sheet
        }

        // Try to find floating window with our content
        if let floating = NSApp.windows.first(where: {
            $0.level == .floating && $0.isVisible && $0.isKeyWindow == false
        }) {
            return floating
        }

        // Fallback to modal panel
        return NSApp.windows.first(where: { $0.isVisible && $0.level == .modalPanel })
    }

    private func startMonitoringWindowActivation() {
        // Monitor for window deactivation/reactivation
        Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { timer in
            // Find the dialog window
            if let dialogWindow = findDialogWindow() {
                let wasActive = isWindowActive
                isWindowActive = dialogWindow.isKeyWindow

                // If window just became active, ensure focus
                if !wasActive && isWindowActive {
                    if let firstQuestion = inputQuestions.first {
                        focusedField = firstQuestion
                    }
                }
            } else {
                // Dialog was closed
                timer.invalidate()
            }
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.xxs) {
            Text(languageSettings.localized("variable_input.title"))
                .font(DesignTokens.Typography.headline(DesignTokens.Typography.headlineLarge))
                .foregroundColor(DesignTokens.Colors.foregroundPrimary)

            Text(promptTitle)
                .font(DesignTokens.Typography.caption())
                .foregroundColor(DesignTokens.Colors.foregroundSecondary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(DesignTokens.Spacing.lg)
    }

    // MARK: - Clipboard Section

    private func clipboardSection(history: [ClipboardEntry]) -> some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
            Text(languageSettings.localized("variable_input.clipboard_section"))
                .font(DesignTokens.Typography.label(weight: .semibold))
                .foregroundColor(DesignTokens.Colors.foregroundSecondary)

            VStack(spacing: DesignTokens.Spacing.xs) {
                ForEach(history) { entry in
                    ClipboardEntryRow(
                        entry: entry,
                        isSelected: selectedClipboardId == entry.id,
                        onSelect: { selectedClipboardId = entry.id }
                    )
                }
            }
        }
    }

    // MARK: - Input Section

    private var inputSection: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
            Text(languageSettings.localized("variable_input.input_section"))
                .font(DesignTokens.Typography.label(weight: .semibold))
                .foregroundColor(DesignTokens.Colors.foregroundSecondary)

            VStack(spacing: DesignTokens.Spacing.md) {
                ForEach(Array(inputQuestions.enumerated()), id: \.element) { index, question in
                    InputFieldRow(
                        question: question,
                        text: Binding(
                            get: { inputResponses[question] ?? "" },
                            set: { inputResponses[question] = $0 }
                        ),
                        isFocused: focusedField == question
                    )
                    .focused($focusedField, equals: question)
                    // Set default focus on first field
                    .defaultFocus($focusedField, question, priority: index == 0 ? .userInitiated : .automatic)
                }
            }
        }
    }

    // MARK: - Footer

    private var footer: some View {
        HStack {
            Spacer()

            Button(languageSettings.localized("button.cancel"), action: onCancel)
                .keyboardShortcut(.escape, modifiers: [])

            Button(languageSettings.localized("variable_input.button.copy")) {
                complete()
            }
            .keyboardShortcut(.return, modifiers: [])
            .buttonStyle(.borderedProminent)
        }
        .padding(DesignTokens.Spacing.lg)
    }

    // MARK: - Actions

    private func complete() {
        var context = VariableResolutionContext()

        // Set clipboard selection
        if let selectedId = selectedClipboardId,
           let history = clipboardHistory,
           let entry = history.first(where: { $0.id == selectedId }) {
            context.clipboardSelection = entry.content
        }

        // Set input responses
        context.inputResponses = inputResponses

        onComplete(context)
    }
}

// MARK: - Clipboard Entry Row

private struct ClipboardEntryRow: View {
    let entry: ClipboardEntry
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: DesignTokens.Spacing.sm) {
                Image(systemName: isSelected ? "largecircle.fill.circle" : "circle")
                    .font(.system(size: DesignTokens.IconSize.md))
                    .foregroundColor(isSelected ? DesignTokens.Colors.accentPrimary : DesignTokens.Colors.foregroundTertiary)

                Text(entry.preview)
                    .font(DesignTokens.Typography.body())
                    .foregroundColor(DesignTokens.Colors.foregroundPrimary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)

                Spacer()
            }
            .padding(DesignTokens.Spacing.sm)
            .background(
                RoundedRectangle(cornerRadius: DesignTokens.Radius.sm, style: .continuous)
                    .fill(isSelected ? DesignTokens.Colors.selectedBackground : Color.clear)
            )
            .overlay(
                RoundedRectangle(cornerRadius: DesignTokens.Radius.sm, style: .continuous)
                    .stroke(
                        isSelected ? DesignTokens.Colors.accentPrimary.opacity(0.3) : DesignTokens.Colors.borderSubtle,
                        lineWidth: 1
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Input Field Row

private struct InputFieldRow: View {
    let question: String
    @Binding var text: String
    let isFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
            Text(question)
                .font(DesignTokens.Typography.label())
                .foregroundColor(DesignTokens.Colors.foregroundPrimary)

            TextField("", text: $text)
                .textFieldStyle(.roundedBorder)
                .font(DesignTokens.Typography.body())
                // Ensure TextField is always enabled and interactive
                .disabled(false)
                .allowsHitTesting(true)
        }
    }
}

// MARK: - Preview

#Preview {
    VariableInputDialog(
        promptTitle: "Email Template",
        clipboardHistory: [
            ClipboardEntry(content: "First clipboard item with some long text that should be truncated"),
            ClipboardEntry(content: "Second clipboard item"),
            ClipboardEntry(content: "Third clipboard item")
        ],
        inputQuestions: ["Email Subject", "Tone (formal/casual)"],
        onComplete: { _ in },
        onCancel: {}
    )
}
