//
//  VariableHighlightedTextEditor.swift
//  Promptist
//
//  NSTextView-based editor with syntax highlighting for template variables
//

import SwiftUI
import AppKit

struct VariableHighlightedTextEditor: NSViewRepresentable {
    @Binding var text: String

    func makeNSView(context: Context) -> EditorContainerView {
        let container = EditorContainerView()

        let scrollView = container.scrollView
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.autohidesScrollers = true
        scrollView.borderType = .noBorder
        scrollView.drawsBackground = false

        let textView = HighlightingTextView()
        textView.delegate = context.coordinator
        textView.isEditable = true
        textView.isSelectable = true
        textView.allowsUndo = true
        textView.isRichText = false
        textView.importsGraphics = false
        textView.usesFontPanel = false
        textView.usesRuler = false
        textView.drawsBackground = false
        textView.backgroundColor = .clear
        textView.textContainerInset = NSSize(width: 8, height: 8)
        textView.insertionPointColor = .labelColor

        // Configure text container
        textView.textContainer?.widthTracksTextView = true
        textView.textContainer?.containerSize = NSSize(
            width: CGFloat.greatestFiniteMagnitude,
            height: CGFloat.greatestFiniteMagnitude
        )
        textView.isHorizontallyResizable = false
        textView.isVerticallyResizable = true
        textView.autoresizingMask = [.width]

        // Set default font and text color
        textView.font = NSFont.monospacedSystemFont(ofSize: 13, weight: .regular)
        textView.textColor = .textColor
        textView.typingAttributes = [
            .font: NSFont.monospacedSystemFont(ofSize: 13, weight: .regular),
            .foregroundColor: NSColor.textColor
        ]

        // Set initial text
        textView.string = text
        textView.applyHighlighting()

        scrollView.documentView = textView
        container.textView = textView

        return container
    }

    func updateNSView(_ container: EditorContainerView, context: Context) {
        guard let textView = container.textView else { return }

        // Only update text if it changed externally
        if textView.string != text {
            let selectedRanges = textView.selectedRanges
            textView.string = text
            textView.applyHighlighting()
            textView.selectedRanges = selectedRanges
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, NSTextViewDelegate {
        var parent: VariableHighlightedTextEditor

        init(_ parent: VariableHighlightedTextEditor) {
            self.parent = parent
        }

        func textDidChange(_ notification: Notification) {
            guard let textView = notification.object as? HighlightingTextView else { return }
            parent.text = textView.string
            textView.applyHighlighting()
        }
    }
}

// MARK: - Editor Container View

/// Container view that wraps the scroll view and handles focus ring drawing
class EditorContainerView: NSView {
    let scrollView = NSScrollView()
    weak var textView: HighlightingTextView?

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setupView()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }

    private func setupView() {
        wantsLayer = true
        layer?.cornerRadius = 6
        layer?.masksToBounds = true

        // Set up scroll view
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(scrollView)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])

        // Observe focus changes
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(textViewDidBecomeFirstResponder),
            name: NSTextView.didChangeSelectionNotification,
            object: nil
        )
    }

    @objc private func textViewDidBecomeFirstResponder(_ notification: Notification) {
        needsDisplay = true
    }

    override var acceptsFirstResponder: Bool { false }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        // Draw background - transparent by default
        NSColor.clear.setFill()
        bounds.fill()

        // Draw border
        let borderColor = NSColor.separatorColor.withAlphaComponent(0.3)
        borderColor.setStroke()
        let borderPath = NSBezierPath(roundedRect: bounds.insetBy(dx: 0.5, dy: 0.5), xRadius: 6, yRadius: 6)
        borderPath.lineWidth = 1
        borderPath.stroke()

        // Draw focus ring if text view is first responder
        if let textView = textView, textView.window?.firstResponder === textView {
            NSColor.keyboardFocusIndicatorColor.withAlphaComponent(0.5).setStroke()
            let focusPath = NSBezierPath(roundedRect: bounds.insetBy(dx: 1, dy: 1), xRadius: 5, yRadius: 5)
            focusPath.lineWidth = 2
            focusPath.stroke()
        }
    }

    override func mouseDown(with event: NSEvent) {
        // Forward click to text view to make it first responder
        if let textView = textView {
            window?.makeFirstResponder(textView)
        }
        super.mouseDown(with: event)
    }
}

// MARK: - Highlighting Text View

class HighlightingTextView: NSTextView {

    private let validVariablePattern = try! NSRegularExpression(
        pattern: #"\{\{(selection|clipboard|date|time|datetime|input:[^}]+)\}\}"#,
        options: [.caseInsensitive]
    )

    private let anyVariablePattern = try! NSRegularExpression(
        pattern: #"\{\{[^}]+\}\}"#,
        options: []
    )

    override var acceptsFirstResponder: Bool { true }

    override func becomeFirstResponder() -> Bool {
        let result = super.becomeFirstResponder()
        // Ensure cursor is visible when becoming first responder
        if result {
            needsDisplay = true
        }
        return result
    }

    override func mouseDown(with event: NSEvent) {
        // Ensure we become first responder on click
        window?.makeFirstResponder(self)
        super.mouseDown(with: event)
    }

    func applyHighlighting() {
        guard let textStorage = textStorage else { return }

        let fullRange = NSRange(location: 0, length: textStorage.length)

        // Skip if empty
        guard fullRange.length > 0 else { return }

        let content = string

        // Reset to default styling
        textStorage.beginEditing()

        let defaultFont = NSFont.monospacedSystemFont(ofSize: 13, weight: .regular)
        let textColor = NSColor.textColor  // Use textColor instead of labelColor for better visibility
        textStorage.setAttributes([
            .font: defaultFont,
            .foregroundColor: textColor
        ], range: fullRange)

        // Find all {{...}} patterns
        let allMatches = anyVariablePattern.matches(in: content, options: [], range: fullRange)

        for match in allMatches {
            let matchRange = match.range

            // Check if this is a valid variable
            let validMatches = validVariablePattern.matches(in: content, options: [], range: matchRange)
            let isValid = !validMatches.isEmpty

            if isValid {
                // Apply valid variable styling: monospace font with gray background
                let highlightColor: NSColor
                if NSApp.effectiveAppearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua {
                    highlightColor = NSColor(calibratedWhite: 0.3, alpha: 1.0)
                } else {
                    highlightColor = NSColor(calibratedWhite: 0.92, alpha: 1.0)
                }

                textStorage.addAttributes([
                    .font: NSFont.monospacedSystemFont(ofSize: 13, weight: .medium),
                    .backgroundColor: highlightColor,
                    .foregroundColor: textColor
                ], range: matchRange)
            }
            // Invalid variables keep default styling (no special highlighting)
        }

        textStorage.endEditing()
    }

    override func didChangeText() {
        super.didChangeText()
        // Highlighting is applied by coordinator after text change
    }
}

// MARK: - Preview

#Preview {
    @Previewable @State var text = """
    Hello {{selection}}!

    Today is {{date}} at {{time}}.

    {{clipboard}} will be inserted here.

    User input: {{input:What is your name?}}

    Invalid: {{invalid_variable}}
    """

    return VariableHighlightedTextEditor(text: $text)
        .frame(width: 400, height: 300)
        .background(Color(nsColor: .textBackgroundColor))
}
