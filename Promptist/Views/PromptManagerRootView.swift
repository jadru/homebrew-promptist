import SwiftUI

struct PromptManagerRootView: View {
    enum ManagerTab {
        case templates
        case shortcuts
        case settings
    }

    @EnvironmentObject private var languageSettings: LanguageSettings
    @ObservedObject var promptListViewModel: PromptListViewModel
    @ObservedObject var shortcutManager: ShortcutManager
    @StateObject var shortcutViewModel: ShortcutManagerViewModel

    @State private var selectedTab: ManagerTab = .templates
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
        HStack(spacing: 0) {
            // Left navigation sidebar
            navigationSidebar
                .frame(width: 180)

            Separator(orientation: .vertical)

            // Right content area
            contentArea
                .frame(minWidth: 460)
        }
        .frame(minWidth: 640, minHeight: 520)
        .background(DesignTokens.Colors.backgroundPrimary)
    }

    private var navigationSidebar: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
            Text(languageSettings.localized("prompt_manager.root.title"))
                .font(DesignTokens.Typography.headline(16, weight: .semibold))
                .foregroundColor(DesignTokens.Colors.foregroundPrimary)
                .padding(.horizontal, DesignTokens.Spacing.md)
                .padding(.top, DesignTokens.Spacing.lg)

            Separator()

            VStack(spacing: DesignTokens.Spacing.xxs) {
                NavigationTabButton(
                    title: languageSettings.localized("prompt_manager.nav.templates"),
                    icon: "doc.text",
                    isSelected: selectedTab == .templates,
                    action: {
                        withAnimation(DesignTokens.Animation.normal) {
                            selectedTab = .templates
                        }
                    }
                )

                NavigationTabButton(
                    title: languageSettings.localized("prompt_manager.nav.shortcuts"),
                    icon: "command",
                    isSelected: selectedTab == .shortcuts,
                    action: {
                        withAnimation(DesignTokens.Animation.normal) {
                            selectedTab = .shortcuts
                        }
                    }
                )

                NavigationTabButton(
                    title: languageSettings.localized("prompt_manager.nav.settings"),
                    icon: "gearshape",
                    isSelected: selectedTab == .settings,
                    action: {
                        withAnimation(DesignTokens.Animation.normal) {
                            selectedTab = .settings
                        }
                    }
                )
            }
            .padding(.horizontal, DesignTokens.Spacing.sm)

            Spacer()
        }
        .background(DesignTokens.Colors.backgroundSecondary)
    }

    private var contentArea: some View {
        Group {
            switch selectedTab {
            case .templates:
                PromptManagerContentView(
                    viewModel: promptListViewModel,
                    shortcutViewModel: shortcutViewModel,
                    onNavigateToShortcut: { templateId in
                        focusedTemplateId = templateId
                        withAnimation(DesignTokens.Animation.normal) {
                            selectedTab = .shortcuts
                        }
                    }
                )
                .transition(.opacity.combined(with: .move(edge: .trailing)))

            case .shortcuts:
                ShortcutManagerView(
                    viewModel: shortcutViewModel,
                    shortcutManager: shortcutManager,
                    focusedTemplateId: $focusedTemplateId
                )
                .transition(.opacity.combined(with: .move(edge: .trailing)))

            case .settings:
                SettingsView()
                    .transition(.opacity.combined(with: .move(edge: .trailing)))
            }
        }
        .animation(DesignTokens.Animation.normal, value: selectedTab)
    }
}

// MARK: - Navigation Tab Button

private struct NavigationTabButton: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void

    @State private var isHovering = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: DesignTokens.Spacing.sm) {
                Image(systemName: icon)
                    .font(.system(size: DesignTokens.IconSize.sm))
                    .foregroundColor(isSelected ? DesignTokens.Colors.accentPrimary : DesignTokens.Colors.foregroundSecondary)

                Text(title)
                    .font(DesignTokens.Typography.body(weight: isSelected ? .medium : .regular))
                    .foregroundColor(isSelected ? DesignTokens.Colors.foregroundPrimary : DesignTokens.Colors.foregroundSecondary)

                Spacer()
            }
            .padding(.horizontal, DesignTokens.Spacing.md)
            .padding(.vertical, DesignTokens.Spacing.sm)
            .background(
                RoundedRectangle(cornerRadius: DesignTokens.Radius.md, style: .continuous)
                    .fill(
                        isSelected ? DesignTokens.Colors.selectedBackground :
                            (isHovering ? DesignTokens.Colors.hoverBackground : Color.clear)
                    )
            )
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            withAnimation(DesignTokens.Animation.normal) {
                isHovering = hovering
            }
        }
    }
}
