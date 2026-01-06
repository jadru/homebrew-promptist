//
//  SelectionGrabber.swift
//  Promptist
//
//  Grabs selected text from the frontmost application using Accessibility API
//

import AppKit
import ApplicationServices

@MainActor
final class SelectionGrabber {
    private let permissionManager: AccessibilityPermissionManager

    init(permissionManager: AccessibilityPermissionManager) {
        self.permissionManager = permissionManager
    }

    /// Grab the currently selected text from the frontmost application
    /// Returns nil if no selection, no permission, or unable to access
    func grabSelection() async -> String? {
        guard permissionManager.hasPermission else {
            return nil
        }

        guard let frontApp = NSWorkspace.shared.frontmostApplication else {
            return nil
        }

        let pid = frontApp.processIdentifier
        let appElement = AXUIElementCreateApplication(pid)

        // Get the focused UI element
        var focusedElement: CFTypeRef?
        let focusResult = AXUIElementCopyAttributeValue(
            appElement,
            kAXFocusedUIElementAttribute as CFString,
            &focusedElement
        )

        guard focusResult == .success,
              let focused = focusedElement else {
            AppLogger.logAccessibility("Failed to get focused element: \(focusResult.rawValue)", level: .debug)
            return nil
        }

        // AXUIElement is a CFTypeRef, so we can cast it directly
        let axElement = focused as! AXUIElement

        // Get the selected text from the focused element
        var selectedText: CFTypeRef?
        let textResult = AXUIElementCopyAttributeValue(
            axElement,
            kAXSelectedTextAttribute as CFString,
            &selectedText
        )

        guard textResult == .success,
              let text = selectedText as? String,
              !text.isEmpty else {
            return nil
        }

        return text
    }

    /// Check if we have permission to grab selection
    var hasPermission: Bool {
        permissionManager.hasPermission
    }
}
