import SwiftUI

struct LanguagePickerView: View {
    @AppStorage("app_language") private var appLanguage: String = "es"
    @State private var showRestartAlert = false

    private let languages: [(code: String, name: String, flag: String)] = [
        ("es", "Español", "🇪🇸"),
        ("en", "English", "🇺🇸")
    ]

    var body: some View {
        List {
            Section {
                ForEach(languages, id: \.code) { language in
                    Button {
                        guard appLanguage != language.code else { return }
                        appLanguage = language.code
                        UserDefaults.standard.set([language.code], forKey: "AppleLanguages")
                        UserDefaults.standard.synchronize()
                        showRestartAlert = true
                    } label: {
                        HStack(spacing: 12) {
                            Text(language.flag)
                                .font(.title2)

                            Text(language.name)
                                .foregroundStyle(.primary)

                            Spacer()

                            if appLanguage == language.code {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(.nnPrimary)
                                    .fontWeight(.semibold)
                            }
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            } header: {
                Text(L10n.settingsLanguage)
            }

            Section {
                Label {
                    Text(String(localized: "language.restartNote"))
                } icon: {
                    Image(systemName: "info.circle")
                        .foregroundStyle(.secondary)
                }
                .font(.footnote)
                .foregroundStyle(.secondary)
            }
        }
        .navigationTitle(L10n.settingsLanguage)
        .navigationBarTitleDisplayMode(.inline)
        .alert(
            String(localized: "language.restartTitle"),
            isPresented: $showRestartAlert
        ) {
            Button(L10n.commonAccept) {
                // Force the app to exit so the language change takes effect on next launch
                exit(0)
            }
            Button(L10n.commonCancel, role: .cancel) {}
        } message: {
            Text(String(localized: "language.restartMessage"))
        }
    }
}

// MARK: - Localized strings for this view only (added to xcstrings separately)

private extension String {
    // These keys should be added to Localizable.xcstrings:
    // "language.restartNote"
    //   es: "La app necesita reiniciarse para aplicar el cambio de idioma."
    //   en: "The app needs to restart to apply the language change."
    //
    // "language.restartTitle"
    //   es: "Reiniciar app"
    //   en: "Restart app"
    //
    // "language.restartMessage"
    //   es: "La app se cerrará para aplicar el nuevo idioma. Ábrela de nuevo para continuar."
    //   en: "The app will close to apply the new language. Open it again to continue."
}

#Preview {
    NavigationStack {
        LanguagePickerView()
    }
}
