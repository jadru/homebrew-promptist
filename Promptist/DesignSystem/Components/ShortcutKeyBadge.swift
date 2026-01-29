import SwiftUI

/// Displays a keyboard shortcut combination (e.g., "⌘⌥P") in a capsule badge.
struct ShortcutKeyBadge: View {
    let keyCombo: KeyCombo

    var body: some View {
        Text(keyCombo.displayString)
            .font(.system(size: 11, weight: .medium, design: .rounded))
            .foregroundColor(DesignTokens.Colors.foregroundSecondary)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(
                Capsule()
                    .fill(DesignTokens.Colors.backgroundTertiary)
            )
            .liquidGlass(.clear)
    }
}

#Preview {
    HStack(spacing: 8) {
        ShortcutKeyBadge(keyCombo: KeyCombo(modifiers: [.command, .option], key: "P"))
        ShortcutKeyBadge(keyCombo: KeyCombo(modifiers: [.command, .shift], key: "N"))
        ShortcutKeyBadge(keyCombo: KeyCombo(modifiers: [.control, .option, .command], key: "T"))
    }
    .padding()
}
