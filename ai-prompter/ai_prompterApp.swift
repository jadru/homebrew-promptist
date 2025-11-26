//
//  PromptistApp.swift
//  Promptist
//
//  Created by Younggun Park on 11/25/25.
//

import SwiftUI
import AppKit

// <CHORUS_TAG>main</CHORUS_TAG>
@main
struct PromptistApp: App {
    @StateObject private var appContext = AppContextService()
    @StateObject private var languageSettings = LanguageSettings()
    @StateObject private var promptListViewModel: PromptListViewModel
    @StateObject private var shortcutManager: ShortcutManager

    init() {
        if let appIcon = NSImage(named: "AppIcon") {
            NSApplication.shared.applicationIconImage = appIcon
        }

        let repository = FilePromptTemplateRepository()
        let viewModel = PromptListViewModel(repository: repository)
        _promptListViewModel = StateObject(wrappedValue: viewModel)

        // Create shared AppContext instance
        let sharedContext = AppContextService()
        _appContext = StateObject(wrappedValue: sharedContext)

        // Initialize shortcut infrastructure with SHARED context
        let store = FileShortcutStore()
        let manager = ShortcutManager(store: store, appContext: sharedContext)
        _shortcutManager = StateObject(wrappedValue: manager)

        // Set execution callback
        manager.onShortcutTriggered = { templateId in
            Task { @MainActor in
                if let template = viewModel.allTemplates.first(where: { $0.id == templateId }) {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(template.content, forType: .string)

                    // Show notification
                    print("✅ Shortcut triggered: \(template.title)")
                    print("📋 Copied to clipboard: \(template.content.prefix(50))...")
                }
            }
        }
    }

    var body: some Scene {
        MenuBarExtra {
            PromptLauncherView()
                .environmentObject(appContext)
                .environmentObject(languageSettings)
                .environment(\.locale, languageSettings.locale)
        } label: {
            MenuBarIconView(count: overlayCount)
                .onAppear(perform: syncAppContext)
                .onReceive(appContext.$currentTrackedApp) { _ in
                    syncAppContext()
                }
                .onReceive(appContext.$frontmostBundleIdentifier) { _ in
                    syncAppContext()
                }
                .onReceive(appContext.$frontmostAppName) { _ in
                    syncAppContext()
                }
        }
        .menuBarExtraStyle(.window)

        Window("prompt_manager.window_title", id: "manager") {
            PromptManagerRootView(
                promptListViewModel: promptListViewModel,
                shortcutManager: shortcutManager
            )
            .environmentObject(appContext)
            .environmentObject(languageSettings)
            .environment(\.locale, languageSettings.locale)
        }
        .windowResizability(.contentSize)

        Settings {
            SettingsView()
                .environmentObject(languageSettings)
                .environment(\.locale, languageSettings.locale)
        }
    }

    private var overlayCount: Int {
        promptListViewModel.linkedTemplatesForCurrentApp.count
    }

    private func syncAppContext() {
        promptListViewModel.updateCurrentApp(
            trackedApp: appContext.currentTrackedApp,
            bundleIdentifier: appContext.frontmostBundleIdentifier,
            appDisplayName: appContext.frontmostAppName
        )
    }
}

/// Custom menu bar icon with a badge showing the current app's template count.
private struct MenuBarIconView: View {
    let count: Int

    var body: some View {
        HStack(spacing: 0) {
            Image("MenuBarIcon")
                .resizable()
                .renderingMode(.template)
                .scaledToFit()
                .frame(width: 18, height: 18)
                .foregroundStyle(.primary)
                .overlay(alignment: .topTrailing) {
                    if count > 0 {
                        Text("\(count)")
                            .font(.system(size: 8, weight: .bold))
                            .padding(.horizontal, 3.5)
                            .padding(.vertical, 1.25)
                            .background(
                                Capsule()
                                    .fill(Color.red.opacity(0.95))
                            )
                            .foregroundColor(.white)
                            .offset(x: 5, y: -5)
                    }
                }
        }
        .frame(width: 18, height: 18)
    }
}
