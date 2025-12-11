import Foundation
import AppKit
import Combine

// MARK: - Shortcut Manager

@MainActor
final class ShortcutManager: ObservableObject {
    @Published private(set) var registeredShortcuts: [TemplateShortcut] = []
    @Published private(set) var isMonitoring: Bool = false

    var onShortcutTriggered: ((UUID) -> Void)?

    private let store: ShortcutStore
    private let appContext: AppContextService
    private var eventMonitor: Any?
    private var isPaused: Bool = false

    init(store: ShortcutStore, appContext: AppContextService) {
        self.store = store
        self.appContext = appContext

        // Load shortcuts from storage
        self.registeredShortcuts = store.loadShortcuts()

        // Start monitoring if we have shortcuts
        if !registeredShortcuts.isEmpty {
            startMonitoring()
        }
    }

    deinit {
        // Stop monitoring - must be done synchronously in deinit
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
            eventMonitor = nil
        }
    }

    func registerShortcut(_ shortcut: TemplateShortcut) {
        registeredShortcuts.append(shortcut)
        saveShortcuts()
        refreshMonitoring()
    }

    func unregisterShortcut(id: UUID) {
        registeredShortcuts.removeAll { $0.id == id }
        saveShortcuts()
        refreshMonitoring()
    }

    func updateShortcut(_ shortcut: TemplateShortcut) {
        if let index = registeredShortcuts.firstIndex(where: { $0.id == shortcut.id }) {
            registeredShortcuts[index] = shortcut
            saveShortcuts()
            refreshMonitoring()
        }
    }

    func refreshAll(with shortcuts: [TemplateShortcut]) {
        registeredShortcuts = shortcuts
        saveShortcuts()
        refreshMonitoring()
    }

    // Temporarily pause monitoring (e.g., when recording shortcuts)
    func pauseMonitoring() {
        guard !isPaused else {
            print("⚠️ Already paused, ignoring duplicate pause")
            return
        }
        isPaused = true
        stopMonitoring()
        print("⏸️ Shortcut monitoring paused")
    }

    // Resume monitoring after pause
    func resumeMonitoring() {
        guard isPaused else {
            print("⚠️ Not paused, ignoring duplicate resume")
            return
        }
        isPaused = false
        if !registeredShortcuts.isEmpty {
            startMonitoring()
            print("▶️ Shortcut monitoring resumed")
        } else {
            print("⚠️ No shortcuts to monitor, skipping resume")
        }
    }

    private func saveShortcuts() {
        store.saveShortcuts(registeredShortcuts)
    }

    private func refreshMonitoring() {
        guard !isPaused else { return }
        stopMonitoring()
        if !registeredShortcuts.isEmpty {
            startMonitoring()
        }
    }

    private func startMonitoring() {
        guard eventMonitor == nil else {
            print("⚠️ Event monitor already active")
            return
        }

        print("🎧 Starting global keyboard event monitoring...")
        print("📝 Monitoring \(registeredShortcuts.count) shortcuts")

        eventMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            Task { @MainActor [weak self] in
                self?.handleKeyEvent(event)
            }
        }

        if eventMonitor != nil {
            isMonitoring = true
            print("✅ Global keyboard monitoring active")
        } else {
            print("❌ Failed to start global keyboard monitoring - check Accessibility permissions!")
        }
    }

    private func stopMonitoring() {
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
            eventMonitor = nil
            isMonitoring = false
            print("⏹️ Global keyboard monitoring stopped")
        }
    }

    private func handleKeyEvent(_ event: NSEvent) {
        guard let keyCombo = event.toKeyCombo() else { return }

        print("⌨️ Key pressed: \(keyCombo.displayString)")

        // Get current app context
        let currentAppFilter = PromptAppFilter(
            trackedApp: appContext.currentTrackedApp,
            bundleIdentifier: appContext.frontmostBundleIdentifier,
            displayName: appContext.frontmostAppName
        )

        print("🎯 Current app: \(currentAppFilter.displayName ?? "unknown") (\(currentAppFilter.bundleIdentifier ?? "no bundle"))")

        // CRITICAL: Don't execute shortcuts inside our own app
        // Global monitor only captures events from OTHER apps
        if let bundleId = currentAppFilter.bundleIdentifier,
           bundleId.contains("Promptist") {
            print("🚫 Ignoring shortcut in own app - shortcuts only work in external apps")
            return
        }

        // Find matching shortcuts
        let matches = registeredShortcuts.filter { shortcut in
            guard shortcut.isEnabled else { return false }
            guard shortcut.keyCombo.conflicts(with: keyCombo) else { return false }

            switch shortcut.scope {
            case .global:
                return true
            case .app(let target):
                return target.matches(currentAppFilter)
            }
        }

        print("🔍 Found \(matches.count) matching shortcuts")

        // Priority: app-specific first, then global
        let appSpecific = matches.first { shortcut in
            if case .app = shortcut.scope { return true }
            return false
        }

        let selected = appSpecific ?? matches.first

        if let shortcut = selected {
            print("✨ Executing shortcut for template: \(shortcut.templateId)")
            onShortcutTriggered?(shortcut.templateId)
        } else {
            print("❌ No matching shortcut found")
        }
    }
}

// MARK: - NSEvent Extension

extension NSEvent {
    func toKeyCombo() -> KeyCombo? {
        guard let chars = charactersIgnoringModifiers,
              let firstChar = chars.first else {
            return nil
        }

        var mods = ModifierKey()
        if modifierFlags.contains(.command) { mods.insert(.command) }
        if modifierFlags.contains(.option) { mods.insert(.option) }
        if modifierFlags.contains(.control) { mods.insert(.control) }
        if modifierFlags.contains(.shift) { mods.insert(.shift) }

        // Require at least one modifier for global shortcuts
        guard !mods.isEmpty else { return nil }

        return KeyCombo(modifiers: mods, key: String(firstChar))
    }
}
