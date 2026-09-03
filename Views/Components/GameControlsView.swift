import SwiftUI

struct GameControlsView: View {
    @EnvironmentObject var languageManager: LanguageManager
    @ObservedObject var viewModel: GameViewModel

    var body: some View {
        HStack(spacing: 16) {
            controlButton(icon: "arrow.uturn.backward", title: languageManager.t(.undo)) {
                viewModel.undoLastMove()
            }
            .opacity(viewModel.canUndo ? 1 : 0.35)
            .disabled(!viewModel.canUndo)

            controlButton(icon: "ruler", title: languageManager.t(.measureDistance)) {
                viewModel.measureClosest()
            }
            .disabled(viewModel.cochonnet == nil)

            Spacer()

            Text(viewModel.measurement ?? hint)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(viewModel.measurement != nil ? Color("PrimaryOrange") : .secondary)
                .animation(.easeInOut(duration: 0.2), value: viewModel.measurement)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }

    private var hint: String {
        let isPlayerThrow = viewModel.isHumanControlled(viewModel.currentTeam)
            && (viewModel.phase == .throwCochonnet || viewModel.phase == .throwBall)
        return isPlayerThrow ? languageManager.t(.dragToAim) : ""
    }

    private func controlButton(icon: String, title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 2) {
                Image(systemName: icon).font(.system(size: 15, weight: .semibold))
                Text(title).font(.system(size: 10, weight: .medium))
            }
            .foregroundColor(.primary)
        }
    }
}
