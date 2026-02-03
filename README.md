# Promptist

A native macOS menu bar app for managing and instantly launching AI prompt templates.

Save your frequently used prompts for ChatGPT, Claude, Cursor, and other AI apps, then copy them to the clipboard with a single shortcut.

> **[한국어 문서는 여기를 참조하세요.](docs/README.ko.md)**

## Installation

### Homebrew (Recommended)

```bash
brew tap jadru/promptist
brew install --cask promptist
```

### Direct Download

Download the latest DMG from [GitHub Releases](https://github.com/jadru/homebrew-promptist/releases).

## Requirements

- macOS 15.0 (Sequoia) or later
- Supports macOS 26 (Tahoe) Liquid Glass design

## Features

### Menu Bar Launcher

Click the menu bar icon to open a Raycast-style command palette. It supports search, keyboard navigation, and a preview panel. Select a prompt and it's instantly copied to your clipboard.

### App-Specific Prompts

Link prompt templates to specific apps. Promptist auto-detects the frontmost app and prioritizes linked prompts.

Supported apps:
- **AI**: ChatGPT, Claude for Desktop, Comet (Perplexity), ChatGPT Atlas
- **Development**: Cursor, Xcode, Android Studio, Warp, Docker
- **Productivity**: Conductor, ClickUp, Obsidian, Goodnotes, Figma, Google Chrome
- You can also add any custom app

### Template Variables

Insert variables into your prompt body. They are automatically resolved at execution time.

| Variable | Description |
|----------|-------------|
| `{{selection}}` | Selected text from the current app (via Accessibility API) |
| `{{clipboard}}` | Pick from clipboard history |
| `{{date}}` | Today's date |
| `{{time}}` | Current time |
| `{{datetime}}` | Date and time |
| `{{input:question}}` | Prompts the user for input at execution time |

Example:

```
Review the following code. Analyze it for bugs, performance, and readability.

{{selection}}
```

### Global Keyboard Shortcuts

Assign a keyboard shortcut to any prompt. Press the shortcut from any app to copy the prompt to your clipboard.

- **Global shortcuts**: Work across all apps
- **App-specific shortcuts**: Only trigger in a designated app (the same key combo can map to different prompts per app)

> Global shortcuts require **Accessibility permission**. A guided onboarding flow walks you through granting it on first launch.

### Collections & Categories

Organize prompts into collections or browse by built-in categories.

Default categories:
- **Coding** — Code Review, Debugging, Refactoring, Testing, Explain Code, Generate Code, Documentation
- **Writing & Communication** — Rewrite/Polish, Formal Writing, Creative Writing, Email, Translation, Summarization
- **Productivity** — Task Automation, Meeting Notes, Brainstorming, Planning, Decision Support
- **Research & Analysis** — Information Extraction, Comparison, Market/Topic Research, Critical Review
- **Image / Media Generation** — Image, Video, Audio
- **General Utilities** — General Q&A, Quick Commands, Daily Tools

### More

- Launch at login
- Dark / Light / System appearance
- Auto-sort by usage frequency
- Recent prompts section
- English & Korean localization

## Permissions

Promptist requires the following permission:

- **Accessibility**: Needed for global shortcut detection and grabbing selected text via the `{{selection}}` variable

To grant permission:
1. System Settings > Privacy & Security > Accessibility
2. Find **Promptist** in the list and enable it
3. Restart the app

## Building from Source

```bash
git clone https://github.com/jadru/homebrew-promptist.git
cd homebrew-promptist
open Promptist.xcodeproj
```

Select the `Promptist` scheme in Xcode and build. The project has zero external dependencies — it's built entirely with Swift and SwiftUI.

### Release Build

```bash
./scripts/release.sh
```

This produces a DMG and ZIP in `build/release/`.

## CI/CD

When changes under `Promptist/` are pushed to the `main` branch, GitHub Actions automatically:

1. Extracts the version from the Xcode project
2. Builds a Release archive
3. Creates a DMG
4. Publishes a GitHub Release
5. Updates the Homebrew Cask formula

## Uninstalling

### Homebrew

```bash
brew uninstall --cask promptist
```

### Manual

Delete the app, then remove:

```
~/Library/Preferences/com.jadru.promptist.plist
~/Library/Application Support/Promptist
```

## License

Copyright 2025 Younggun Park

Licensed under the [Apache License 2.0](LICENSE). You are free to use, modify, and distribute this software, including for commercial purposes. The license includes a patent grant from contributors. See the [LICENSE](LICENSE) file for full details.
