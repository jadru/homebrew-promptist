//
//  ClipboardHistoryManager.swift
//  Promptist
//
//  Tracks clipboard history for the {{clipboard}} variable picker
//

import AppKit
import Combine

@MainActor
final class ClipboardHistoryManager: ObservableObject {
    @Published private(set) var history: [ClipboardEntry] = []

    private let maxHistorySize: Int = 10
    private var lastChangeCount: Int = 0
    private var pollTimer: Timer?

    init() {
        // Initialize with current clipboard content
        lastChangeCount = NSPasteboard.general.changeCount
        if let currentContent = NSPasteboard.general.string(forType: .string),
           !currentContent.isEmpty {
            history.append(ClipboardEntry(content: currentContent))
        }
    }

    deinit {
        pollTimer?.invalidate()
    }

    // MARK: - Monitoring

    func startMonitoring(interval: TimeInterval = 0.5) {
        stopMonitoring()

        pollTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.checkForChanges()
            }
        }
    }

    func stopMonitoring() {
        pollTimer?.invalidate()
        pollTimer = nil
    }

    // MARK: - History Management

    func addEntry(_ content: String) {
        guard !content.isEmpty else { return }

        // Remove duplicate if exists
        history.removeAll { $0.content == content }

        // Add new entry at the beginning
        let entry = ClipboardEntry(content: content)
        history.insert(entry, at: 0)

        // Trim to max size
        if history.count > maxHistorySize {
            history = Array(history.prefix(maxHistorySize))
        }
    }

    func clearHistory() {
        history.removeAll()
    }

    // MARK: - Private

    private func checkForChanges() {
        let currentChangeCount = NSPasteboard.general.changeCount

        guard currentChangeCount != lastChangeCount else { return }
        lastChangeCount = currentChangeCount

        guard let content = NSPasteboard.general.string(forType: .string),
              !content.isEmpty else { return }

        addEntry(content)
    }
}
