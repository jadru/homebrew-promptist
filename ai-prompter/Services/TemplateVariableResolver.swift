//
//  TemplateVariableResolver.swift
//  Promptist
//
//  Resolves template variables to their actual values and substitutes them
//

import Foundation

@MainActor
final class TemplateVariableResolver {

    // MARK: - Date Formatters

    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()

    private let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter
    }()

    private let dateTimeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        return formatter
    }()

    // MARK: - Resolution

    /// Resolve all variables in the template and return the final string
    func resolveAll(
        template: String,
        variables: [TemplateVariable],
        context: VariableResolutionContext
    ) -> String {
        var result = template
        let now = Date()

        // Process variables in reverse order to avoid index shifting
        let sortedVariables = variables.sorted { $0.range.lowerBound > $1.range.lowerBound }

        for variable in sortedVariables {
            let replacement = resolveVariable(variable.type, context: context, now: now)
            result.replaceSubrange(variable.range, with: replacement)
        }

        return result
    }

    /// Resolve a single variable type to its value
    func resolveVariable(
        _ type: TemplateVariableType,
        context: VariableResolutionContext,
        now: Date = Date()
    ) -> String {
        switch type {
        case .selection:
            return context.selectedText ?? ""

        case .clipboard:
            return context.clipboardSelection ?? ""

        case .date:
            return dateFormatter.string(from: now)

        case .time:
            return timeFormatter.string(from: now)

        case .datetime:
            return dateTimeFormatter.string(from: now)

        case .input(let question):
            return context.inputResponses[question] ?? ""

        case .unknown:
            return ""
        }
    }
}
