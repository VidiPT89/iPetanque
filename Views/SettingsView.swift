import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var languageManager: LanguageManager
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var soundManager: SoundManager
    @AppStorage("difficulty") private var difficultyRaw = Difficulty.medium.rawValue
    var onBack: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            TopNavigationBar(showBack: true, onBack: onBack)

            Form {
                Section(languageManager.t(.language)) {
                    Picker(languageManager.t(.language), selection: Binding(
                        get: { languageManager.currentLanguage },
                        set: { languageManager.setLanguage($0) }
                    )) {
                        ForEach(AppLanguage.allCases, id: \.self) { Text($0.displayName).tag($0) }
                    }
                }

                Section(languageManager.t(.theme)) {
                    Picker(languageManager.t(.theme), selection: Binding(
                        get: { themeManager.currentTheme },
                        set: { themeManager.setTheme($0) }
                    )) {
                        Label(languageManager.t(.darkMode), systemImage: "moon.stars.fill").tag(AppTheme.dark)
                        Label(languageManager.t(.lightMode), systemImage: "sun.max.fill").tag(AppTheme.light)
                        Label(languageManager.t(.systemMode), systemImage: "circle.lefthalf.filled").tag(AppTheme.system)
                    }
                    .pickerStyle(.inline)
                }

                Section(languageManager.t(.difficulty)) {
                    Picker(languageManager.t(.difficulty), selection: $difficultyRaw) {
                        ForEach(Difficulty.allCases, id: \.self) { d in
                            Text(languageManager.t(d.titleKey)).tag(d.rawValue)
                        }
                    }
                }

                Section {
                    Toggle(languageManager.t(.sound), isOn: $soundManager.soundEnabled)
                }
            }
        }
        .background(Color(.systemBackground).ignoresSafeArea())
    }
}
