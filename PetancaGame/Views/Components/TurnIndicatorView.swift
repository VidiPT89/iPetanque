import SwiftUI

struct TurnIndicatorView: View {
    @EnvironmentObject var languageManager: LanguageManager
    @ObservedObject var viewModel: GameViewModel
    @State private var pulse = false

    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(viewModel.currentTeam.isHuman ? Color("PrimaryOrange") : Color("BurntYellow"))
                .frame(width: 9, height: 9)
                .scaleEffect(pulse ? 1.4 : 1.0)
                .opacity(pulse ? 0.4 : 1.0)
                .animation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true), value: pulse)

            Text(label)
                .font(.system(size: 14, weight: .semibold, design: .rounded))

            if viewModel.isAiThinking {
                ProgressView().scaleEffect(0.7)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(.ultraThinMaterial, in: Capsule())
        .onAppear { pulse = true }
    }

    private var label: String {
        viewModel.currentTeam.isHuman ? languageManager.t(.yourTurn) : languageManager.t(.opponentTurn)
    }
}
