//
//  PromptExecutionService.swift
//  Promptist
//
//  Orchestrates prompt execution with variable resolution
//

import AppKit
import Combine
import Foundation

@MainActor
final class PromptExecutionService: ObservableObject {
    // Required for ObservableObject conformance
    let objectWillChange = ObservableObjectPublisher()
    private let selectionGrabber: SelectionGrabber
    private let clipboardHistory: ClipboardHistoryManager
    private let resolver: TemplateVariableResolver

    init(
        selectionGrabber: SelectionGrabber,
        clipboardHistory: ClipboardHistoryManager,
        resolver: TemplateVariableResolver? = nil
    ) {
        self.selectionGrabber = selectionGrabber
        self.clipboardHistory = clipboardHistory
        self.resolver = resolver ?? TemplateVariableResolver()
    }

    // MARK: - Execution Result

    enum ExecutionResult {
        case directCopy(String)
        case needsInput(ParsedExecution)
    }

    struct ParsedExecution {
        let prompt: PromptTemplate
        let parseResult: TemplateParseResult
        let initialContext: VariableResolutionContext
    }

    // MARK: - Main Execution Flow

    /// Prepare a prompt for execution
    /// Returns .directCopy if no interactive variables needed, or .needsInput if dialog required
    func prepareExecution(for prompt: PromptTemplate) async -> ExecutionResult {
        let parseResult = TemplateVariableParser.parse(prompt.content)

        // No variables - direct copy
        guard !parseResult.isEmpty else {
            return .directCopy(prompt.content)
        }

        // Build initial context with auto-resolved values
        var context = VariableResolutionContext()

        // Grab selection if needed
        let needsSelection = parseResult.variables.contains {
            if case .selection = $0.type { return true }
            return false
        }
        if needsSelection {
            context.selectedText = await selectionGrabber.grabSelection()
        }

        // Check if interactive input is needed
        if parseResult.hasInteractiveVariables {
            return .needsInput(ParsedExecution(
                prompt: prompt,
                parseResult: parseResult,
                initialContext: context
            ))
        }

        // All variables can be auto-resolved
        let resolved = resolver.resolveAll(
            template: prompt.content,
            variables: parseResult.variables,
            context: context
        )
        return .directCopy(resolved)
    }

    /// Complete execution with user-provided context (from dialog)
    func completeExecution(
        parsed: ParsedExecution,
        userContext: VariableResolutionContext
    ) -> String {
        let mergedContext = parsed.initialContext.merging(userContext)
        return resolver.resolveAll(
            template: parsed.prompt.content,
            variables: parsed.parseResult.variables,
            context: mergedContext
        )
    }

    /// Copy text to clipboard
    func copyToClipboard(_ text: String) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
    }

    // MARK: - Accessors

    var currentClipboardHistory: [ClipboardEntry] {
        clipboardHistory.history
    }
}
