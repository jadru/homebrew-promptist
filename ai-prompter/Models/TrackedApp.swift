import Foundation

/// Known apps we want to treat specially when filtering prompts.
enum TrackedApp: String, Codable, CaseIterable, Identifiable, Hashable {
    case antigravity
    case chatGPTAtlas
    case chatGPT
    case clickUp
    case comet
    case claude
    case conductor
    case cursor
    case docker
    case figma
    case goodnotes
    case chrome
    case obsidian
    case warp
    case xcode
    case androidStudio

    var id: String { rawValue }

    /// User-facing name from its configuration.
    var displayName: String {
        TrackedAppConfig.config(for: self)?.displayName ?? rawValue
    }
}

/// Configuration describing how to map running apps to `TrackedApp` values.
struct TrackedAppConfig {
    let trackedApp: TrackedApp
    let displayName: String
    let bundleIdentifiers: [String]

    static let configs: [TrackedAppConfig] = [
        TrackedAppConfig(
            trackedApp: .antigravity,
            displayName: "Antigravity",
            bundleIdentifiers: [
                "com.google.antigravity"
            ]
        ),
        TrackedAppConfig(
            trackedApp: .chatGPTAtlas,
            displayName: "ChatGPT Atlas",
            bundleIdentifiers: [
                "com.openai.atlas"
            ]
        ),
        TrackedAppConfig(
            trackedApp: .chatGPT,
            displayName: "ChatGPT",
            bundleIdentifiers: [
                "com.openai.chat",
                "com.openai.chatgpt",
                "com.openai.chatgpt.app"
            ]
        ),
        TrackedAppConfig(
            trackedApp: .clickUp,
            displayName: "ClickUp",
            bundleIdentifiers: [
                "com.clickup.desktop-app"
            ]
        ),
        TrackedAppConfig(
            trackedApp: .comet,
            displayName: "Comet",
            bundleIdentifiers: [
                "ai.perplexity.comet"
            ]
        ),
        TrackedAppConfig(
            trackedApp: .claude,
            displayName: "Claude for Desktop",
            bundleIdentifiers: [
                "com.anthropic.claudefordecktop"
            ]
        ),
        TrackedAppConfig(
            trackedApp: .warp,
            displayName: "Warp",
            bundleIdentifiers: [
                "dev.warp.Warp-Stable",
                "dev.warp.warp-stable",
                "dev.warp.warp"
            ]
        ),
        TrackedAppConfig(
            trackedApp: .cursor,
            displayName: "Cursor",
            bundleIdentifiers: [
                "com.todesktop.230313mzl4w4u92"
            ]
        ),
        TrackedAppConfig(
            trackedApp: .conductor,
            displayName: "Conductor",
            bundleIdentifiers: [
                "com.conductor.app",
                "build.conductor.app"
            ]
        ),
        TrackedAppConfig(
            trackedApp: .docker,
            displayName: "Docker",
            bundleIdentifiers: [
                "com.docker.docker"
            ]
        ),
        TrackedAppConfig(
            trackedApp: .figma,
            displayName: "Figma",
            bundleIdentifiers: [
                "com.figma.Desktop"
            ]
        ),
        TrackedAppConfig(
            trackedApp: .goodnotes,
            displayName: "Goodnotes",
            bundleIdentifiers: [
                "com.goodnotesapp.x"
            ]
        ),
        TrackedAppConfig(
            trackedApp: .chrome,
            displayName: "Google Chrome",
            bundleIdentifiers: [
                "com.google.Chrome"
            ]
        ),
        TrackedAppConfig(
            trackedApp: .obsidian,
            displayName: "Obsidian",
            bundleIdentifiers: [
                "md.obsidian"
            ]
        ),
        TrackedAppConfig(
            trackedApp: .xcode,
            displayName: "Xcode",
            bundleIdentifiers: [
                "com.apple.dt.Xcode"
            ]
        ),
        TrackedAppConfig(
            trackedApp: .androidStudio,
            displayName: "Android Studio",
            bundleIdentifiers: [
                "com.google.android.studio"
            ]
        )
    ]

    static func config(for trackedApp: TrackedApp) -> TrackedAppConfig? {
        configs.first { $0.trackedApp == trackedApp }
    }
}
