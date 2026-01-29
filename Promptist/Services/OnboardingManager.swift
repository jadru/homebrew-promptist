import Foundation
import SwiftUI
import Combine

// MARK: - Onboarding Manager

@MainActor
final class OnboardingManager: ObservableObject {

    // MARK: - Types

    enum OnboardingStep: Int, CaseIterable {
        case welcome = 0
        case features = 1
        case permission = 2
        case complete = 3

        var next: OnboardingStep? {
            OnboardingStep(rawValue: rawValue + 1)
        }

        var previous: OnboardingStep? {
            OnboardingStep(rawValue: rawValue - 1)
        }
    }

    // MARK: - Published Properties

    @Published var currentStep: OnboardingStep = .welcome
    @Published var isOnboardingWindowOpen: Bool = false

    // MARK: - Callbacks

    /// Called when onboarding is completed - use to open launcher
    var onOnboardingCompleted: (() -> Void)?

    // MARK: - Dependencies

    private let permissionManager: AccessibilityPermissionManager
    private let userDefaults: UserDefaults
    private var cancellables = Set<AnyCancellable>()

    // MARK: - UserDefaults Keys

    private enum Keys {
        static let hasCompletedOnboarding = "OnboardingManager.hasCompletedOnboarding"
    }

    // MARK: - Computed Properties

    var hasCompletedOnboarding: Bool {
        get { userDefaults.bool(forKey: Keys.hasCompletedOnboarding) }
        set {
            userDefaults.set(newValue, forKey: Keys.hasCompletedOnboarding)
            objectWillChange.send()
        }
    }

    /// Returns true if onboarding should be shown (only for first-time users)
    var shouldShowOnboarding: Bool {
        !hasCompletedOnboarding
    }

    /// Returns true if permission is not granted (for showing reminder, not blocking)
    var needsPermission: Bool {
        !permissionManager.hasPermission
    }

    var totalSteps: Int {
        OnboardingStep.allCases.count
    }

    var progress: Double {
        Double(currentStep.rawValue) / Double(totalSteps - 1)
    }

    // MARK: - Initialization

    init(permissionManager: AccessibilityPermissionManager? = nil,
         userDefaults: UserDefaults = .standard) {
        self.permissionManager = permissionManager ?? AccessibilityPermissionManager()
        self.userDefaults = userDefaults

        setupPermissionObserver()
    }

    private func setupPermissionObserver() {
        // No longer auto-jump to permission step - users can use the app without permission

        // Listen for permission changes
        permissionManager.$hasPermission
            .receive(on: DispatchQueue.main)
            .sink { [weak self] hasPermission in
                guard let self = self else { return }
                if hasPermission && self.currentStep == .permission {
                    // Auto-advance when permission is granted
                    self.nextStep()
                }
            }
            .store(in: &cancellables)
    }

    // MARK: - Navigation

    func nextStep() {
        guard let next = currentStep.next else {
            // Complete onboarding
            completeOnboarding()
            return
        }

        // Skip permission step if already granted
        if next == .permission && permissionManager.hasPermission {
            currentStep = .complete
            return
        }

        withAnimation(.easeInOut(duration: 0.3)) {
            currentStep = next
        }
    }

    func previousStep() {
        guard let previous = currentStep.previous else { return }

        withAnimation(.easeInOut(duration: 0.3)) {
            currentStep = previous
        }
    }

    func goToStep(_ step: OnboardingStep) {
        withAnimation(.easeInOut(duration: 0.3)) {
            currentStep = step
        }
    }

    // MARK: - Completion

    func completeOnboarding() {
        hasCompletedOnboarding = true
        isOnboardingWindowOpen = false
        onOnboardingCompleted?()
    }

    // MARK: - Reset (for testing)

    func resetOnboarding() {
        hasCompletedOnboarding = false
        currentStep = .welcome
    }

    // MARK: - Permission Access

    var permissionManagerInstance: AccessibilityPermissionManager {
        permissionManager
    }
}
