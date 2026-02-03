import SwiftUI

/// Simple editor for creating or updating a prompt template.
struct PromptEditorView: View {
    enum Mode {
        case create(nextSortOrder: Int, presetApps: [PromptAppTarget], categoryId: UUID?)
        case edit(existing: PromptTemplate)
    }

    let mode: Mode
    let categories: [PromptCategory]
    let onSave: (PromptTemplate) -> Void
    let onCancel: () -> Void

    @State private var title: String
    @State private var content: String
    @State private var keywordInput: String  // Renamed from tagInput
    @State private var selectedCategoryId: UUID?
    @State private var isShowingAppSelector = false
    @StateObject private var appSelectorViewModel: AppSelectorViewModel
    @EnvironmentObject private var languageSettings: LanguageSettings

    init(
        mode: Mode,
        categories: [PromptCategory] = [],
        onSave: @escaping (PromptTemplate) -> Void,
        onCancel: @escaping () -> Void
    ) {
        self.mode = mode
        self.categories = categories
        self.onSave = onSave
        self.onCancel = onCancel
        let initialLinkedApps: [PromptAppTarget]

        switch mode {
        case .create(_, let presetApps, let categoryId):
            _title = State(initialValue: "")
            _content = State(initialValue: "")
            _keywordInput = State(initialValue: "")
            _selectedCategoryId = State(initialValue: categoryId)
            initialLinkedApps = presetApps
        case .edit(let existing):
            _title = State(initialValue: existing.title)
            _content = State(initialValue: existing.content)
            _keywordInput = State(initialValue: existing.keywords.joined(separator: ", "))
            _selectedCategoryId = State(initialValue: existing.categoryId)
            initialLinkedApps = existing.linkedApps
        }

        _appSelectorViewModel = StateObject(wrappedValue: AppSelectorViewModel(initialLinkedApps: initialLinkedApps))
    }

    // MARK: - Category Helpers

    private var rootCategories: [PromptCategory] {
        categories.filter { $0.parentId == nil }.sorted { $0.sortOrder < $1.sortOrder }
    }

    private func childCategories(of parentId: UUID) -> [PromptCategory] {
        categories.filter { $0.parentId == parentId }.sorted { $0.sortOrder < $1.sortOrder }
    }

    private func categoryName(for categoryId: UUID?) -> String {
        guard let id = categoryId,
              let category = categories.first(where: { $0.id == id }) else {
            return languageSettings.localized("category.none")
        }
        if let parentId = category.parentId,
           let parent = categories.first(where: { $0.id == parentId }) {
            return "\(parent.name) / \(category.name)"
        }
        return category.name
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(modeTitle)
                .font(.headline)

            // Prompt content (required) - now first
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 4) {
                    Text(languageSettings.localized("prompt_editor.field.prompt"))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Text("*")
                        .font(.subheadline)
                        .foregroundColor(.red)
                }

                VariableHighlightedTextEditor(text: $content)
                    .frame(minHeight: 140)
            }

            // Title (optional) - now below prompt
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 4) {
                    Text(languageSettings.localized("prompt_editor.field.title"))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Text(languageSettings.localized("prompt_editor.field.title.optional"))
                        .font(.caption)
                        .foregroundColor(Color(nsColor: .tertiaryLabelColor))
                }
                TextField(languageSettings.localized("prompt_editor.field.title.placeholder"), text: $title)
                    .textFieldStyle(.roundedBorder)
            }

            // Category selector
            if !categories.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text(languageSettings.localized("category.select"))
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)

                    Menu {
                        // Option to have no category
                        Button(action: { selectedCategoryId = nil }) {
                            if selectedCategoryId == nil {
                                Label(languageSettings.localized("category.none"), systemImage: "checkmark")
                            } else {
                                Text(languageSettings.localized("category.none"))
                            }
                        }

                        Divider()

                        // Show categories grouped by parent
                        ForEach(rootCategories) { parent in
                            Menu(parent.name) {
                                ForEach(childCategories(of: parent.id)) { child in
                                    Button(action: { selectedCategoryId = child.id }) {
                                        if selectedCategoryId == child.id {
                                            Label(child.name, systemImage: "checkmark")
                                        } else {
                                            Text(child.name)
                                        }
                                    }
                                }
                            }
                        }
                    } label: {
                        HStack {
                            Text(categoryName(for: selectedCategoryId))
                                .foregroundStyle(.primary)
                            Spacer()
                            Image(systemName: "chevron.down")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 6)
                        .glassCardBackground(cornerRadius: 6)
                    }
                    .menuStyle(.borderlessButton)
                }
            }

            // Keywords (for search, not displayed in UI filtering)
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 4) {
                    Text(languageSettings.localized("prompt_editor.field.keywords.label"))
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                    Text(languageSettings.localized("prompt_editor.field.keywords.for_search"))
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
                TextField(languageSettings.localized("prompt_editor.field.keywords.example"), text: $keywordInput)
                    .textFieldStyle(.roundedBorder)
            }

            VStack(alignment: .leading, spacing: 12) {
                Text(languageSettings.localized("prompt_editor.field.linked_apps"))
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)

                LinkedAppSummaryView(
                    selectedApps: selectedAppsSorted,
                    onRemove: { appSelectorViewModel.toggleSelection($0) },
                    onAdd: { isShowingAppSelector = true }
                )

                Button {
                    isShowingAppSelector = true
                } label: {
                    Label(languageSettings.localized("prompt_editor.button.add_edit_apps"), systemImage: "link")
                }
                .buttonStyle(.borderless)
                .font(.footnote)
            }

            Text(languageSettings.localized("prompt_editor.hint.variables"))
                .font(.footnote)
                .foregroundColor(.secondary)
                .padding(.top, 4)

            HStack {
                Spacer()
                Button(languageSettings.localized("button.cancel"), action: onCancel)
                Button(languageSettings.localized("button.save"), action: save)
                    .keyboardShortcut(.defaultAction)
            }
        }
            .padding()
        .frame(minWidth: 420)
        .sheet(isPresented: $isShowingAppSelector) {
            AppSelectorDrawerView(viewModel: appSelectorViewModel) {
                isShowingAppSelector = false
            }
        }
    }

    private var selectedAppsSorted: [AppInfo] {
        appSelectorViewModel.selectedApps
            .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    private var modeTitle: String {
        switch mode {
        case .create: return languageSettings.localized("prompt_editor.title_new")
        case .edit: return languageSettings.localized("prompt_editor.title_edit")
        }
    }

    private func save() {
        let trimmedContent = content.trimmingCharacters(in: .whitespacesAndNewlines)

        // Content is required
        guard !trimmedContent.isEmpty else { return }

        // Title is optional - auto-generate from content if empty
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let finalTitle: String
        if trimmedTitle.isEmpty {
            // Use first 30 characters of content + "..."
            let firstLine = trimmedContent.components(separatedBy: .newlines).first ?? trimmedContent
            let cleanFirstLine = firstLine.trimmingCharacters(in: .whitespacesAndNewlines)
            if cleanFirstLine.count > 30 {
                finalTitle = String(cleanFirstLine.prefix(30)) + "..."
            } else {
                finalTitle = cleanFirstLine
            }
        } else {
            finalTitle = trimmedTitle
        }

        let cleanKeywords = keywordInput
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        let linkedApps = appSelectorViewModel.linkedAppTargets()

        let template: PromptTemplate
        switch mode {
        case .create(let nextSortOrder, _, _):
            template = PromptTemplate(
                id: UUID(),
                title: finalTitle,
                content: trimmedContent,
                keywords: cleanKeywords,
                linkedApps: linkedApps,
                sortOrder: nextSortOrder,
                categoryId: selectedCategoryId
            )
        case .edit(let existing):
            template = PromptTemplate(
                id: existing.id,
                title: finalTitle,
                content: trimmedContent,
                keywords: cleanKeywords,
                linkedApps: linkedApps,
                sortOrder: existing.sortOrder,
                usageCount: existing.usageCount,
                lastUsedAt: existing.lastUsedAt,
                collectionId: existing.collectionId,
                categoryId: selectedCategoryId
            )
        }

        onSave(template)
    }
}
