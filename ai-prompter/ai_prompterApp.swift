//
//  ai_prompterApp.swift
//  ai-prompter
//
//  Created by Younggun Park on 11/25/25.
//

import SwiftUI
import AppKit

// <CHORUS_TAG>main</CHORUS_TAG>
@main
struct AiPrompterApp: App {
    @StateObject private var appContext = AppContextService()
    @StateObject private var languageSettings = LanguageSettings()
    @StateObject private var promptListViewModel: PromptListViewModel

    init() {
        if let appIcon = NSImage(named: "AppIcon") {
            NSApplication.shared.applicationIconImage = appIcon
        }
        _promptListViewModel = StateObject(wrappedValue: PromptListViewModel(repository: FilePromptTemplateRepository()))
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

        WindowGroup("prompt_manager.window_title", id: "manager") {
            PromptManagerView(viewModel: promptListViewModel)
                .environmentObject(appContext)
                .environmentObject(languageSettings)
                .environment(\.locale, languageSettings.locale)
        }

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
