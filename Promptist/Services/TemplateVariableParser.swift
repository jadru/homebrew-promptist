//
//  TemplateVariableParser.swift
//  Promptist
//
//  Parses {{...}} template variables from prompt content
//

import Foundation

struct TemplateVariableParser {

    // MARK: - Public API

    static func parse(_ content: String) -> TemplateParseResult {
        let variables = extractVariables(from: content)

        let hasInteractiveVariables = variables.contains { $0.type.isInteractive }
        let hasClipboardVariable = variables.contains {
            if case .clipboard = $0.type { return true }
            return false
        }

        var seenQuestions = Set<String>()
        var uniqueInputQuestions: [String] = []
        for variable in variables {
            if case .input(let question) = variable.type {
                if !seenQuestions.contains(question) {
                    seenQuestions.insert(question)
                    uniqueInputQuestions.append(question)
                }
            }
        }

        return TemplateParseResult(
            variables: variables,
            hasInteractiveVariables: hasInteractiveVariables,
            hasClipboardVariable: hasClipboardVariable,
            uniqueInputQuestions: uniqueInputQuestions
        )
    }

    static func extractVariableRanges(from content: String) -> [(range: Range<String.Index>, type: TemplateVariableType)] {
        let variables = extractVariables(from: content)
        return variables.map { ($0.range, $0.type) }
    }

    // MARK: - Private

    private static let variablePattern = try! NSRegularExpression(
        pattern: #"\{\{([^}]+)\}\}"#,
        options: []
    )

    private static func extractVariables(from content: String) -> [TemplateVariable] {
        let nsRange = NSRange(content.startIndex..., in: content)
        let matches = variablePattern.matches(in: content, options: [], range: nsRange)

        return matches.compactMap { match -> TemplateVariable? in
            guard let matchRange = Range(match.range, in: content),
                  let captureRange = Range(match.range(at: 1), in: content) else {
                return nil
            }

            let rawMatch = String(content[matchRange])
            let innerContent = String(content[captureRange]).trimmingCharacters(in: .whitespaces)
            let type = parseVariableType(innerContent)

            return TemplateVariable(
                rawMatch: rawMatch,
                type: type,
                range: matchRange
            )
        }
    }

    private static func parseVariableType(_ inner: String) -> TemplateVariableType {
        let lowercased = inner.lowercased()

        switch lowercased {
        case "selection":
            return .selection
        case "clipboard":
            return .clipboard
        case "date":
            return .date
        case "time":
            return .time
        case "datetime":
            return .datetime
        default:
            if lowercased.hasPrefix("input:") {
                let question = String(inner.dropFirst(6)).trimmingCharacters(in: .whitespaces)
                if !question.isEmpty {
                    return .input(question: question)
                }
            }
            return .unknown(raw: inner)
        }
    }
}
