import SwiftUI
import Combine
import AppKit

/// Dedicated window for creating, editing, and deleting prompt templates.
struct PromptManagerView: View {
    enum PresentationStyle {
        case window
        case floatingPanel
    }

    @EnvironmentObject private var languageSettings: LanguageSettings
    @ObservedObject var viewModel: PromptListViewModel
    var presentationStyle: PresentationStyle = .window

    @State private var searchText = ""
    @State private var isPresentingEditor = false
    @State private var editorMode: PromptEditorView.Mode = .create(nextSortOrder: 1, presetApps: [])
    @State private var templatePendingDeletion: PromptTemplate?
    @State private var showDeleteConfirmation = false
    @State private var searchRecordWorkItem: DispatchWorkItem?

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                searchBar

                List {
                    ForEach(displayedTemplates) { template in
                        managerRow(template)
                    }
                    .onDelete(perform: deleteTemplates)
                }
                .listStyle(.inset)
            }
            .navigationTitle("prompt_manager.title")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: presentCreateEditor) {
                        Label("prompt_manager.toolbar.new_prompt", systemImage: "plus")
                    }
                    .help(String(localized: "prompt_manager.toolbar.new_prompt.help", locale: languageSettings.locale))
                }
            }
        }
        .sheet(isPresented: $isPresentingEditor) {
            PromptEditorView(mode: editorMode) { template in
                viewModel.saveNewOrUpdated(template)
                isPresentingEditor = false
            } onCancel: {
                isPresentingEditor = false
            }
        }
        .alert("prompt_manager.delete_alert.title", isPresented: $showDeleteConfirmation, presenting: templatePendingDeletion) { template in
            Button("prompt_manager.delete_alert.delete", role: .destructive) {
                viewModel.deleteTemplate(template)
            }
            Button("prompt_manager.delete_alert.cancel", role: .cancel) { }
        } message: { _ in
            Text("prompt_manager.delete_alert.message")
        }
        .frame(minWidth: presentationStyle.minWidth,
               minHeight: presentationStyle.minHeight)
        .onAppear {
            if let intent = viewModel.pendingCreationIntent {
                handlePendingCreationIntent(intent)
            }
        }
        .onReceive(viewModel.$pendingCreationIntent.compactMap { $0 }) { intent in
            handlePendingCreationIntent(intent)
        }
    }

    private var displayedTemplates: [PromptTemplate] {
        viewModel.templatesForManagement(searchText: searchText)
    }

    private var searchBar: some View {
        VStack(alignment: .leading, spacing: 10) {
            TextField("search.placeholder", text: $searchText)
                .textFieldStyle(.roundedBorder)
                .onChange(of: searchText) { newValue in
                    searchRecordWorkItem?.cancel()
                    let workItem = DispatchWorkItem { viewModel.recordRecentSearch(newValue) }
                    searchRecordWorkItem = workItem
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: workItem)
                }
                .onSubmit {
                    viewModel.recordRecentSearch(searchText)
                }

            quickFilters

            if !viewModel.recentSearches.isEmpty {
                recentSearchRow
            }
        }
        .padding([.horizontal, .top])
        .padding(.bottom, 8)
    }

    private func managerRow(_ template: PromptTemplate) -> some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(template.title)
                        .font(.headline)
                    Spacer()
                    if template.linkedApps.isEmpty {
                        Text(String(localized: "prompt_manager.label.all_apps", locale: languageSettings.locale))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else {
                        LinkedAppSummaryView(
                            selectedApps: appInfos(for: template),
                            onRemove: { _ in },
                            onAdd: { },
                            showAddButton: false,
                            allowRemoval: false
                        )
                        .frame(maxWidth: 260, alignment: .trailing)
                    }
                }

                if !template.tags.isEmpty {
                    Text(template.tags.joined(separator: ", "))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Text(template.content)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            VStack(alignment: .trailing, spacing: 8) {
                Button {
                    presentEditEditor(for: template)
                } label: {
                    Image(systemName: "square.and.pencil")
                }
                .buttonStyle(.borderless)
                .help(String(localized: "prompt_manager.help.edit_prompt", locale: languageSettings.locale))

                Button(role: .destructive) {
                    templatePendingDeletion = template
                    showDeleteConfirmation = true
                } label: {
                    Image(systemName: "trash")
                }
                .buttonStyle(.borderless)
                .help(String(localized: "prompt_manager.help.delete_prompt", locale: languageSettings.locale))
            }
        }
        .padding(.vertical, 8)
    }

    private var quickFilters: some View {
        HStack(spacing: 8) {
            filterButton(for: .chatGPT)
            filterButton(for: .warp)
            filterButton(for: .cursor)

            Button {
                viewModel.selectFilter(.all)
            } label: {
                Text("filter.all")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(viewModel.quickFilter == .all ? .accentColor : .gray.opacity(0.2))
            .foregroundColor(viewModel.quickFilter == .all ? .white : .primary)
        }
    }

    private func filterButton(for app: TrackedApp) -> some View {
        Button {
            viewModel.selectFilter(.app(app))
        } label: {
            Text(app.displayName)
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .tint(viewModel.isFilterSelected(app) ? .accentColor : .gray.opacity(0.2))
        .foregroundColor(viewModel.isFilterSelected(app) ? .white : .primary)
    }

    private var recentSearchRow: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("section.recent_searches")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                Button("action.clear") {
                    viewModel.clearRecentSearches()
                }
                .font(.caption)
                .buttonStyle(.borderless)
                .foregroundColor(.secondary)
                .help(String(localized: "recent_searches.clear_help", locale: languageSettings.locale))
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(viewModel.recentSearches, id: \.self) { term in
                        Button {
                            searchText = term
                        } label: {
                            Text(term)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(Capsule().fill(Color.gray.opacity(0.15)))
                        }
                        .buttonStyle(.plain)
                        .foregroundColor(.primary)
                    }
                }
                .padding(.vertical, 2)
            }
        }
    }

    private func presentCreateEditor() {
        editorMode = .create(nextSortOrder: viewModel.nextSortOrder, presetApps: [])
        isPresentingEditor = true
    }

    private func presentEditEditor(for template: PromptTemplate) {
        editorMode = .edit(existing: template)
        isPresentingEditor = true
    }

    private func deleteTemplates(_ offsets: IndexSet) {
        for offset in offsets {
            guard displayedTemplates.indices.contains(offset) else { continue }
            let template = displayedTemplates[offset]
            viewModel.deleteTemplate(template)
        }
    }

    private func appInfos(for template: PromptTemplate) -> [AppInfo] {
        template.linkedApps.map { target in
            switch target {
            case .tracked(let tracked):
                let bundleId = TrackedAppConfig.config(for: tracked)?.bundleIdentifiers.first
                return AppInfo(name: tracked.displayName, bundleId: bundleId, icon: nil, isCustom: false)
            case .custom(let name, let bundleIdentifier):
                return AppInfo(name: name, bundleId: bundleIdentifier, icon: nil, isCustom: true)
            }
        }
        .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    private func handlePendingCreationIntent(_ intent: PromptListViewModel.PromptCreationIntent) {
        editorMode = .create(nextSortOrder: viewModel.nextSortOrder, presetApps: intent.presetApps)
        isPresentingEditor = true
        viewModel.pendingCreationIntent = nil
    }
}

private extension PromptManagerView.PresentationStyle {
    var minWidth: CGFloat {
        switch self {
        case .window:
            return 640
        case .floatingPanel:
            return 420
        }
    }

    var minHeight: CGFloat {
        switch self {
        case .window:
            return 520
        case .floatingPanel:
            return 460
        }
    }
}

#Preview {
    let context = AppContextService()
    context.currentTrackedApp = .chatGPT
    let vm = PromptListViewModel(repository: FilePromptTemplateRepository())
    return PromptManagerView(viewModel: vm)
        .environmentObject(context)
}
