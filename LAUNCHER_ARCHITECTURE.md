# Prompt Launcher Architecture

## Overview

The prompt launcher is a minimal, ultra-fast command palette for executing prompts. It's designed as a Raycast-style interface with zero chrome, instant search filtering, and full keyboard navigation.

## Design Philosophy

### Minimal UI Principles
- **No app metadata** - No current app section, no headers, no secondary information
- **Pure execution focus** - Only show what's needed to find and run prompts
- **Instant feedback** - Search filters in real-time, keyboard navigation is immediate
- **Zero friction** - Open → Search → Execute → Close in under 2 seconds

### Visual Style
- Lightweight command palette aesthetic
- Flat backgrounds with subtle depth
- SF Pro typography for clarity
- Minimal hover and selection states
- No heavy borders or containers

## Architecture

### Component Hierarchy

```
PromptLauncherView (Root)
├── PromptSearchBar
│   ├── Search icon
│   ├── TextField (auto-focused)
│   └── Clear button (conditional)
├── Divider (thin separator)
└── PromptList
    ├── ScrollView
    └── LazyVStack
        └── PromptRow (repeated)
            ├── Title + Subtitle
            └── Tags (hover/selected only)
```

### Data Flow

```
PromptLauncherViewModel
    ↓ (publishes)
searchText → filteredPrompts → PromptList
    ↓                              ↓
selectedIndex ←──────────────── ScrollViewReader
    ↓
PromptRow (highlight state)
```

## Components

### 1. PromptLauncherView
**Location:** `/ai-prompter/Views/Launcher/PromptLauncherView.swift`

The root view of the popover. Coordinates all child components and handles keyboard events.

**Responsibilities:**
- Auto-focus search bar on appear
- Handle keyboard navigation (↑↓ Enter Escape)
- Execute prompts and copy to clipboard
- Show notifications
- Close popover
- Open manager window (Cmd+K)

**Key Features:**
- Fixed width: 540pt
- Dynamic height: 200-600pt
- `.onKeyPress()` modifiers for keyboard handling
- Notification integration

### 2. PromptSearchBar
**Location:** `/ai-prompter/Views/Launcher/PromptSearchBar.swift`

Minimal search input with icon and clear button.

**Features:**
- Magnifying glass icon (left)
- Plain text field (no border)
- Clear button (only when text present)
- Auto-focused on appear
- 44pt fixed height

**Styling:**
- Rounded 8pt corners
- Control background color
- 15pt regular font
- Horizontal padding: 12pt

### 3. PromptList
**Location:** `/ai-prompter/Views/Launcher/PromptList.swift`

Scrollable list of prompts with auto-scrolling to selection.

**Features:**
- Lazy loading with `LazyVStack`
- Auto-scroll to selected prompt
- Empty state view
- 2pt spacing between rows

**Empty State:**
- Magnifying glass icon (32pt)
- Context-aware message
- Centered layout

### 4. PromptRow
**Location:** `/ai-prompter/Views/Launcher/PromptRow.swift`

Individual prompt row with hover and selection states.

**Layout:**
- Title (14pt semibold)
- Subtitle (12pt regular, truncated)
- Tags (10pt, only on hover/selected)
- Height: 48pt
- Horizontal padding: 12pt

**States:**
- Default: transparent
- Hover: 5% primary opacity
- Selected: 12% accent opacity
- Pressed: 18% accent opacity + 0.995 scale

**Interactions:**
- Hover shows tags
- Click executes prompt
- Smooth animations (150ms hover, 120ms selection)

### 5. PromptLauncherViewModel
**Location:** `/ai-prompter/ViewModels/PromptLauncherViewModel.swift`

State management and business logic.

**Published Properties:**
```swift
@Published var searchText: String
@Published var selectedIndex: Int
@Published private(set) var allPrompts: [PromptTemplate]
```

**Computed Properties:**
```swift
var filteredPrompts: [PromptTemplate]  // Search + fuzzy match
var promptCount: Int                    // Total filtered count
var selectedPrompt: PromptTemplate?     // Safe access to selection
```

**Key Methods:**
- `loadPrompts()` - Fetch from repository
- `refresh()` - Reload and reset selection
- `moveSelectionUp()` - Keyboard navigation
- `moveSelectionDown()` - Keyboard navigation
- `executeSelected()` - Run current prompt
- `fuzzyMatch()` - "fb" matches "FooBar"

### 6. LauncherDesignTokens
**Location:** `/ai-prompter/Design/LauncherDesignTokens.swift`

Centralized design tokens for consistency.

**Namespaces:**
- `Layout` - Dimensions, padding, spacing
- `Colors` - Semantic color palette
- `Typography` - Font definitions
- `Shadows` - Shadow presets
- `Animation` - Timing and easing
- `Interaction` - Scale factors

## Keyboard Navigation

### Key Bindings

| Key | Action |
|-----|--------|
| ↑ | Move selection up |
| ↓ | Move selection down |
| Enter | Execute selected prompt |
| Escape | Close popover |
| Cmd+K | Open manager window |
| Type | Filter prompts |

### Navigation Behavior

1. **Auto-scroll**: Selected row always visible
2. **Wrap prevention**: Can't go below 0 or above max
3. **Search reset**: Selection resets to 0 on search change
4. **Instant response**: No debounce, immediate feedback

## Search & Filtering

### Match Algorithm

The launcher uses multiple matching strategies:

1. **Exact substring** - "code" matches "Code Review"
2. **Fuzzy match** - "cr" matches "Code Review"
3. **Tag match** - "dev" matches tags: ["dev", "review"]
4. **Content match** - Search in prompt content

All matches are case-insensitive.

### Fuzzy Match Example

```
Query: "fb"
Matches: "FooBar", "File Browser", "Focus Border"
```

The algorithm steps through each character in the target string, consuming query characters in order.

## Execution Flow

### User Action: Click Prompt

```
User clicks PromptRow
    ↓
onExecute closure fires
    ↓
PromptLauncherView.executePrompt()
    ↓
1. Copy prompt.content to clipboard
2. Show notification (title + body)
3. Close popover
```

### User Action: Keyboard Enter

```
User presses Enter
    ↓
.onKeyPress(.return) handler
    ↓
viewModel.executeSelected()
    ↓
Returns selected PromptTemplate
    ↓
executePrompt() (same as click)
```

## Styling Guidelines

### Color Usage

```swift
// Background
popoverBackground: .windowBackgroundColor
searchBackground: .controlBackgroundColor

// Row states
rowHover: primary @ 5% opacity
rowSelected: accent @ 12% opacity
rowPressed: accent @ 18% opacity

// Text
primaryText: .primary (system adaptive)
secondaryText: .secondary (system adaptive)
tertiaryText: primary @ 50% opacity
```

### Typography Scale

```swift
Search: 15pt regular
Row title: 14pt semibold
Row subtitle: 12pt regular
Tags: 10pt medium
Empty state: 13pt regular
```

### Spacing System

```swift
Horizontal padding: 12pt
Vertical padding: 8pt
Search padding: 16pt
Row spacing: 2pt
Tag spacing: 6pt
```

## Integration Points

### Repository
- Uses `PromptTemplateRepository` protocol
- Default: `FilePromptTemplateRepository.shared`
- Loads prompts on appear

### App Context
- Injects `AppContextService.shared`
- Currently unused (no app filtering in launcher)
- Available for future app-aware features

### Notifications
- Uses `UNUserNotificationCenter`
- Shows "Prompt Copied" notification
- Displays prompt title in body

### Clipboard
- `NSPasteboard.general`
- Clears existing content
- Sets `.string` type

## Performance Optimizations

### Lazy Loading
- `LazyVStack` only renders visible rows
- Supports hundreds of prompts without lag

### Computed Properties
- `filteredPrompts` recalculates only on search change
- No unnecessary view updates

### Animation Budget
- Hover: 150ms
- Selection: 120ms
- Search: 200ms
- All use efficient SwiftUI animations

## Testing

### Preview Support

All components include SwiftUI previews:
- `PromptSearchBar` - Shows empty and filled states
- `PromptRow` - Shows normal, selected, and edge cases
- `PromptList` - Uses mock repository with sample data
- `PromptLauncherView` - Full launcher preview

### Mock Repository

`PromptList.swift` includes a `MockPromptRepository` for previews and testing.

## Future Enhancements

### Potential Features (Not Implemented)
- Recent prompts section
- Frequently used prompts
- App-specific filtering toggle
- Multi-select and batch execution
- Custom keyboard shortcuts per prompt
- Preview pane on right side
- Quick actions (edit, delete, duplicate)

### Performance Improvements
- Debounced search for very large lists
- Virtual scrolling for 1000+ prompts
- Index-based fuzzy matching

## Migration Guide

### From Old PromptListView

The new launcher replaces `PromptListView` in the menu bar:

**Before:**
```swift
MenuBarExtra {
    PromptListView(viewModel: promptListViewModel)
}
```

**After:**
```swift
MenuBarExtra {
    PromptLauncherView()
}
```

### Key Differences

| Old | New |
|-----|-----|
| Shows current app | No app section |
| Manage button | Cmd+K to manager |
| Section headers | Flat list |
| Hover previews | Execute on click |
| App filter buttons | Search only |
| Recent searches | Not shown |

### Preserved Features
- Clipboard copy on execute
- Notifications
- Tag display
- Prompt content

## File Structure

```
ai-prompter/
├── Design/
│   └── LauncherDesignTokens.swift
├── ViewModels/
│   └── PromptLauncherViewModel.swift
└── Views/
    └── Launcher/
        ├── PromptLauncherView.swift
        ├── PromptSearchBar.swift
        ├── PromptList.swift
        └── PromptRow.swift
```

## Dependencies

### Internal
- `PromptTemplate` model
- `PromptTemplateRepository` protocol
- `FilePromptTemplateRepository` implementation
- `AppContextService` (injected, unused)

### System Frameworks
- SwiftUI
- AppKit (`NSPasteboard`, `NSApp`)
- UserNotifications (`UNUserNotificationCenter`)

## Accessibility

### VoiceOver Support
- All buttons have implicit labels
- Text fields have placeholders
- Row selection is announced
- Empty state is readable

### Keyboard Access
- Full keyboard navigation
- No mouse required
- Focus management
- Escape to dismiss

### Dynamic Type
- Uses system fonts
- Scales with text size preferences
- Layout adapts to larger text

## Performance Metrics

### Target Benchmarks
- Open to search focus: < 100ms
- Search filtering: < 16ms (60fps)
- Keyboard navigation: < 16ms (60fps)
- Execute and close: < 200ms

### Memory
- Lazy loading prevents memory spikes
- No image caching needed
- Minimal view hierarchy

## Troubleshooting

### Search Not Working
- Check `filteredPrompts` computed property
- Verify `searchText` binding
- Ensure `allPrompts` is loaded

### Keyboard Not Responding
- Check `.onKeyPress()` handlers
- Verify focus state
- Test with `.menuBarExtraStyle(.window)`

### Selection Not Scrolling
- Check `ScrollViewReader` in `PromptList`
- Verify `.id()` modifier on rows
- Test `scrollTo()` animation

### Popover Not Closing
- Verify `NSApp.sendAction` call
- Check `NSStatusBarButton.performClick`
- Test with menu bar extra reference

## Related Files

- `ai_prompterApp.swift` - App entry point and MenuBarExtra setup
- `PromptTemplate.swift` - Data model
- `PromptTemplateRepository.swift` - Data persistence
- `AppContextService.swift` - App tracking (unused in launcher)

## Contact

For questions about the launcher architecture, refer to this document or check the inline code comments in each component file.
