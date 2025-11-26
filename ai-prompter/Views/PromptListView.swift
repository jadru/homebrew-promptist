import SwiftUI
import AppKit
import UserNotifications

struct PromptListView: View {
    @EnvironmentObject private var appContext: AppContextService
    @EnvironmentObject private var languageSettings: LanguageSettings
    @Environment(\.openWindow) private var openWindow
    @ObservedObject var viewModel: PromptListViewModel
    private let compactModeEnabled = true

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            headerStack

            Divider()
                .padding(.horizontal, 6)
                .opacity(0.25)

            CurrentAppHeaderView(onNewPrompt: { openManagerWindow(startNewForCurrentApp: true) })

            templateList
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .frame(width: 360)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(nsColor: .windowBackgroundColor))
                .shadow(color: Color.black.opacity(0.04), radius: 12, y: 2)
        )
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .onAppear {
            syncAppContext()
        }
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

    private var headerStack: some View {
        VStack(alignment: .leading, spacing: 10) {
            SearchBarView(
                text: $viewModel.searchText,
                placeholder: searchPlaceholder,
                onSubmit: { viewModel.recordRecentSearch(viewModel.searchText) },
                manageAction: { openManagerWindow() },
                manageLabel: manageButtonTitle
            )

            if !viewModel.recentSearches.isEmpty {
                recentSearchRow
            }
        }
    }

    private func syncAppContext() {
        viewModel.updateCurrentApp(
            trackedApp: appContext.currentTrackedApp,
            bundleIdentifier: appContext.frontmostBundleIdentifier,
            appDisplayName: appContext.frontmostAppName
        )
    }

    private var templateList: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: compactModeEnabled ? 10 : 14) {
                if !viewModel.linkedTemplatesForCurrentApp.isEmpty {
                    SectionHeaderView(title: sectionTitle(for: "section.current_app"))
                    templateGroup(viewModel.linkedTemplatesForCurrentApp)
                }

                if !viewModel.generalTemplates.isEmpty {
                    SectionHeaderView(title: sectionTitle(for: "section.all_templates"))
                    templateGroup(viewModel.generalTemplates)
                }
            }
            .padding(.vertical, 2)
        }
        .frame(minHeight: 200, maxHeight: 360) // Cap height to avoid constraint churn inside menu bar popover.
    }

    private var recentSearchRow: some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack {
                Text("section.recent_searches")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                Spacer()
                Button("action.clear") {
                    viewModel.clearRecentSearches()
                }
                .font(.caption2)
                .buttonStyle(.borderless)
                .foregroundColor(.secondary)
                .help(String(localized: "recent_searches.clear_help", locale: languageSettings.locale))
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(viewModel.recentSearches, id: \.self) { term in
                        Button {
                            viewModel.searchText = term
                        } label: {
                            Text(term)
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Capsule().fill(Color.gray.opacity(0.14)))
                        }
                        .buttonStyle(.plain)
                        .foregroundColor(.primary)
                    }
                }
                .padding(.vertical, 1)
            }
        }
    }

    private func templateGroup(_ templates: [PromptTemplate]) -> some View {
        VStack(alignment: .leading, spacing: compactModeEnabled ? 8 : 10) {
            ForEach(Array(templates.enumerated()), id: \.element.id) { index, template in
                TemplateRowView(
                    template: template,
                    linkedAppsText: linkedAppsText(for: template),
                    isCompact: compactModeEnabled
                ) {
                    handleTemplateTap(template)
                }

                if index < templates.count - 1 {
                    Divider()
                        .padding(.horizontal, 4)
                        .opacity(0.15)
                }
            }
        }
    }

    private func linkedAppsText(for template: PromptTemplate) -> String? {
        guard !template.linkedApps.isEmpty else { return nil }
        return template.linkedApps.map { $0.displayName }.joined(separator: ", ")
    }

    private func copyToClipboard(_ text: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
    }

    private func showCopyNotification(for template: PromptTemplate) {
        let center = UNUserNotificationCenter.current()
        let content = UNMutableNotificationContent()
        content.title = String(localized: "notification.copy_success.title", locale: languageSettings.locale)

        if let appName = appContext.currentTrackedApp?.displayName {
            let format = String(localized: "notification.copy_success.body.app", locale: languageSettings.locale)
            content.body = String.localizedStringWithFormat(format, appName)
        } else {
            let format = String(localized: "notification.copy_success.body.generic", locale: languageSettings.locale)
            content.body = String.localizedStringWithFormat(format, template.title)
        }

        let request = UNNotificationRequest(
            identifier: "prompt-copy-\(UUID().uuidString)",
            content: content,
            trigger: nil
        )

        center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
            guard granted else { return }
            center.add(request, withCompletionHandler: nil)
        }
    }

    private func openManagerWindow(startNewForCurrentApp: Bool = false) {
        if startNewForCurrentApp {
            viewModel.prepareCreationIntentForCurrentApp()
        }
        closePopover()
        openWindow(id: "prompt-manager")
        NSApp.activate(ignoringOtherApps: true)
    }

    private func closePopover() {
        NSApp.sendAction(#selector(NSPopover.performClose(_:)), to: nil, from: nil)
    }

    private func handleTemplateTap(_ template: PromptTemplate) {
        copyToClipboard(template.content)
        showCopyNotification(for: template)
        closePopover()
    }

    private var searchPlaceholder: String {
        localizedString(for: "search.placeholder", fallback: "Search prompts…")
    }

    private var manageButtonTitle: String {
        localizedString(for: "button.manage", fallback: "Manage")
    }

    private func sectionTitle(for key: String) -> String {
        switch key {
        case "section.current_app":
            return localizedString(for: key, fallback: "Current App")
        case "section.all_templates":
            return localizedString(for: key, fallback: "All Templates")
        default:
            return localizedString(for: key, fallback: key)
        }
    }

    private func localizedString(for key: String, fallback: String) -> String {
        let value = String(localized: String.LocalizationValue(key), locale: languageSettings.locale)
        return value == key ? fallback : value
    }
}

#Preview {
    let context = AppContextService()
    context.currentTrackedApp = .chatGPT
    let vm = PromptListViewModel(repository: FilePromptTemplateRepository())
    return PromptListView(viewModel: vm)
        .environmentObject(context)
        .environmentObject(LanguageSettings())
}
