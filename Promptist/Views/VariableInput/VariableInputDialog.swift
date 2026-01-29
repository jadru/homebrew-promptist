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
                VStack(alignment: .leading, spacing: 20) {
                    // Clipboard selection
                    if let history = clipboardHistory, !history.isEmpty {
                        clipboardSection(history: history)
                    }

                    // Input fields
                    if !inputQuestions.isEmpty {
                        inputSection
                    }
                }
                .padding(20)
            }

            Divider()

            // Footer
            footer
        }
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
        VStack(alignment: .leading, spacing: 4) {
            Text(languageSettings.localized("variable_input.title"))
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(.primary)

            Text(promptTitle)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
    }

    // MARK: - Clipboard Section

    private func clipboardSection(history: [ClipboardEntry]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(languageSettings.localized("variable_input.clipboard_section"))
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.secondary)

            VStack(spacing: 6) {
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
        VStack(alignment: .leading, spacing: 8) {
            Text(languageSettings.localized("variable_input.input_section"))
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.secondary)

            VStack(spacing: 12) {
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
        .padding(20)
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
            HStack(spacing: 8) {
                Image(systemName: isSelected ? "largecircle.fill.circle" : "circle")
                    .font(.system(size: 16))
                    .foregroundStyle(isSelected ? AnyShapeStyle(Color.accentColor) : AnyShapeStyle(.tertiary))

                Text(entry.preview)
                    .font(.system(size: 14))
                    .foregroundStyle(.primary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)

                Spacer()
            }
            .padding(8)
            .background(
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(isSelected ? Color.accentColor.opacity(0.12) : Color.clear)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .stroke(
                        isSelected ? Color.accentColor.opacity(0.3) : Color.primary.opacity(0.1),
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
        VStack(alignment: .leading, spacing: 6) {
            Text(question)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.primary)

            TextField("", text: $text)
                .textFieldStyle(.roundedBorder)
                .font(.system(size: 14))
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
