import SwiftUI

struct GameView: View {
    @EnvironmentObject var languageManager: LanguageManager
    @EnvironmentObject var soundManager: SoundManager
    @ObservedObject var viewModel: GameViewModel
    var onExit: () -> Void

    @State private var dragTarget: CGPoint?

    var body: some View {
        ZStack {
            fieldLayer

            VStack {
                topBar
                Spacer()
                bottomBar
            }
            .padding(.top, 8)
            .padding(.bottom, 20)

            if viewModel.phase == .coinToss {
                coinTossOverlay
            }

            if viewModel.phase == .endOfEnd {
                endOfEndOverlay
            }

            if viewModel.phase == .gameOver {
                gameOverOverlay
            }
        }
        .onAppear { viewModel.soundManager = soundManager }
        .background(Color.black.ignoresSafeArea())
    }

    private var fieldLayer: some View {
        GeometryReader { geo in
            ZStack {
                PetancaFieldView(viewModel: viewModel)
                    .ignoresSafeArea()

                if let dragTarget, canThrow {
                    aimOverlay(to: dragTarget, in: geo.size)
                }
            }
            .gesture(throwGesture(in: geo.size))
        }
    }

    private var canThrow: Bool {
        viewModel.currentTeam.isHuman && (viewModel.phase == .throwCochonnet || viewModel.phase == .throwBall)
    }

    private func aimOverlay(to point: CGPoint, in size: CGSize) -> some View {
        let origin = CGPoint(x: size.width / 2, y: size.height * 0.92)
        return ZStack {
            Path { path in
                path.move(to: origin)
                path.addLine(to: point)
            }
            .stroke(
                LinearGradient(colors: [Color("PrimaryOrange").opacity(0.05), Color("BurntYellow").opacity(0.85)], startPoint: .bottom, endPoint: .top),
                style: StrokeStyle(lineWidth: 3, lineCap: .round, dash: [2, 10])
            )

            Circle()
                .fill(Color("PrimaryOrange"))
                .frame(width: 14, height: 14)
                .shadow(color: Color("PrimaryOrange").opacity(0.7), radius: 8)
                .position(point)
        }
        .allowsHitTesting(false)
    }

    private func throwGesture(in size: CGSize) -> some Gesture {
        DragGesture(minimumDistance: 4)
            .onChanged { value in dragTarget = value.location }
            .onEnded { value in
                guard viewModel.currentTeam.isHuman,
                      viewModel.phase == .throwCochonnet || viewModel.phase == .throwBall else { return }
                let scaled = CGPoint(
                    x: value.location.x / size.width * viewModel.fieldSize.width,
                    y: (1 - value.location.y / size.height) * viewModel.fieldSize.height
                )
                viewModel.humanThrow(toward: scaled)
                dragTarget = nil
            }
    }

    private var topBar: some View {
        HStack {
            Button(action: onExit) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 26))
                    .foregroundColor(.white.opacity(0.85))
            }
            .accessibilityLabel(languageManager.t(.menu))
            Spacer()
            ScoreBoardView(viewModel: viewModel)
            Spacer()
            Color.clear.frame(width: 26, height: 26)
        }
        .padding(.horizontal, 16)
    }

    private var bottomBar: some View {
        VStack(spacing: 12) {
            TurnIndicatorView(viewModel: viewModel)
            GameControlsView(viewModel: viewModel)
        }
        .padding(.horizontal, 16)
    }

    private var coinTossOverlay: some View {
        overlayBackground {
            VStack(spacing: 16) {
                ProgressView()
                Text(languageManager.t(.coinToss))
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
            }
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.4) {
                    viewModel.confirmCoinToss()
                }
            }
        }
    }

    private var endOfEndOverlay: some View {
        overlayBackground {
            VStack(spacing: 18) {
                Text(languageManager.t(.endOfEnd))
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                Text(String(format: languageManager.t(.endOfEndSubtitle), languageManager.t((viewModel.lastEndWinner ?? .teamA).nameKey), viewModel.lastEndPoints))
                    .font(.system(size: 15))
                    .foregroundColor(.white.opacity(0.85))
                Button {
                    viewModel.continueAfterEnd()
                } label: {
                    Text(languageManager.t(.continueButton))
                        .font(.system(size: 16, weight: .bold))
                        .padding(.horizontal, 32)
                        .padding(.vertical, 12)
                        .background(LinearGradient(colors: [Color("PrimaryOrange"), Color("BurntYellow")], startPoint: .leading, endPoint: .trailing))
                        .foregroundColor(.white)
                        .clipShape(Capsule())
                }
            }
        }
    }

    private var gameOverOverlay: some View {
        ZStack {
            overlayBackground {
                VStack(spacing: 18) {
                    Text(languageManager.t((viewModel.winner ?? .teamA).isHuman ? .victory : .defeat))
                        .font(.system(size: 40, weight: .heavy, design: .rounded))
                        .foregroundColor(.white)
                    Text("\(viewModel.teamAScore) - \(viewModel.teamBScore)")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(.white.opacity(0.9))

                    HStack(spacing: 14) {
                        Button {
                            viewModel.startNewGame(mode: viewModel.mode, difficulty: viewModel.difficulty)
                        } label: {
                            Text(languageManager.t(.playAgain))
                                .font(.system(size: 15, weight: .bold))
                                .padding(.horizontal, 20)
                                .padding(.vertical, 12)
                                .background(LinearGradient(colors: [Color("PrimaryOrange"), Color("BurntYellow")], startPoint: .leading, endPoint: .trailing))
                                .foregroundColor(.white)
                                .clipShape(Capsule())
                        }

                        Button(action: onExit) {
                            Text(languageManager.t(.backToMenu))
                                .font(.system(size: 15, weight: .semibold))
                                .padding(.horizontal, 20)
                                .padding(.vertical, 12)
                                .background(.white.opacity(0.15))
                                .foregroundColor(.white)
                                .clipShape(Capsule())
                        }
                    }
                }
            }
            if (viewModel.winner ?? .teamB).isHuman {
                CelebrationParticles()
            }
        }
    }

    private func overlayBackground<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        ZStack {
            Color.black.opacity(0.55).ignoresSafeArea()
            content()
                .padding(28)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
                .padding(40)
        }
        .transition(.opacity.combined(with: .scale(scale: 0.9)))
    }
}
