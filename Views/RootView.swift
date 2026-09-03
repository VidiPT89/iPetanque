import SwiftUI

enum AppScreen {
    case splash
    case menu
    case newGame
    case game
    case settings
    case about
}

struct RootView: View {
    @State private var screen: AppScreen = .splash
    @StateObject private var gameViewModel = GameViewModel()

    var body: some View {
        ZStack {
            switch screen {
            case .splash:
                SplashView {
                    withAnimation(.easeInOut(duration: 0.5)) { screen = .menu }
                }
                .transition(.opacity)
            case .menu:
                MainMenuView(
                    onNewGame: { withAnimation { screen = .newGame } },
                    onSettings: { withAnimation { screen = .settings } },
                    onAbout: { withAnimation { screen = .about } }
                )
                .transition(.opacity)
            case .newGame:
                NewGameView(
                    onBack: { withAnimation { screen = .menu } },
                    onStart: { mode, difficulty in
                        gameViewModel.startNewGame(mode: mode, difficulty: difficulty)
                        withAnimation { screen = .game }
                    }
                )
                .transition(.move(edge: .trailing))
            case .game:
                GameView(viewModel: gameViewModel, onExit: { withAnimation { screen = .menu } })
                    .transition(.opacity)
            case .settings:
                SettingsView(onBack: { withAnimation { screen = .menu } })
                    .transition(.move(edge: .trailing))
            case .about:
                AboutView(onBack: { withAnimation { screen = .menu } })
                    .transition(.move(edge: .trailing))
            }
        }
    }
}
