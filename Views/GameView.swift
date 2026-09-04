import SwiftUI

/// Reports the real, rendered height of a UI chrome bar (top/bottom) up the
/// view tree, so the playable field can be inset to exactly avoid it —
/// hardcoding a guessed point value would drift from the real UI on
/// different devices/Dynamic Type sizes.
private struct TopBarHeightKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}

private struct BottomBarHeightKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}

struct GameView: View {
    @EnvironmentObject var languageManager: LanguageManager
    @EnvironmentObject var soundManager: SoundManager
    @EnvironmentObject var statsManager: StatsManager
    @ObservedObject var viewModel: GameViewModel
    var onExit: () -> Void

    /// `@GestureState` (not `@State`): SwiftUI guarantees this resets to
    /// `nil` the instant the gesture ends or is cancelled, for any reason —
    /// no manual cleanup path can be missed, unlike a plain `@State` var
    /// that only a correctly-firing `.onEnded` closure would reset.
    @GestureState private var dragTarget: CGPoint?

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

            if let unlocked = statsManager.justUnlocked {
                achievementToast(unlocked)
            }
        }
        .onAppear { viewModel.soundManager = soundManager }
        .onPreferenceChange(TopBarHeightKey.self) { viewModel.topSafeInset = $0 + 16 }
        .onPreferenceChange(BottomBarHeightKey.self) { viewModel.bottomSafeInset = $0 + 36 }
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
            .accessibilityIdentifier("game.field")
        }
    }

    private var canThrow: Bool {
        viewModel.isHumanControlled(viewModel.currentTeam) && (viewModel.phase == .throwCochonnet || viewModel.phase == .throwBall)
    }

    /// Drag distance normalized against a reference "full pull" length, so
    /// the power meter and the shot/point decision agree on the same 0...1
    /// scale regardless of screen size.
    private func power(for point: CGPoint, origin: CGPoint, in size: CGSize) -> CGFloat {
        let reference = size.height * 0.5
        let pulled = hypot(point.x - origin.x, point.y - origin.y)
        return min(pulled / reference, 1.0)
    }

    private func powerColor(_ power: CGFloat) -> Color {
        if power > 0.62 { return Color.red }
        if power > 0.35 { return Color("BurntYellow") }
        return Color("PrimaryOrange")
    }

    private func aimOverlay(to point: CGPoint, in size: CGSize) -> some View {
        let origin = CGPoint(x: size.width / 2, y: size.height * 0.92)
        let power = power(for: point, origin: origin, in: size)
        let color = powerColor(power)
        let isShot = power > 0.62

        return ZStack {
            Path { path in
                path.move(to: origin)
                path.addLine(to: point)
            }
            .stroke(
                LinearGradient(colors: [color.opacity(0.05), color.opacity(0.9)], startPoint: .bottom, endPoint: .top),
                style: StrokeStyle(lineWidth: 3, lineCap: .round, dash: [2, 10])
            )

            Circle()
                .fill(color)
                .frame(width: 14, height: 14)
                .shadow(color: color.opacity(0.7), radius: 8)
                .position(point)

            powerMeter(power: power, isShot: isShot, color: color)
                .position(x: size.width / 2, y: size.height * 0.98)
        }
        .allowsHitTesting(false)
    }

    private func powerMeter(power: CGFloat, isShot: Bool, color: Color) -> some View {
        VStack(spacing: 4) {
            if isShot {
                Text(languageManager.t(.shotMode))
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.red)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.white.opacity(0.15))
                    Capsule().fill(color).frame(width: geo.size.width * power)
                }
            }
            .frame(width: 130, height: 6)
        }
    }

    /// Reads "effect" (spin) from the drag's own momentum at release: how
    /// far `predictedEndLocation` (SwiftUI's velocity-based extrapolation)
    /// deviates *sideways* from the straight aim line tells us the player
    /// flicked left/right as they let go, same intent as brushing a real
    /// boule off-center. Clamped to -1...1.
    private func lateralEffect(for value: DragGesture.Value, origin: CGPoint) -> CGFloat {
        let aim = CGVector(dx: value.location.x - origin.x, dy: value.location.y - origin.y)
        let aimLength = max(hypot(aim.dx, aim.dy), 1)
        let aimDir = CGVector(dx: aim.dx / aimLength, dy: aim.dy / aimLength)
        let perpendicular = CGVector(dx: -aimDir.dy, dy: aimDir.dx)

        let momentum = CGVector(
            dx: value.predictedEndLocation.x - value.location.x,
            dy: value.predictedEndLocation.y - value.location.y
        )
        let lateral = momentum.dx * perpendicular.dx + momentum.dy * perpendicular.dy
        return max(-1, min(1, lateral / 70))
    }

    private func throwGesture(in size: CGSize) -> some Gesture {
        DragGesture(minimumDistance: 4)
            .updating($dragTarget) { value, state, _ in
                guard canThrow else { return }
                state = value.location
            }
            .onEnded { value in
                guard canThrow else { return }
                let origin = CGPoint(x: size.width / 2, y: size.height * 0.92)
                let power = power(for: value.location, origin: origin, in: size)
                let scaled = CGPoint(
                    x: value.location.x / size.width * viewModel.fieldSize.width,
                    y: (1 - value.location.y / size.height) * viewModel.fieldSize.height
                )
                viewModel.humanThrow(toward: scaled, power: power, curve: lateralEffect(for: value, origin: origin))
            }
    }

    private var topBar: some View {
        VStack(spacing: 6) {
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
            ballsRemainingRow
        }
        .padding(.horizontal, 16)
        .background(
            GeometryReader { geo in
                Color.clear.preference(key: TopBarHeightKey.self, value: geo.size.height)
            }
        )
    }

    private var ballsRemainingRow: some View {
        HStack(spacing: 24) {
            ballsPill(team: .teamA)
            if !viewModel.isFreeTraining {
                ballsPill(team: .teamB)
            }
        }
    }

    private func ballsPill(team: Team) -> some View {
        HStack(spacing: 4) {
            Circle().fill(Color.white.opacity(0.7)).frame(width: 8, height: 8)
            Text("\(viewModel.remainingBalls(for: team)) \(languageManager.t(.ballsRemainingShort))")
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.white.opacity(0.75))
        }
    }

    private var bottomBar: some View {
        VStack(spacing: 12) {
            if viewModel.phase != .coinToss {
                TurnIndicatorView(viewModel: viewModel)
            }
            GameControlsView(viewModel: viewModel)
        }
        .padding(.horizontal, 16)
        .background(
            GeometryReader { geo in
                Color.clear.preference(key: BottomBarHeightKey.self, value: geo.size.height)
            }
        )
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
                Text(languageManager.t(viewModel.isFreeTraining ? .trainingRoundComplete : .endOfEnd))
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                if !viewModel.isFreeTraining {
                    Text(String(format: languageManager.t(.endOfEndSubtitle), languageManager.t((viewModel.lastEndWinner ?? .teamA).nameKey), viewModel.lastEndPoints))
                        .font(.system(size: 15))
                        .foregroundColor(.white.opacity(0.85))
                }
                Button {
                    viewModel.continueAfterEnd()
                } label: {
                    Text(languageManager.t(viewModel.isFreeTraining ? .newRound : .continueButton))
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
                    Group {
                        if viewModel.matchType == .localTwoPlayer {
                            Text(String(format: languageManager.t(.teamTurn), languageManager.t((viewModel.winner ?? .teamA).nameKey)))
                        } else {
                            Text(languageManager.t((viewModel.winner ?? .teamA).isHuman ? .victory : .defeat))
                        }
                    }
                    .font(.system(size: 32, weight: .heavy, design: .rounded))
                    .foregroundColor(.white)
                    Text("\(viewModel.teamAScore) - \(viewModel.teamBScore)")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(.white.opacity(0.9))

                    HStack(spacing: 14) {
                        Button {
                            viewModel.startNewGame(mode: viewModel.mode, difficulty: viewModel.difficulty, targetScore: viewModel.targetScore, terrain: viewModel.terrain, matchType: viewModel.matchType)
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

    /// A short-lived toast for `StatsManager.justUnlocked` — previously that
    /// flag was set on every unlock but nothing ever displayed it, so
    /// achievements unlocked completely silently. Auto-dismisses itself
    /// after 2.5s, and only clears the flag if it's still the same
    /// achievement (a second one unlocking in that window replaces it
    /// instead of being clobbered by the first toast's dismiss timer).
    private func achievementToast(_ achievement: AchievementID) -> some View {
        VStack {
            HStack(spacing: 12) {
                Image(systemName: achievement.icon)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
                VStack(alignment: .leading, spacing: 1) {
                    Text(languageManager.t(.unlocked))
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(.white.opacity(0.75))
                    Text(languageManager.t(achievement.titleKey))
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(LinearGradient(colors: [Color("PrimaryOrange"), Color("BurntYellow")], startPoint: .leading, endPoint: .trailing))
            .clipShape(Capsule())
            .shadow(color: .black.opacity(0.3), radius: 10, y: 4)
            .padding(.top, 4)
            Spacer()
        }
        .transition(.move(edge: .top).combined(with: .opacity))
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                if statsManager.justUnlocked == achievement {
                    withAnimation { statsManager.justUnlocked = nil }
                }
            }
        }
        .allowsHitTesting(false)
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
