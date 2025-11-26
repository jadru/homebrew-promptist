import SwiftUI

enum PromptFilterMode: Equatable {
    case all
    case byApp
}

/// Compact filter bar that scales to many apps by splitting primary mode (all vs app) and secondary pills.
struct PromptFilterBarView: View {
    @Binding var mode: PromptFilterMode
    var pinnedApps: [AppInfo]
    var selectedApp: AppInfo?
    var onSelectApp: (AppInfo?) -> Void
    var onManageApps: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            PrimaryFilterSegmentedControl(mode: $mode)

            if mode == .byApp {
                AppPillRow(
                    apps: pinnedApps,
                    selectedApp: selectedApp,
                    onSelect: onSelectApp,
                    onManageApps: onManageApps
                )
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }
}

struct PrimaryFilterSegmentedControl: View {
    @Binding var mode: PromptFilterMode

    var body: some View {
        Picker("", selection: $mode) {
            Text("All prompts").tag(PromptFilterMode.all)
            Text("By app").tag(PromptFilterMode.byApp)
        }
        .pickerStyle(.segmented)
        .controlSize(.small)
    }
}

struct AppPillRow: View {
    var apps: [AppInfo]
    var selectedApp: AppInfo?
    var onSelect: (AppInfo?) -> Void
    var onManageApps: () -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(apps) { app in
                    pill(for: app)
                }

                Button(action: onManageApps) {
                    Label("Manage Apps", systemImage: "ellipsis.circle")
                        .labelStyle(.titleAndIcon)
                        .font(.system(size: 12, weight: .semibold))
                        .padding(.vertical, 6)
                        .padding(.horizontal, 10)
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
            .padding(.vertical, 2)
        }
    }

    private func pill(for app: AppInfo) -> some View {
        let isSelected = selectedApp?.id == app.id

        return Button {
            onSelect(app)
        } label: {
            Text(app.name)
                .font(.system(size: 12, weight: isSelected ? .semibold : .medium))
                .padding(.vertical, 6)
                .padding(.horizontal, 12)
                .frame(minWidth: 70)
                .background(
                    Capsule()
                        .fill(isSelected ? Color.accentColor.opacity(0.16) : Color.primary.opacity(0.06))
                )
                .overlay(
                    Capsule()
                        .stroke(isSelected ? Color.accentColor : Color.primary.opacity(0.12), lineWidth: 0.8)
                )
                .foregroundStyle(isSelected ? Color.accentColor : Color.primary)
        }
        .buttonStyle(.plain)
    }
}
