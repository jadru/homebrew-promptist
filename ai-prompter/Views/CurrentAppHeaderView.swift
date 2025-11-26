import SwiftUI

/// Demonstrates how to present the current tracked app in the popover header.
struct CurrentAppHeaderView: View {
    @EnvironmentObject private var appContext: AppContextService
    @EnvironmentObject private var languageSettings: LanguageSettings
    var onNewPrompt: (() -> Void)?

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 10) {
            Image(systemName: "app.badge.fill")
                .imageScale(.medium)
                .foregroundStyle(.secondary)

            VStack(alignment: .leading, spacing: 2) {
                Text(appLabel)
                    .font(.system(size: 15, weight: .semibold))
                    .lineLimit(1)

                if let bundle = appContext.frontmostBundleIdentifier {
                    Text(bundle)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }

            Spacer()

            if let onNewPrompt {
                Button(action: onNewPrompt) {
                    Label("New", systemImage: "plus")
                        .labelStyle(.titleAndIcon)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
            }
        }
        .padding(.vertical, 4)
    }

    private var appLabel: String {
        if let tracked = appContext.currentTrackedApp {
            return tracked.displayName
        }
        return appContext.frontmostAppName ?? String(localized: "current_app_header.unknown", locale: languageSettings.locale)
    }
}

#Preview {
    let context = AppContextService()
    context.frontmostAppName = "Preview App"
    context.frontmostBundleIdentifier = "com.example.preview"
    context.currentTrackedApp = .chatGPT
    return CurrentAppHeaderView()
        .environmentObject(context)
        .environmentObject(LanguageSettings())
        .padding()
}
