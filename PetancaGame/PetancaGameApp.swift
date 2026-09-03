import SwiftUI

@main
struct PetancaGameApp: App {
    @StateObject private var themeManager = ThemeManager()
    @StateObject private var languageManager = LanguageManager()
    @StateObject private var soundManager = SoundManager()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(themeManager)
                .environmentObject(languageManager)
                .environmentObject(soundManager)
                .preferredColorScheme(themeManager.colorScheme)
        }
    }
}
