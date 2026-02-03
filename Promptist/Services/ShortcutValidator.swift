import Foundation
import AppKit

// MARK: - Shortcut Validation Result

enum ShortcutValidationError: Error {
    case systemReserved(String)           // macOS 시스템 예약 단축키
    case tooSimple(String)                // 너무 단순한 조합
    case noModifiers(String)              // 모디파이어 키 없음
    case invalidKey(String)               // 유효하지 않은 키
    case accessibilityRequired(String)    // Accessibility 권한 필요

    var localizedDescription: String {
        switch self {
        case .systemReserved(let message):
            return message
        case .tooSimple(let message):
            return message
        case .noModifiers(let message):
            return message
        case .invalidKey(let message):
            return message
        case .accessibilityRequired(let message):
            return message
        }
    }
}

// MARK: - Shortcut Validator

final class ShortcutValidator {

    // System-reserved shortcuts that cannot be overridden
    private static let systemReservedShortcuts: Set<String> = [
        // Spotlight
        "⌘ ", // Spotlight search

        // Mission Control
        "⌃↑", "⌃↓", "⌃←", "⌃→",

        // Screenshot
        "⌘⇧3", "⌘⇧4", "⌘⇧5",

        // System
        "⌘⌥⎋", // Force Quit
        "⌃⌘Q", // Lock Screen
        "⌃⌘⏏", // Sleep/Shutdown

        // Accessibility
        "⌘⌥F5", // Accessibility Options

        // Input
        "⌃ ", // Switch input source (Control+Space)
        "⌘ ", // Spotlight (Command+Space)
    ]

    // Common system shortcuts that are strongly discouraged
    private static let discouragedShortcuts: Set<String> = [
        "⌘Q", "⌘W", "⌘N", "⌘T", // Window management
        "⌘C", "⌘V", "⌘X", "⌘A", "⌘Z", "⌘⇧Z", // Editing
        "⌘S", "⌘O", "⌘P", // File operations
        "⌘,", // Preferences
        "⌘H", "⌘⌥H", "⌘M", // Hide/Minimize
        "⌘Tab", "⌘⇧Tab", "⌘`", // App switching
    ]

    // Keys that should not be used alone (even with modifiers)
    private static let problematicKeys: Set<UInt16> = [
        53,  // ESC
        36,  // Return
        48,  // Tab
        51,  // Delete
        117, // Forward Delete
        122, 120, 99, 118, 96, 97, 98, 100, 101, 109, 103, 111, // F-keys (F1-F12)
    ]

    func validate(_ keyCombo: KeyCombo) -> Result<Void, ShortcutValidationError> {
        // 1. Check if modifiers are present
        if keyCombo.modifiers.isEmpty {
            return .failure(.noModifiers("Shortcut must include at least one modifier key (⌘, ⌥, ⌃, or ⇧)"))
        }

        // 2. Check for system-reserved shortcuts
        let displayString = keyCombo.displayString
        if Self.systemReservedShortcuts.contains(displayString) {
            return .failure(.systemReserved("This shortcut is reserved by macOS and cannot be used"))
        }

        // 3. Block discouraged shortcuts that conflict with standard app shortcuts
        if Self.discouragedShortcuts.contains(displayString) {
            return .failure(.systemReserved(
                "\(displayString) is a common system/app shortcut and will conflict with most applications."
            ))
        }

        // 4. Check if using only Shift (too simple)
        if keyCombo.modifiers == .shift && keyCombo.key.count == 1 {
            return .failure(.tooSimple("Shift-only shortcuts are not recommended. Add ⌘, ⌥, or ⌃"))
        }

        // 5. Check for special keys that shouldn't be used
        // We can't easily check keyCode here since we only have the character,
        // but we can check for known problematic characters
        let problematicChars = Set(["⎋", "\r", "\n", "\t", "⌫", "⌦"])
        if problematicChars.contains(keyCombo.key) {
            return .failure(.invalidKey("This key cannot be used for shortcuts"))
        }

        // 6. Check Accessibility permissions
        if !checkAccessibilityPermissions() {
            return .failure(.accessibilityRequired(
                "Accessibility permissions required.\n\n" +
                "Open System Settings → Privacy & Security → Accessibility\n" +
                "and enable 'Promptist'."
            ))
        }

        return .success(())
    }

    // Test if we can actually register global shortcuts
    func canRegisterGlobalShortcuts() -> Bool {
        return checkAccessibilityPermissions()
    }

    func checkAccessibilityPermissions() -> Bool {
        // Check without showing system prompt (we'll use our custom UI)
        let options: NSDictionary = [kAXTrustedCheckOptionPrompt.takeRetainedValue() as String: false]
        let accessEnabled = AXIsProcessTrustedWithOptions(options)
        return accessEnabled
    }

    // Get a user-friendly explanation of why a shortcut might not work
    func explainIssue(for keyCombo: KeyCombo) -> String? {
        switch validate(keyCombo) {
        case .success:
            return nil
        case .failure(let error):
            return error.localizedDescription
        }
    }
}

// MARK: - KeyCombo Extension

extension KeyCombo {
    /// Check if this key combo is likely to work as a global shortcut
    var isValidGlobalShortcut: Bool {
        let validator = ShortcutValidator()
        switch validator.validate(self) {
        case .success:
            return true
        case .failure:
            return false
        }
    }

    /// Get validation error if any
    var validationError: String? {
        let validator = ShortcutValidator()
        return validator.explainIssue(for: self)
    }
}
