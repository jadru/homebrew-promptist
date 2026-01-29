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
        VStack(spacing: 20) {
            Text(isEditing ? languageSettings.localized("collection.rename") : languageSettings.localized("collection.create"))
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(.primary)

            TextField(languageSettings.localized("collection.name_placeholder"), text: $collectionName)
                .textFieldStyle(.roundedBorder)
                .font(.system(size: 14))

            HStack(spacing: 12) {
                Button(languageSettings.localized("button.cancel")) {
                    onCancel()
                }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)

                Button(isEditing ? languageSettings.localized("button.save") : languageSettings.localized("collection.create_button")) {
                    onCreate()
                }
                .buttonStyle(.borderedProminent)
                .disabled(collectionName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .padding(20)
        .frame(width: 400)
    }
}
