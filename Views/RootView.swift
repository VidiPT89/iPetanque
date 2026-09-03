import SwiftUI

enum AppScreen {
    case splash
    case menu
    case newGame
    case game
    case settings
    case about
    case achievements
    case statistics
}

struct RootView: View {
    @EnvironmentObject var statsManager: StatsManager
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
                    onAbout: { withAnimation { screen = .about } },
                    onAchievements: { withAnimation { screen = .achievements } },
                    onStatistics: { withAnimation { screen = .statistics } }
                )
                .transition(.opacity)
            case .newGame:
                NewGameView(
                    onBack: { withAnimation { screen = .menu } },
                    onStart: { mode, difficulty, targetScore, terrain, matchType in
                        gameViewModel.startNewGame(mode: mode, difficulty: difficulty, targetScore: targetScore, terrain: terrain, matchType: matchType)
                        withAnimation { screen = .game }
                    }
                )
                .transition(.move(edge: .trailing))
            case .game:
                GameView(viewModel: gameViewModel, onExit: { withAnimation { screen = .menu } })
                    .environmentObject(statsManager)
                    .onAppear { gameViewModel.statsManager = statsManager }
                    .transition(.opacity)
            case .settings:
                SettingsView(onBack: { withAnimation { screen = .menu } })
                    .transition(.move(edge: .trailing))
            case .about:
                AboutView(onBack: { withAnimation { screen = .menu } })
                    .transition(.move(edge: .trailing))
            case .achievements:
                AchievementsView(onBack: { withAnimation { screen = .menu } })
                    .transition(.move(edge: .trailing))
            case .statistics:
                StatisticsView(onBack: { withAnimation { screen = .menu } })
                    .transition(.move(edge: .trailing))
            }
        }
    }
}
