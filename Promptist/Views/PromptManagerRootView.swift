import SwiftUI

// MARK: - Sidebar Item

enum SidebarItem: Hashable {
    case allTemplates
    case category(UUID)
    case collection(UUID)
    case shortcuts
    case settings
}

struct PromptManagerRootView: View {
    @EnvironmentObject private var languageSettings: LanguageSettings
    @ObservedObject var promptListViewModel: PromptListViewModel
    @ObservedObject var shortcutManager: ShortcutManager
    @StateObject var shortcutViewModel: ShortcutManagerViewModel

    @State private var sidebarSelection: SidebarItem? = .allTemplates
    @State private var focusedTemplateId: UUID?

    init(promptListViewModel: PromptListViewModel, shortcutManager: ShortcutManager) {
        self.promptListViewModel = promptListViewModel
        self.shortcutManager = shortcutManager
        self._shortcutViewModel = StateObject(wrappedValue: ShortcutManagerViewModel(
            shortcutManager: shortcutManager,
            conflictDetector: ShortcutConflictDetector(),
            promptListViewModel: promptListViewModel
        ))
    }

    var body: some View {
        NavigationSplitView {
            sidebar
        } detail: {
            detailContent
        }
        .navigationSplitViewStyle(.balanced)
        .frame(minWidth: 700, minHeight: 520)
        .onChange(of: sidebarSelection) { _, newValue in
            applySidebarFilter(newValue)
        }
    }

    // MARK: - Sidebar

    private var sidebar: some View {
        List(selection: $sidebarSelection) {
            Section {
                Label(languageSettings.localized("prompt_manager.nav.all_templates"), systemImage: "doc.text")
                    .tag(SidebarItem.allTemplates)
            }

            if !promptListViewModel.rootCategories.isEmpty {
                Section(languageSettings.localized("prompt_manager.nav.categories")) {
                    ForEach(promptListViewModel.rootCategories) { category in
                        categoryRow(category)
                    }
                }
            }

            if !promptListViewModel.allCollections.isEmpty {
                Section(languageSettings.localized("prompt_manager.nav.collections")) {
                    ForEach(promptListViewModel.allCollections) { collection in
                        Label {
                            HStack {
                                Text(collection.name)
                                Spacer()
                                Text("\(promptListViewModel.templateCount(forCollection: collection.id))")
                                    .foregroundStyle(.secondary)
                                    .font(.caption)
                            }
                        } icon: {
                            Image(systemName: "tray")
                        }
                        .tag(SidebarItem.collection(collection.id))
                    }
                }
            }

            Section {
                Label(languageSettings.localized("prompt_manager.nav.shortcuts"), systemImage: "command")
                    .tag(SidebarItem.shortcuts)

                Label(languageSettings.localized("prompt_manager.nav.settings"), systemImage: "gearshape")
                    .tag(SidebarItem.settings)
            }
        }
        .listStyle(.sidebar)
        .navigationSplitViewColumnWidth(min: 180, ideal: 220, max: 260)
    }

    @ViewBuilder
    private func categoryRow(_ category: PromptCategory) -> some View {
        let children = promptListViewModel.childCategories(of: category.id)

        if children.isEmpty {
            Label {
                HStack {
                    Text(category.name)
                    Spacer()
                    Text("\(promptListViewModel.templateCount(for: category.id))")
                        .foregroundStyle(.secondary)
                        .font(.caption)
                }
            } icon: {
                Image(systemName: category.icon)
            }
            .tag(SidebarItem.category(category.id))
        } else {
            DisclosureGroup {
                ForEach(children) { child in
                    Label {
                        HStack {
                            Text(child.name)
                            Spacer()
                            Text("\(promptListViewModel.templateCount(for: child.id))")
                                .foregroundStyle(.secondary)
                                .font(.caption)
                        }
                    } icon: {
                        Image(systemName: child.icon)
                    }
                    .tag(SidebarItem.category(child.id))
                }
            } label: {
                Label {
                    HStack {
                        Text(category.name)
                        Spacer()
                        Text("\(promptListViewModel.templateCount(for: category.id))")
                            .foregroundStyle(.secondary)
                            .font(.caption)
                    }
                } icon: {
                    Image(systemName: category.icon)
                }
                .tag(SidebarItem.category(category.id))
            }
        }
    }

    // MARK: - Detail Content

    @ViewBuilder
    private var detailContent: some View {
        switch sidebarSelection {
        case .allTemplates, .category, .collection, .none:
            PromptManagerContentView(
                viewModel: promptListViewModel,
                shortcutViewModel: shortcutViewModel,
                onNavigateToShortcut: { templateId in
                    focusedTemplateId = templateId
                    sidebarSelection = .shortcuts
                }
            )

        case .shortcuts:
            ShortcutManagerView(
                viewModel: shortcutViewModel,
                shortcutManager: shortcutManager,
                focusedTemplateId: $focusedTemplateId
            )

        case .settings:
            SettingsView()
        }
    }

    // MARK: - Sidebar Filter Sync

    private func applySidebarFilter(_ item: SidebarItem?) {
        switch item {
        case .allTemplates, .none:
            promptListViewModel.selectCategory(nil)
            promptListViewModel.selectCollection(nil)
        case .category(let id):
            promptListViewModel.selectCategory(id)
            promptListViewModel.selectCollection(nil)
        case .collection(let id):
            promptListViewModel.selectCategory(nil)
            promptListViewModel.selectCollection(id)
        case .shortcuts, .settings:
            break
        }
    }
}
