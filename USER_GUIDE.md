# Prompt Launcher User Guide

## Quick Start

The new prompt launcher is a minimal, ultra-fast command palette for finding and executing your prompts.

### Opening the Launcher

Click the menu bar icon to open the launcher popover.

```
┌─────────────────────────────────┐
│ 🔍 [Search prompts...]  [×] [⚙]│ ← Search + Manage button
├─────────────────────────────────┤
│ Code Review                     │ ← Your prompts
│ Please review this code...      │
├─────────────────────────────────┤
│ Debug This                      │
│ Help me debug this issue...     │
├─────────────────────────────────┤
│ Write Tests                     │
│ Write comprehensive unit...     │
└─────────────────────────────────┘
```

## Using the Launcher

### 1. Search for Prompts

Start typing to filter prompts instantly:

**Example:** Type "code"
```
┌─────────────────────────────────┐
│ 🔍 [code]                   [×]  │
├─────────────────────────────────┤
│ Code Review                     │ ← Matches "code" in title
│ Please review this code...      │
├─────────────────────────────────┤
│ Explain Code                    │ ← Also matches "code"
│ Explain how this code works...  │
└─────────────────────────────────┘
```

### 2. Fuzzy Search

Don't remember the exact name? Use fuzzy search:

**Example:** Type "cr" to find "Code Review"
```
┌─────────────────────────────────┐
│ 🔍 [cr]                     [×]  │
├─────────────────────────────────┤
│ Code Review                     │ ← "cr" matches "Code Review"
│ Please review this code...      │
└─────────────────────────────────┘
```

The fuzzy matcher steps through each character:
- "c" → **C**ode
- "r" → **R**eview

### 3. Search by Tags

Type a tag name to find all prompts with that tag:

**Example:** Type "debug"
```
┌─────────────────────────────────┐
│ 🔍 [debug]                  [×]  │
├─────────────────────────────────┤
│ Debug This                      │ ← Has tag: "debug"
│ Help me debug this issue...     │
├─────────────────────────────────┤
│ Bug Hunt                        │ ← Also has tag: "debug"
│ Review the code snippet...      │
└─────────────────────────────────┘
```

### 4. Keyboard Navigation

Use arrow keys to navigate, Enter to execute:

```
┌─────────────────────────────────┐
│ 🔍 [Search prompts...]          │
├─────────────────────────────────┤
│ Code Review                     │ ← Press ↓
│ Please review this code...      │
├─────────────────────────────────┤
│ Debug This                      │ ← Selected (highlighted)
│ Help me debug this issue...     │   Press Enter to execute
├─────────────────────────────────┤
│ Write Tests                     │ ← Press ↓ again
│ Write comprehensive unit...     │
└─────────────────────────────────┘
```

**Keyboard Shortcuts:**

| Key | Action |
|-----|--------|
| ↑ | Move selection up |
| ↓ | Move selection down |
| Enter | Execute selected prompt |
| Escape | Close launcher |
| Type | Start searching |

### 5. Hover States

Hover over a prompt to see its tags:

```
┌─────────────────────────────────┐
│ 🔍 [Search prompts...]          │
├─────────────────────────────────┤
│ Code Review          [dev] [re…]│ ← Tags appear on hover
│ Please review this code...      │
└─────────────────────────────────┘
```

### 6. Execute a Prompt

Click a prompt or press Enter to execute:

1. Prompt content copied to clipboard ✓
2. Notification appears ✓
3. Launcher closes ✓

**Example Notification:**
```
┌──────────────────────────┐
│ Prompt Copied            │
│ Code Review              │
└──────────────────────────┘
```

## Features

### Empty State

When no prompts match your search:

```
┌─────────────────────────────────┐
│ 🔍 [xyz]                    [×]  │
├─────────────────────────────────┤
│                                 │
│         🔍                       │
│                                 │
│   No prompts match "xyz"        │
│                                 │
└─────────────────────────────────┘
```

### Clear Search

Click the [×] button to clear your search:

```
┌─────────────────────────────────┐
│ 🔍 [code review]        [×] [⚙]│ ← Click [×] to clear
├─────────────────────────────────┤
```

### Manage Button

Click the [⚙] button to open the manager window:

```
┌─────────────────────────────────┐
│ 🔍 [Search prompts...]  [×] [⚙]│ ← Click [⚙] to manage
├─────────────────────────────────┤
```

This opens the full manager window where you can:
- Create new prompts
- Edit existing prompts
- Delete prompts
- Organize with tags
- Link prompts to apps

### Auto-Scroll

The launcher automatically scrolls to keep the selected prompt visible:

```
[Visible area]
│ Prompt 8                        │
│ Prompt 9  ← Selected            │ ← Auto-scrolls here
│ Prompt 10                       │
[...]
```

## Managing Prompts

The launcher focuses on **finding and executing** prompts. To create, edit, or delete prompts:

### Open Manager Window

**Option 1:** Click the [⚙] button in the launcher (top-right)
**Option 2:** Click and hold the menu bar icon
**Option 3:** Use the "Manage Prompts" menu item

The manager window provides:
- Create new prompts
- Edit existing prompts
- Delete prompts
- Organize with tags
- Link to apps
- Reorder prompts

## Tips & Tricks

### 1. Fast Workflow

```
1. Click menu bar icon (or use hotkey)
2. Type 2-3 characters
3. Press Enter
4. Paste into target app
```

Total time: ~2 seconds

### 2. Memorable Shortcuts

Create prompts with unique starting letters:
- "Debug" → Type "d" + Enter
- "Explain" → Type "e" + Enter
- "Review" → Type "r" + Enter

### 3. Use Tags for Organization

Common tag patterns:
- By language: "swift", "python", "js"
- By type: "review", "debug", "explain"
- By app: "xcode", "cursor", "chatgpt"

Search by tag to find related prompts quickly.

### 4. Fuzzy Search Patterns

Learn these patterns for faster searching:

| Query | Matches |
|-------|---------|
| "cr" | **C**ode **R**eview |
| "db" | **D**e**b**ug |
| "wt" | **W**rite **T**ests |
| "exp" | **Exp**lain |

### 5. Content Search

Can't remember the title? Search for words in the prompt content:

**Example:** Type "best practices" to find prompts that mention it.

## Common Questions

### Q: How do I create a new prompt?
**A:** Open the manager window (click and hold menu bar icon). The launcher is execution-only.

### Q: Can I edit prompts from the launcher?
**A:** No, use the manager window. The launcher focuses on speed and finding prompts.

### Q: How do I delete a prompt?
**A:** Open the manager window and delete from there.

### Q: Why don't I see app filters?
**A:** The new launcher is search-first. Type the app name (e.g., "xcode") to filter.

### Q: Can I change the launcher size?
**A:** Not currently. It's fixed at 540pt wide, 200-600pt tall (dynamic).

### Q: Where are my prompts stored?
**A:** `~/Library/Application Support/ai-prompter/templates.json`

### Q: Will my old prompts work?
**A:** Yes! All existing prompts are preserved and work identically.

## Troubleshooting

### Launcher Won't Open
- Check if the app is running (menu bar icon visible)
- Try clicking the icon again
- Restart the app if needed

### Search Not Working
- Make sure the search bar is focused (it auto-focuses on open)
- Try clicking in the search field
- Check for typos

### No Prompts Showing
- Click the [×] button to clear any search filters
- Open manager window to verify prompts exist
- Check `templates.json` file exists

### Keyboard Navigation Not Working
- Click inside the launcher to ensure it has focus
- Try using mouse to verify prompts are selectable
- Close and reopen the launcher

### Clipboard Not Working
- Check system clipboard permissions
- Try manually copying text to test clipboard
- Restart the app if needed

## Keyboard Shortcuts Summary

### In Launcher
| Shortcut | Action |
|----------|--------|
| ↑ | Previous prompt |
| ↓ | Next prompt |
| Enter | Execute selected |
| Escape | Close launcher |
| Any letter | Start searching |

### Global (macOS)
| Shortcut | Action |
|----------|--------|
| Cmd+V | Paste copied prompt |
| Cmd+Tab | Switch to target app |

## Best Practices

1. **Keep titles short and descriptive**
   - Good: "Code Review"
   - Bad: "Please review this code for me and check for bugs"

2. **Use consistent tag naming**
   - Lowercase: "debug" not "Debug"
   - Short: "py" not "python-related"

3. **Create unique acronyms**
   - Make titles work with fuzzy search
   - Example: "Fix Bug" (fb), "Write Tests" (wt)

4. **Organize by frequency**
   - Put most-used prompts in the manager
   - Sort order affects launcher display

5. **Clean up unused prompts**
   - Archive or delete prompts you don't use
   - Keep the list focused and fast

## What's New vs Old UI

### Removed Features
- Current app section
- App filter buttons (ChatGPT, Warp, etc.)
- Section headers ("Templates for X")
- Recent searches row
- Manage button in popover
- Hover preview popovers
- Edit/delete icons in rows

### New Features
- Fuzzy search matching
- Full keyboard navigation
- Auto-scroll to selection
- Instant search (no delay)
- Minimal, focused UI
- Faster execution flow

### Preserved Features
- Search by title/content/tags
- Clipboard copy on execute
- Notifications
- Tag display (on hover)
- Manager window access

## Feedback

If you encounter issues or have suggestions:
1. Check this guide first
2. Try the troubleshooting section
3. Report bugs via GitHub issues

---

**Need more help?**
- See `LAUNCHER_ARCHITECTURE.md` for technical details
- See `LAUNCHER_SUMMARY.md` for design decisions
- See `IMPLEMENTATION_COMPLETE.md` for build info
