import SwiftUI

/// Simple settings surface that lets the user override the app language.
struct SettingsView: View {
    @EnvironmentObject private var languageSettings: LanguageSettings

    var body: some View {
        Form {
            Section(header: Text("settings.language.title")) {
                Picker("settings.language.title", selection: $languageSettings.selectedLanguage) {
                    ForEach(AppLanguage.allCases) { language in
                        Text(language.labelKey)
                            .tag(language)
                    }
                }
                .pickerStyle(.segmented)

                Text("settings.language.subtitle")
                    .font(.footnote)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .frame(minWidth: 420)
    }
}

#Preview {
    SettingsView()
        .environmentObject(LanguageSettings())
}
