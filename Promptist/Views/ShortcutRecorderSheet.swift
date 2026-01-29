import SwiftUI
import AppKit

struct ShortcutRecorderSheet: View {
    let templateId: UUID
    let currentApp: PromptAppTarget?
    let shortcutManager: ShortcutManager
    let onSave: (KeyCombo, ShortcutScope) -> Void
    let onCancel: () -> Void

    @State private var recordedKeyCombo: KeyCombo?
    @State private var errorMessage: String?
    @State private var warningMessage: String?
    @State private var selectedScopeIndex = 0 // 0 = Global, 1 = Current App
    @State private var isRecording = false

    @EnvironmentObject private var languageSettings: LanguageSettings
    private let validator = ShortcutValidator()

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(languageSettings.localized("shortcut_recorder.title"))
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(.primary)

            // Key capture button
            Button(action: startRecording) {
                HStack {
                    if let keyCombo = recordedKeyCombo {
                        Text(keyCombo.displayString)
                            .font(.system(size: 14, weight: .regular, design: .monospaced))
                            .foregroundStyle(.primary)
                    } else {
                        Text(isRecording ? languageSettings.localized("shortcut_recorder.button.press_combination") : languageSettings.localized("shortcut_recorder.button.click_to_record"))
                            .font(.system(size: 14))
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    if recordedKeyCombo != nil && !isRecording {
                        Button(action: clearRecording) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(.tertiary)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(12)
                .frame(height: 44)
                .background(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(isRecording ? AnyShapeStyle(Color.accentColor.opacity(0.12)) : AnyShapeStyle(.quaternary))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(
                            isRecording ? Color.accentColor : Color.primary.opacity(0.1),
                            lineWidth: isRecording ? 1.5 : 1
                        )
                )
            }
            .buttonStyle(.plain)
            .disabled(isRecording)

            // Help text
            Text(isRecording ? languageSettings.localized("shortcut_recorder.help.cancel") : languageSettings.localized("shortcut_recorder.help.modifiers"))
                .font(.caption)
                .foregroundStyle(.tertiary)

            // Scope selector
            VStack(alignment: .leading, spacing: 8) {
                Text(languageSettings.localized("shortcut_recorder.scope.label"))
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.secondary)

                FilterSegmentedControl(
                    options: scopeOptions,
                    selectedIndex: $selectedScopeIndex
                )
            }

            // Error message
            if let error = errorMessage {
                HStack(alignment: .top, spacing: 6) {
                    Image(systemName: "exclamationmark.circle.fill")
                        .font(.system(size: 14))
                    Text(error)
                        .font(.caption)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .foregroundStyle(.red)
                .padding(8)
                .background(
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(Color.red.opacity(0.1))
                )
            }

            // Warning message
            if let warning = warningMessage {
                HStack(alignment: .top, spacing: 6) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 14))
                    Text(warning)
                        .font(.caption)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .foregroundStyle(.orange)
                .padding(8)
                .background(
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(Color.orange.opacity(0.1))
                )
            }

            Spacer()

            HStack(spacing: 12) {
                ActionButton("Cancel", variant: .secondary, action: onCancel)
                Spacer()
                ActionButton("Save", variant: .primary) {
                    if let keyCombo = recordedKeyCombo {
                        let scope: ShortcutScope = {
                            if selectedScopeIndex == 0 {
                                return .global
                            } else if let app = currentApp {
                                return .app(app)
                            } else {
                                return .global
                            }
                        }()
                        onSave(keyCombo, scope)
                    }
                }
                .disabled(recordedKeyCombo == nil || errorMessage != nil)
            }
        }
        .padding(16)
        .frame(width: 480)
        .frame(minHeight: 320, maxHeight: 480)
        .background(
            KeyboardEventHandler(
                isRecording: $isRecording,
                shortcutManager: shortcutManager,
                validator: validator,
                onKeyCaptured: { keyCombo in
                    recordedKeyCombo = keyCombo
                    validateKeyCombo(keyCombo)
                    isRecording = false
                },
                onError: { error in
                    errorMessage = error
                    warningMessage = nil
                    isRecording = false
                },
                onCancel: {
                    isRecording = false
                }
            )
        )
        .onDisappear {
            // Ensure global monitoring resumes when sheet closes
            // This is a safety net in case recording was interrupted
            if isRecording {
                shortcutManager.resumeMonitoring()
            }
        }
    }

    private var scopeOptions: [String] {
        if let app = currentApp {
            return [languageSettings.localized("shortcut_recorder.scope.global"), app.displayName]
        } else {
            return [languageSettings.localized("shortcut_recorder.scope.global")]
        }
    }

    private func startRecording() {
        recordedKeyCombo = nil
        errorMessage = nil
        isRecording = true
    }

    private func clearRecording() {
        recordedKeyCombo = nil
        errorMessage = nil
        warningMessage = nil
        isRecording = false
    }

    private func validateKeyCombo(_ keyCombo: KeyCombo) {
        let result = validator.validate(keyCombo)
        switch result {
        case .success:
            errorMessage = nil
            warningMessage = nil
        case .failure(let validationError):
            errorMessage = validationError.localizedDescription
            warningMessage = nil
        }
    }
}

// MARK: - Keyboard Event Handler

private struct KeyboardEventHandler: NSViewRepresentable {
    @Binding var isRecording: Bool
    let shortcutManager: ShortcutManager
    let validator: ShortcutValidator
    let onKeyCaptured: (KeyCombo) -> Void
    let onError: (String) -> Void
    let onCancel: () -> Void

    func makeNSView(context: Context) -> NSView {
        let view = EventHandlerView()
        view.coordinator = context.coordinator
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        if let handlerView = nsView as? EventHandlerView {
            handlerView.isCapturing = isRecording
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(
            shortcutManager: shortcutManager,
            validator: validator,
            onKeyCaptured: onKeyCaptured,
            onError: onError,
            onCancel: onCancel
        )
    }

    class Coordinator {
        let shortcutManager: ShortcutManager
        let validator: ShortcutValidator
        let onKeyCaptured: (KeyCombo) -> Void
        let onError: (String) -> Void
        let onCancel: () -> Void

        init(
            shortcutManager: ShortcutManager,
            validator: ShortcutValidator,
            onKeyCaptured: @escaping (KeyCombo) -> Void,
            onError: @escaping (String) -> Void,
            onCancel: @escaping () -> Void
        ) {
            self.shortcutManager = shortcutManager
            self.validator = validator
            self.onKeyCaptured = onKeyCaptured
            self.onError = onError
            self.onCancel = onCancel
        }
    }

    class EventHandlerView: NSView {
        weak var coordinator: Coordinator?
        private var hasStartedCapture = false

        var isCapturing = false {
            didSet {
                if isCapturing != oldValue {
                    if isCapturing {
                        startCapture()
                    } else {
                        stopCapture()
                    }
                }
            }
        }

        override var acceptsFirstResponder: Bool { true }
        override func becomeFirstResponder() -> Bool { true }

        private func startCapture() {
            guard !hasStartedCapture else {
                AppLogger.logShortcut("Already capturing, ignoring duplicate start", level: .debug)
                return
            }
            hasStartedCapture = true

            // Pause global monitoring while capturing
            Task { @MainActor in
                coordinator?.shortcutManager.pauseMonitoring()
            }

            // Become first responder to receive key events
            window?.makeFirstResponder(self)

            AppLogger.logShortcut("Started local key capture")
        }

        private func stopCapture() {
            guard hasStartedCapture else {
                AppLogger.logShortcut("Not capturing, ignoring duplicate stop", level: .debug)
                return
            }
            hasStartedCapture = false

            // Resume global monitoring after capturing
            Task { @MainActor in
                coordinator?.shortcutManager.resumeMonitoring()
            }

            AppLogger.logShortcut("Stopped local key capture")
        }

        override func keyDown(with event: NSEvent) {
            guard isCapturing else {
                super.keyDown(with: event)
                return
            }

            AppLogger.logShortcut("Key captured: keyCode=\(event.keyCode)", level: .debug)

            // Handle ESC to cancel (keyCode 53)
            if event.keyCode == 53 {
                AppLogger.logShortcut("ESC pressed, canceling recording", level: .debug)
                DispatchQueue.main.async { [weak self] in
                    self?.coordinator?.onCancel()
                }
                return
            }

            // Try to convert to KeyCombo
            if let keyCombo = event.toKeyCombo() {
                AppLogger.logShortcut("Captured key combo: \(keyCombo.displayString)", level: .debug)

                // Validate the key combo immediately
                if let coordinator = self.coordinator {
                    let validationResult = coordinator.validator.validate(keyCombo)
                    switch validationResult {
                    case .success:
                        AppLogger.logShortcut("Valid shortcut: \(keyCombo.displayString)")
                        // Immediately stop capturing to prevent duplicate captures
                        isCapturing = false
                        DispatchQueue.main.async { [weak self] in
                            self?.coordinator?.onKeyCaptured(keyCombo)
                        }
                    case .failure(let error):
                        AppLogger.logShortcut("Invalid shortcut: \(error.localizedDescription)", level: .warning)
                        DispatchQueue.main.async { [weak self] in
                            self?.coordinator?.onError(error.localizedDescription)
                        }
                    }
                }
            } else {
                AppLogger.logShortcut("Invalid key combo - need modifiers", level: .debug)
                DispatchQueue.main.async { [weak self] in
                    self?.coordinator?.onError(NSLocalizedString("shortcut_recorder.error.need_modifier", comment: ""))
                }
            }
        }

        deinit {
            stopCapture()
        }
    }
}
