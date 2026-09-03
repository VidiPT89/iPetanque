import SwiftUI

struct ScoreBoardView: View {
    @EnvironmentObject var languageManager: LanguageManager
    @ObservedObject var viewModel: GameViewModel

    var body: some View {
        HStack(spacing: 0) {
            scoreBlock(team: .teamA, score: viewModel.teamAScore)
            Rectangle()
                .fill(Color.white.opacity(0.2))
                .frame(width: 1, height: 34)
            scoreBlock(team: .teamB, score: viewModel.teamBScore)
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 18)
        .background(.ultraThinMaterial, in: Capsule())
        .shadow(color: .black.opacity(0.15), radius: 10, y: 4)
    }

    private func scoreBlock(team: Team, score: Int) -> some View {
        VStack(spacing: 2) {
            Text(languageManager.t(team.nameKey))
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.secondary)
            Text("\(score)")
                .font(.system(size: 26, weight: .heavy, design: .rounded))
                .foregroundColor(viewModel.currentTeam == team ? Color("PrimaryOrange") : .primary)
                .contentTransition(.numericText())
                .animation(.spring(response: 0.4), value: score)
        }
        .frame(width: 90)
    }
}
