import SwiftUI

struct GameControlsView: View {
    @EnvironmentObject var languageManager: LanguageManager
    @ObservedObject var viewModel: GameViewModel

    var body: some View {
        HStack(spacing: 16) {
            controlButton(icon: "arrow.uturn.backward", title: languageManager.t(.undo)) {}
            controlButton(icon: "ruler", title: languageManager.t(.measureDistance)) {}
            Spacer()
            Text(hint)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }

    private var hint: String {
        viewModel.phase == .throwCochonnet ? languageManager.t(.dragToAim) : languageManager.t(.tapToThrow)
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
