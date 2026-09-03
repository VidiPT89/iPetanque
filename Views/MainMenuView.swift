import SwiftUI

struct MainMenuView: View {
    @EnvironmentObject var languageManager: LanguageManager
    @EnvironmentObject var themeManager: ThemeManager
    var onNewGame: () -> Void
    var onSettings: () -> Void
    var onAbout: () -> Void

    @State private var appeared = false

    var body: some View {
        VStack(spacing: 0) {
            TopNavigationBar()

            Spacer()

            VStack(spacing: 8) {
                Circle()
                    .fill(RadialGradient(colors: [.white, Color("MediumGray")], center: .topLeading, startRadius: 2, endRadius: 70))
                    .frame(width: 100, height: 100)
                    .shadow(color: Color("PrimaryOrange").opacity(0.35), radius: 16, y: 8)

                Text(languageManager.t(.appName))
                    .font(.system(size: 44, weight: .heavy, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(colors: [Color("PrimaryOrange"), Color("BurntYellow")], startPoint: .leading, endPoint: .trailing)
                    )
            }
            .scaleEffect(appeared ? 1 : 0.85)
            .opacity(appeared ? 1 : 0)

            Spacer()

            VStack(spacing: 14) {
                MainMenuButton(title: languageManager.t(.newGame), icon: "play.fill", isPrimary: true, identifier: "menu.newGame", action: onNewGame)
                MainMenuButton(title: languageManager.t(.settings), icon: "gearshape.fill", identifier: "menu.settings", action: onSettings)
                MainMenuButton(title: languageManager.t(.about), icon: "info.circle.fill", identifier: "menu.about", action: onAbout)
            }
            .padding(.horizontal, 32)
            .offset(y: appeared ? 0 : 24)
            .opacity(appeared ? 1 : 0)

            Spacer()

            VStack(spacing: 6) {
                Text("\(languageManager.t(.developedBy)) David Arsénio Martins")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)
                HStack(spacing: 18) {
                    Link("ividi.dev", destination: URL(string: "https://ividi.dev/")!)
                    Link("GitHub", destination: URL(string: "https://github.com/VidiPT89/")!)
                }
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(Color("PrimaryOrange"))
            }
            .padding(.bottom, 24)
        }
        .background(Color(.systemBackground).ignoresSafeArea())
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.75)) {
                appeared = true
            }
        }
    }
}
