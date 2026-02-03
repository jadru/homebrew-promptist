//
//  ServiceContainer.swift
//  Promptist
//
//  Centralized dependency injection container for managing app services.
//

import SwiftUI
import Combine

/// Centralized container managing all app services and their dependencies.
/// This provides a single source of truth for service instantiation and
/// ensures proper dependency injection throughout the app.
@MainActor
final class ServiceContainer: ObservableObject {
    // MARK: - Singleton

    static let shared = ServiceContainer()

    // MARK: - Core Services

    let repository: PromptTemplateRepository
    let shortcutStore: ShortcutStore

    // MARK: - Observable Services

    @Published private(set) var appContext: AppContextService
    @Published private(set) var languageSettings: LanguageSettings
    @Published private(set) var onboardingManager: OnboardingManager
    @Published private(set) var accessibilityManager: AccessibilityPermissionManager
    @Published private(set) var clipboardHistory: ClipboardHistoryManager
    @Published private(set) var executionService: PromptExecutionService
    @Published private(set) var shortcutManager: ShortcutManager
    @Published private(set) var promptListViewModel: PromptListViewModel
    @Published private(set) var windowObserver: WindowObserver

    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialization

    private init() {
        AppLogger.log("Initializing ServiceContainer", level: .info)

        // 1. Initialize core data services (no dependencies)
        let repo = FilePromptTemplateRepository()
        self.repository = repo
        self.shortcutStore = FileShortcutStore()

        // 2. Initialize settings services
        self.languageSettings = LanguageSettings()
        self.onboardingManager = OnboardingManager()

        // 3. Initialize app context (tracks frontmost app)
        let context = AppContextService()
        self.appContext = context

        // 4. Initialize accessibility and clipboard services
        let accessibility = AccessibilityPermissionManager()
        self.accessibilityManager = accessibility

        let clipboard = ClipboardHistoryManager()
        self.clipboardHistory = clipboard

        // 5. Initialize execution service (depends on accessibility, clipboard)
        let grabber = SelectionGrabber(permissionManager: accessibility)
        self.executionService = PromptExecutionService(
            selectionGrabber: grabber,
            clipboardHistory: clipboard
        )

        // 6. Initialize shortcut manager (depends on store, context)
        guard let fileStore = shortcutStore as? FileShortcutStore else {
            fatalError("ServiceContainer requires FileShortcutStore implementation")
        }
        self.shortcutManager = ShortcutManager(
            store: fileStore,
            appContext: context
        )

        // 7. Initialize view models (depends on repository)
        self.promptListViewModel = PromptListViewModel(repository: repo)

        // 8. Initialize window observer
        self.windowObserver = WindowObserver()

        // Start services
        startServices()

        AppLogger.log("ServiceContainer initialized successfully", level: .info)
    }

    // MARK: - Service Lifecycle

    private func startServices() {
        // Start clipboard monitoring
        clipboardHistory.startMonitoring()

        // Configure shortcut callback
        configureShortcutCallback()

        // Watch for accessibility permission changes to restart shortcut monitoring
        observeAccessibilityPermission()

        // Forward onboardingManager changes so PromptistApp re-evaluates its views
        onboardingManager.objectWillChange
            .sink { [weak self] _ in self?.objectWillChange.send() }
            .store(in: &cancellables)
    }

    private func observeAccessibilityPermission() {
        accessibilityManager.$hasPermission
            .removeDuplicates()
            .filter { $0 == true }
            .sink { [weak self] _ in
                guard let self else { return }
                AppLogger.logShortcut("Accessibility permission granted — ensuring shortcut monitoring is active")
                self.shortcutManager.ensureMonitoring()
            }
            .store(in: &cancellables)

        // Start polling so we detect when the user grants permission in System Settings
        accessibilityManager.startPollingForPermission(interval: 2.0)
    }

    private func configureShortcutCallback() {
        let viewModel = promptListViewModel
        let execution = executionService

        shortcutManager.onShortcutTriggered = { templateId in
            Task { @MainActor in
                guard let template = viewModel.allTemplates.first(where: { $0.id == templateId }) else {
                    AppLogger.logShortcut("Template not found for shortcut: \(templateId)", level: .warning)
                    return
                }

                let result = await execution.prepareExecution(for: template)

                switch result {
                case .directCopy(let content):
                    execution.copyToClipboard(content)
                    AppLogger.logShortcut("Shortcut triggered: \(template.title)")

                case .needsInput:
                    // For shortcuts with interactive variables, copy raw content
                    execution.copyToClipboard(template.content)
                    AppLogger.logShortcut("Shortcut triggered (has variables): \(template.title)", level: .warning)
                }
            }
        }
    }

    // MARK: - App Context Sync

    /// Syncs the current app context with the prompt list view model
    func syncAppContext() {
        promptListViewModel.updateCurrentApp(
            trackedApp: appContext.currentTrackedApp,
            bundleIdentifier: appContext.frontmostBundleIdentifier,
            appDisplayName: appContext.frontmostAppName
        )
    }
}

// MARK: - Environment Key

private struct ServiceContainerKey: EnvironmentKey {
    static let defaultValue: ServiceContainer = .shared
}

extension EnvironmentValues {
    var serviceContainer: ServiceContainer {
        get { self[ServiceContainerKey.self] }
        set { self[ServiceContainerKey.self] = newValue }
    }
}
