import SwiftUI

enum AppLanguage: String, Codable, CaseIterable {
    case portuguese = "pt-PT"
    case english = "en"

    var displayName: String {
        switch self {
        case .portuguese: return "Português"
        case .english: return "English"
        }
    }
}

final class LanguageManager: ObservableObject {
    @AppStorage("selectedLanguage") var currentLanguage: AppLanguage = .portuguese {
        didSet { objectWillChange.send() }
    }

    func setLanguage(_ language: AppLanguage) {
        currentLanguage = language
    }

    /// Resolves a localized string for the active language.
    func t(_ key: L10nKey) -> String {
        L10n.string(key, language: currentLanguage)
    }
}
