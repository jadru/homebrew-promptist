import SwiftUI
import AppKit

struct LinkedAppSummaryView: View {
    var selectedApps: [AppInfo]
    var onRemove: (AppInfo) -> Void
    var onAdd: () -> Void
    var showAddButton: Bool = true
    var allowRemoval: Bool = true

    @EnvironmentObject private var languageSettings: LanguageSettings
    private let columns = [GridItem(.adaptive(minimum: 140, maximum: 200), spacing: 8)]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            LazyVGrid(columns: columns, alignment: .leading, spacing: 8) {
                ForEach(selectedApps) { app in
                    pill(for: app)
                }

                if showAddButton {
                    Button(action: onAdd) {
                        Label(String(localized: "app_selector.button.add_app", locale: languageSettings.locale), systemImage: "plus")
                            .labelStyle(.titleAndIcon)
                            .font(.system(size: 13, weight: .semibold))
                            .padding(.vertical, 6)
                            .padding(.horizontal, 12)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }
            }
        }
    }

    private func pill(for app: AppInfo) -> some View {
        HStack(spacing: 8) {
            AppIconView(icon: app.icon)
                .frame(width: 18, height: 18)
                .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))

            Text(app.name)
                .font(.system(size: 13, weight: .medium))
                .lineLimit(1)

            Spacer(minLength: 4)

            if allowRemoval {
                Button {
                    onRemove(app)
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .help(String(localized: "app_selector.button.remove", locale: languageSettings.locale).replacingOccurrences(of: "%@", with: app.name))
            }
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 10)
        .background(
            Capsule(style: .continuous)
                .fill(Color.primary.opacity(0.06))
        )
        .overlay(
            Capsule(style: .continuous)
                .stroke(Color.primary.opacity(0.1), lineWidth: 0.8)
        )
    }
}

struct AppSelectorDrawerView: View {
    @ObservedObject var viewModel: AppSelectorViewModel
    var onClose: () -> Void

    @EnvironmentObject private var languageSettings: LanguageSettings

    var body: some View {
        VStack(spacing: 12) {
            header
            searchBar

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    section(title: String(localized: "app_selector.section.suggested", locale: languageSettings.locale)) {
                        if viewModel.filteredBuiltInApps.isEmpty {
                            EmptyStateRow(text: String(localized: "app_selector.empty.suggested", locale: languageSettings.locale))
                        } else {
                            ForEach(viewModel.filteredBuiltInApps) { app in
                                AppListRow(
                                    app: app,
                                    isSelected: viewModel.isSelected(app),
                                    onToggle: { viewModel.toggleSelection(app) }
                                )
                            }
                        }
                    }

                    section(title: String(localized: "app_selector.section.installed", locale: languageSettings.locale)) {
                        if viewModel.filteredInstalledApps.isEmpty {
                            EmptyStateRow(text: String(localized: "app_selector.empty.installed", locale: languageSettings.locale))
                        } else {
                            ForEach(viewModel.filteredInstalledApps) { app in
                                AppListRow(
                                    app: app,
                                    isSelected: viewModel.isSelected(app),
                                    onToggle: { viewModel.toggleSelection(app) }
                                )
                            }
                        }
                    }

                    section(title: String(localized: "app_selector.section.custom", locale: languageSettings.locale)) {
                        if viewModel.filteredCustomApps.isEmpty {
                            EmptyStateRow(text: String(localized: "app_selector.empty.custom", locale: languageSettings.locale))
                        }

                        ForEach($viewModel.customApps) { $app in
                            let currentApp = app
                            CustomAppEditorView(
                                app: $app,
                                isSelected: viewModel.isSelected(currentApp),
                                onToggle: { viewModel.toggleSelection(currentApp) },
                                onRemove: { viewModel.removeCustomApp(currentApp) }
                            )
                        }

                        Button {
                            viewModel.addEmptyCustomApp()
                        } label: {
                            Label(String(localized: "app_selector.button.add_custom", locale: languageSettings.locale), systemImage: "plus")
                                .labelStyle(.titleAndIcon)
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                    }
                }
                .padding(.vertical, 6)
            }
        }
        .padding(16)
        .frame(minWidth: 420, maxWidth: 520, maxHeight: 520)
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(String(localized: "app_selector.title", locale: languageSettings.locale))
                    .font(.title3.weight(.semibold))
                Text(String(localized: "app_selector.subtitle", locale: languageSettings.locale))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Button(String(localized: "app_selector.button.close", locale: languageSettings.locale), action: onClose)
                .controlSize(.small)
        }
    }

    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
            TextField("Search apps", text: $viewModel.searchText)
                .textFieldStyle(.plain)
                .disableAutocorrection(true)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color(nsColor: .textBackgroundColor))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(Color.primary.opacity(0.08), lineWidth: 0.8)
        )
    }

    private func section(title: String, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title.uppercased())
                .font(.caption2.smallCaps())
                .foregroundStyle(.secondary)
            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct AppListRow: View {
    let app: AppInfo
    var isSelected: Bool
    var onToggle: () -> Void

    var body: some View {
        Button(action: onToggle) {
            HStack(spacing: 10) {
                AppIconView(icon: app.icon)
                    .frame(width: 24, height: 24)
                    .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))

                VStack(alignment: .leading, spacing: 2) {
                    Text(app.name)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                    if app.isCustom, let bundleId = app.bundleId, !bundleId.isEmpty {
                        Text(bundleId)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }

                Spacer()

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(isSelected ? Color.accentColor : Color.secondary.opacity(0.5))
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(isSelected ? Color.accentColor.opacity(0.12) : Color.clear)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

struct CustomAppEditorView: View {
    @Binding var app: AppInfo
    var isSelected: Bool
    var onToggle: () -> Void
    var onRemove: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 10) {
                AppIconView(icon: app.icon)
                    .frame(width: 24, height: 24)
                    .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))

                VStack(alignment: .leading, spacing: 4) {
                    TextField("App name", text: Binding(
                        get: { app.name },
                        set: { app.name = $0 }
                    ))
                    .textFieldStyle(.roundedBorder)

                    TextField("Bundle identifier (optional)", text: Binding(
                        get: { app.bundleId ?? "" },
                        set: { app.bundleId = $0.isEmpty ? nil : $0 }
                    ))
                    .textFieldStyle(.roundedBorder)
                }

                Spacer()

                Button(action: onToggle) {
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .foregroundStyle(isSelected ? Color.accentColor : Color.secondary.opacity(0.5))
                }
                .buttonStyle(.plain)

                Button(role: .destructive, action: onRemove) {
                    Image(systemName: "trash")
                }
                .buttonStyle(.plain)
            }
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color.primary.opacity(0.03))
        )
    }
}

private struct AppIconView: View {
    var icon: NSImage?

    var body: some View {
        Group {
            if let icon {
                Image(nsImage: icon)
                    .resizable()
                    .scaledToFit()
            } else {
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(Color.primary.opacity(0.06))
                    .overlay(
                        Image(systemName: "app.dashed")
                            .foregroundStyle(.secondary)
                    )
            }
        }
    }
}

private struct EmptyStateRow: View {
    var text: String

    var body: some View {
        Text(text)
            .font(.caption)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 2)
    }
}
