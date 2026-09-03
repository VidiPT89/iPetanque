import SwiftUI

@main
struct iPetanqueApp: App {
    @StateObject private var themeManager = ThemeManager()
    @StateObject private var languageManager = LanguageManager()
    @StateObject private var soundManager = SoundManager()
    @StateObject private var statsManager = StatsManager()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(themeManager)
                .environmentObject(languageManager)
                .environmentObject(soundManager)
                .environmentObject(statsManager)
                .preferredColorScheme(themeManager.colorScheme)
        }
    }
}
