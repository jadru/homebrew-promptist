//
//  GroupEditorView.swift
//  ai-prompter
//
//  Simple group name editor
//

import SwiftUI

struct GroupEditorView: View {
    @Binding var groupName: String
    let isEditing: Bool
    let onCreate: () -> Void
    let onCancel: () -> Void

    var body: some View {
        VStack(spacing: DesignTokens.Spacing.lg) {
            Text(isEditing ? "Rename Group" : "Create Group")
                .font(DesignTokens.Typography.headline(18))
                .foregroundColor(DesignTokens.Colors.foregroundPrimary)

            TextField("Group Name", text: $groupName)
                .textFieldStyle(.roundedBorder)
                .font(DesignTokens.Typography.body())

            HStack(spacing: DesignTokens.Spacing.md) {
                Button("Cancel") {
                    onCancel()
                }
                .buttonStyle(.plain)
                .foregroundColor(DesignTokens.Colors.foregroundSecondary)

                Button(isEditing ? "Save" : "Create") {
                    onCreate()
                }
                .buttonStyle(.borderedProminent)
                .disabled(groupName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .padding(DesignTokens.Spacing.lg)
        .frame(width: 400)
        .background(DesignTokens.Colors.backgroundPrimary)
    }
}
