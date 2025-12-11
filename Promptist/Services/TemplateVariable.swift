//
//  TemplateVariable.swift
//  Promptist
//
//  Template variable types and parsing result structures
//

import Foundation

// MARK: - Variable Type

enum TemplateVariableType: Equatable, Hashable {
    case selection
    case clipboard
    case date
    case time
    case datetime
    case input(question: String)
    case unknown(raw: String)

    var isInteractive: Bool {
        switch self {
        case .clipboard, .input:
            return true
        default:
            return false
        }
    }

    var isValid: Bool {
        switch self {
        case .unknown:
            return false
        default:
            return true
        }
    }
}

// MARK: - Variable

struct TemplateVariable: Identifiable, Hashable {
    let id: UUID
    let rawMatch: String
    let type: TemplateVariableType
    let range: Range<String.Index>

    init(rawMatch: String, type: TemplateVariableType, range: Range<String.Index>) {
        self.id = UUID()
        self.rawMatch = rawMatch
        self.type = type
        self.range = range
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: TemplateVariable, rhs: TemplateVariable) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Parse Result

struct TemplateParseResult {
    let variables: [TemplateVariable]
    let hasInteractiveVariables: Bool
    let hasClipboardVariable: Bool
    let uniqueInputQuestions: [String]

    var isEmpty: Bool {
        variables.isEmpty
    }

    static let empty = TemplateParseResult(
        variables: [],
        hasInteractiveVariables: false,
        hasClipboardVariable: false,
        uniqueInputQuestions: []
    )
}

// MARK: - Resolution Context

struct VariableResolutionContext {
    var selectedText: String?
    var clipboardSelection: String?
    var inputResponses: [String: String]

    init(
        selectedText: String? = nil,
        clipboardSelection: String? = nil,
        inputResponses: [String: String] = [:]
    ) {
        self.selectedText = selectedText
        self.clipboardSelection = clipboardSelection
        self.inputResponses = inputResponses
    }

    func merging(_ other: VariableResolutionContext) -> VariableResolutionContext {
        VariableResolutionContext(
            selectedText: other.selectedText ?? self.selectedText,
            clipboardSelection: other.clipboardSelection ?? self.clipboardSelection,
            inputResponses: self.inputResponses.merging(other.inputResponses) { _, new in new }
        )
    }
}

// MARK: - Clipboard Entry

struct ClipboardEntry: Identifiable, Hashable {
    let id: UUID
    let content: String
    let timestamp: Date

    var preview: String {
        let trimmed = content.trimmingCharacters(in: .whitespacesAndNewlines)
        let singleLine = trimmed.replacingOccurrences(of: "\n", with: " ")
        if singleLine.count > 80 {
            return String(singleLine.prefix(77)) + "..."
        }
        return singleLine
    }

    init(content: String, timestamp: Date = Date()) {
        self.id = UUID()
        self.content = content
        self.timestamp = timestamp
    }
}
