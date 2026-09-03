import SwiftUI

enum AppTheme: String, Codable, CaseIterable {
    case dark
    case light
    case system
}

final class ThemeManager: ObservableObject {
    @AppStorage("selectedTheme") var currentTheme: AppTheme = .dark {
        didSet { objectWillChange.send() }
    }

    var colorScheme: ColorScheme? {
        switch currentTheme {
        case .dark: return .dark
        case .light: return .light
        case .system: return nil
        }
    }

    var iconName: String {
        switch currentTheme {
        case .dark: return "moon.stars.fill"
        case .light: return "sun.max.fill"
        case .system: return "circle.lefthalf.filled"
        }
    }

    func setTheme(_ theme: AppTheme) {
        currentTheme = theme
    }
}
