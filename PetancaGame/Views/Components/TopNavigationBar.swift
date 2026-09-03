import SwiftUI

struct TopNavigationBar: View {
    @EnvironmentObject var languageManager: LanguageManager
    @EnvironmentObject var themeManager: ThemeManager
    var showBack: Bool = false
    var onBack: (() -> Void)? = nil

    var body: some View {
        HStack(spacing: 12) {
            if showBack {
                Button(action: { onBack?() }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 17, weight: .semibold))
                }
            }

            Text(languageManager.t(.appName))
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundStyle(
                    LinearGradient(colors: [Color("PrimaryOrange"), Color("BurntYellow")],
                                   startPoint: .leading, endPoint: .trailing)
                )

            Spacer()

            Menu {
                ForEach(AppLanguage.allCases, id: \.self) { lang in
                    Button(lang.displayName) { languageManager.setLanguage(lang) }
                }
            } label: {
                Image(systemName: "globe")
                    .imageScale(.medium)
            }

            Menu {
                Button {
                    themeManager.setTheme(.dark)
                } label: { Label(languageManager.t(.darkMode), systemImage: "moon.stars.fill") }
                Button {
                    themeManager.setTheme(.light)
                } label: { Label(languageManager.t(.lightMode), systemImage: "sun.max.fill") }
                Button {
                    themeManager.setTheme(.system)
                } label: { Label(languageManager.t(.systemMode), systemImage: "circle.lefthalf.filled") }
            } label: {
                Image(systemName: themeManager.iconName)
                    .imageScale(.medium)
            }
        }
        .foregroundColor(.primary)
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial)
    }
}
