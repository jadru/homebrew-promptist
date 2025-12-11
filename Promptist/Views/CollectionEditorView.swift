//
//  CollectionEditorView.swift
//  Promptist
//
//  Simple collection name editor
//

import SwiftUI

struct CollectionEditorView: View {
    @Binding var collectionName: String
    let isEditing: Bool
    let onCreate: () -> Void
    let onCancel: () -> Void

    @EnvironmentObject private var languageSettings: LanguageSettings

    var body: some View {
        VStack(spacing: DesignTokens.Spacing.lg) {
            Text(isEditing ? languageSettings.localized("collection.rename") : languageSettings.localized("collection.create"))
                .font(DesignTokens.Typography.headline(18))
                .foregroundColor(DesignTokens.Colors.foregroundPrimary)

            TextField(languageSettings.localized("collection.name_placeholder"), text: $collectionName)
                .textFieldStyle(.roundedBorder)
                .font(DesignTokens.Typography.body())

            HStack(spacing: DesignTokens.Spacing.md) {
                Button(languageSettings.localized("button.cancel")) {
                    onCancel()
                }
                .buttonStyle(.plain)
                .foregroundColor(DesignTokens.Colors.foregroundSecondary)

                Button(isEditing ? languageSettings.localized("button.save") : languageSettings.localized("collection.create_button")) {
                    onCreate()
                }
                .buttonStyle(.borderedProminent)
                .disabled(collectionName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .padding(DesignTokens.Spacing.lg)
        .frame(width: 400)
        .background(DesignTokens.Colors.backgroundPrimary)
    }
}
