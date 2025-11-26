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
    @State private var showLineNumbers: Bool = true
    @State private var isShowingAppSelector = false
    @StateObject private var appSelectorViewModel: AppSelectorViewModel

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

            TextField("prompt_editor.field.title", text: $title)
                .textFieldStyle(.roundedBorder)

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("prompt_editor.field.prompt")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Spacer()
                    Toggle("prompt_editor.toggle.show_line_numbers", isOn: $showLineNumbers)
                        .toggleStyle(.switch)
                        .font(.caption)
                }

                LineNumberedEditor(text: $content, showLineNumbers: showLineNumbers)
                    .frame(minHeight: 140)
                    .background(Color(nsColor: .textBackgroundColor).opacity(0.4))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.secondary.opacity(0.2))
                    )
            }

            TextField("prompt_editor.field.tags_placeholder", text: $tagInput)
                .textFieldStyle(.roundedBorder)

            VStack(alignment: .leading, spacing: 12) {
                Text("prompt_editor.field.linked_apps")
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
                    Label("Add or edit linked apps", systemImage: "link")
                }
                .buttonStyle(.borderless)
                .font(.footnote)
            }

            Text("prompt_editor.hint.selection_macro")
                .font(.footnote)
                .foregroundColor(.secondary)
                .padding(.top, 4)

            HStack {
                Spacer()
                Button("button.cancel", action: onCancel)
                Button("button.save", action: save)
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

    private var modeTitle: LocalizedStringKey {
        switch mode {
        case .create: return "prompt_editor.title_new"
        case .edit: return "prompt_editor.title_edit"
        }
    }

    private func save() {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanTags = tagInput
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        guard !trimmedTitle.isEmpty else { return }

        let linkedApps = appSelectorViewModel.linkedAppTargets()

        let template: PromptTemplate
        switch mode {
        case .create(let nextSortOrder, _):
            template = PromptTemplate(
                id: UUID(),
                title: trimmedTitle,
                content: content,
                tags: cleanTags,
                linkedApps: linkedApps,
                sortOrder: nextSortOrder
            )
        case .edit(let existing):
            template = PromptTemplate(
                id: existing.id,
                title: trimmedTitle,
                content: content,
                tags: cleanTags,
                linkedApps: linkedApps,
                sortOrder: existing.sortOrder
            )
        }

        onSave(template)
    }
}

/// Text editor styled for prompt writing, with optional line numbers and monospace font.
private struct LineNumberedEditor: View {
    @Binding var text: String
    let showLineNumbers: Bool

    private let editorFont: Font = .system(size: 13, weight: .regular, design: .monospaced)

    private var lines: [Substring] {
        let components = text.split(separator: "\n", omittingEmptySubsequences: false)
        return components.isEmpty ? [""] : components
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
            TextEditor(text: $text)
                .font(editorFont)
                .padding(.leading, showLineNumbers ? 40 : 0)
                .scrollContentBackground(.hidden)
                .background(Color.clear)

            if showLineNumbers {
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(alignment: .trailing, spacing: 0) {
                        ForEach(Array(lines.enumerated()), id: \.offset) { index, _ in
                            Text("\(index + 1)")
                                .font(editorFont)
                                .foregroundColor(.secondary)
                                .frame(maxWidth: .infinity, alignment: .trailing)
                        }
                        Spacer(minLength: 0)
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal, 6)
                }
                .frame(width: 36)
                .background(Color.black.opacity(0.03))
                .overlay(
                    Rectangle()
                        .fill(Color.secondary.opacity(0.15))
                        .frame(width: 1),
                    alignment: .trailing
                )
                .allowsHitTesting(false)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}
