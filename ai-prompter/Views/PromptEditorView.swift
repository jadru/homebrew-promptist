import SwiftUI

/// Simple editor for creating or updating a prompt template.
struct PromptEditorView: View {
    enum Mode {
        case create(nextSortOrder: Int, presetApps: [PromptAppTarget])
        case edit(existing: PromptTemplate)
    }

    let mode: Mode
    let onSave: (PromptTemplate) -> Void
    let onCancel: () -> Void

    @State private var title: String
    @State private var content: String
    @State private var tagInput: String
    @State private var isShowingAppSelector = false
    @StateObject private var appSelectorViewModel: AppSelectorViewModel
    @EnvironmentObject private var languageSettings: LanguageSettings

    init(mode: Mode, onSave: @escaping (PromptTemplate) -> Void, onCancel: @escaping () -> Void) {
        self.mode = mode
        self.onSave = onSave
        self.onCancel = onCancel
        let initialLinkedApps: [PromptAppTarget]

        switch mode {
        case .create(_, let presetApps):
            _title = State(initialValue: "")
            _content = State(initialValue: "")
            _tagInput = State(initialValue: "")
            initialLinkedApps = presetApps
        case .edit(let existing):
            _title = State(initialValue: existing.title)
            _content = State(initialValue: existing.content)
            _tagInput = State(initialValue: existing.tags.joined(separator: ", "))
            initialLinkedApps = existing.linkedApps
        }

        _appSelectorViewModel = StateObject(wrappedValue: AppSelectorViewModel(initialLinkedApps: initialLinkedApps))
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

            TextField(languageSettings.localized("prompt_editor.field.tags_placeholder"), text: $tagInput)
                .textFieldStyle(.roundedBorder)

            VStack(alignment: .leading, spacing: 12) {
                Text(languageSettings.localized("prompt_editor.field.linked_apps"))
                    .font(.subheadline)
                    .foregroundColor(.secondary)

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

        let cleanTags = tagInput
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        let linkedApps = appSelectorViewModel.linkedAppTargets()

        let template: PromptTemplate
        switch mode {
        case .create(let nextSortOrder, _):
            template = PromptTemplate(
                id: UUID(),
                title: finalTitle,
                content: trimmedContent,
                tags: cleanTags,
                linkedApps: linkedApps,
                sortOrder: nextSortOrder
            )
        case .edit(let existing):
            template = PromptTemplate(
                id: existing.id,
                title: finalTitle,
                content: trimmedContent,
                tags: cleanTags,
                linkedApps: linkedApps,
                sortOrder: existing.sortOrder
            )
        }

        onSave(template)
    }
}
