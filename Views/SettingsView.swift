import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var languageManager: LanguageManager
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var soundManager: SoundManager
    @EnvironmentObject var statsManager: StatsManager
    @AppStorage("difficulty") private var difficultyRaw = Difficulty.medium.rawValue
    @AppStorage("ballAccent") private var ballAccentRaw = BallAccent.silver.rawValue
    @State private var showResetConfirm = false
    var onBack: () -> Void

    private var selectedAccent: Binding<BallAccent> {
        Binding(
            get: { BallAccent(rawValue: ballAccentRaw) ?? .silver },
            set: { ballAccentRaw = $0.rawValue }
        )
    }

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

                Section(languageManager.t(.ballColor)) {
                    Picker(languageManager.t(.ballColor), selection: selectedAccent) {
                        ForEach(BallAccent.allCases) { accent in
                            HStack {
                                Circle()
                                    .fill(accentSwiftUIColor(accent))
                                    .frame(width: 16, height: 16)
                                Text(accentLabel(accent))
                            }
                            .tag(accent)
                        }
                    }
                    .pickerStyle(.inline)
                }

                Section {
                    Toggle(languageManager.t(.sound), isOn: $soundManager.soundEnabled)
                }

                Section {
                    Button(role: .destructive) {
                        showResetConfirm = true
                    } label: {
                        Text(languageManager.t(.resetStats))
                    }
                }
            }
        }
        .background(Color(.systemBackground).ignoresSafeArea())
        .alert(languageManager.t(.resetStats), isPresented: $showResetConfirm) {
            Button(languageManager.t(.cancel), role: .cancel) {}
            Button(languageManager.t(.resetStats), role: .destructive) {
                statsManager.resetAll()
            }
        } message: {
            Text(languageManager.t(.resetStatsConfirm))
        }
    }

    private func accentSwiftUIColor(_ accent: BallAccent) -> Color {
        guard let tint = accent.tint else { return Color(white: 0.8) }
        return Color(red: tint.0, green: tint.1, blue: tint.2)
    }

    private func accentLabel(_ accent: BallAccent) -> String {
        switch accent {
        case .silver: return languageManager.currentLanguage == .portuguese ? "Prateado" : "Silver"
        case .orange: return languageManager.currentLanguage == .portuguese ? "Laranja" : "Orange"
        case .blue: return languageManager.currentLanguage == .portuguese ? "Azul" : "Blue"
        case .red: return languageManager.currentLanguage == .portuguese ? "Vermelho" : "Red"
        }
    }
}
