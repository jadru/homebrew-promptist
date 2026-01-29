import SwiftUI

// MARK: - Manage Toolbar

struct ManageToolbar: View {
    @Binding var searchText: String
    @Binding var isCompactMode: Bool
    let onNewPrompt: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            SearchBar(text: $searchText, placeholder: "Search prompts...") {}
                .frame(maxWidth: 400)

            Spacer()

            // Density toggle
            Button(action: {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isCompactMode.toggle()
                }
            }) {
                Image(systemName: isCompactMode ? "square.grid.2x2" : "square.grid.2x2.fill")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.secondary)
                    .frame(width: 28, height: 28)
            }
            .buttonStyle(.plain)
            .help(isCompactMode ? "Normal Density" : "Compact Density")

            ActionButton("New Prompt", icon: "plus", variant: .primary, action: onNewPrompt)
        }
        .padding(12)
        .navigationBackground()
    }
}
