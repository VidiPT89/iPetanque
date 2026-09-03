import SwiftUI

struct NewGameView: View {
    @EnvironmentObject var languageManager: LanguageManager
    var onBack: () -> Void
    var onStart: (GameMode, Difficulty, Int, Terrain, MatchType) -> Void

    @State private var selectedMode: GameMode = .singles
    @State private var matchType: MatchType = .vsCPU
    @AppStorage("difficulty") private var difficultyRaw = Difficulty.medium.rawValue
    @AppStorage("targetScore") private var targetScore = 13
    @AppStorage("terrain") private var terrainRaw = Terrain.hardDirt.rawValue

    private var selectedTerrain: Binding<Terrain> {
        Binding(
            get: { Terrain(rawValue: terrainRaw) ?? .hardDirt },
            set: { terrainRaw = $0.rawValue }
        )
    }

    private var selectedDifficulty: Binding<Difficulty> {
        Binding(
            get: { Difficulty(rawValue: difficultyRaw) ?? .medium },
            set: { difficultyRaw = $0.rawValue }
        )
    }

    var body: some View {
        VStack(spacing: 0) {
            TopNavigationBar(showBack: true, onBack: onBack)

            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(languageManager.t(.selectMode))
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                        Text(languageManager.t(.selectModeSubtitle))
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 20)

                    VStack(spacing: 12) {
                        ForEach(GameMode.allCases) { mode in
                            modeCard(mode)
                        }
                    }

                    VStack(alignment: .leading, spacing: 10) {
                        Text(languageManager.t(.opponentLabel))
                            .font(.system(size: 18, weight: .semibold, design: .rounded))
                        Picker("", selection: $matchType) {
                            ForEach(MatchType.allCases) { type in
                                Label(languageManager.t(type.titleKey), systemImage: type.icon).tag(type)
                            }
                        }
                        .pickerStyle(.segmented)
                    }

                    if matchType == .vsCPU {
                        VStack(alignment: .leading, spacing: 10) {
                            Text(languageManager.t(.difficulty))
                                .font(.system(size: 18, weight: .semibold, design: .rounded))
                            Picker("", selection: selectedDifficulty) {
                                ForEach(Difficulty.allCases, id: \.self) { d in
                                    Text(languageManager.t(d.titleKey)).tag(d)
                                }
                            }
                            .pickerStyle(.segmented)
                        }
                    }

                    if matchType != .freeTraining {
                        VStack(alignment: .leading, spacing: 10) {
                            Text(languageManager.t(.targetScoreLabel))
                                .font(.system(size: 18, weight: .semibold, design: .rounded))
                            Picker("", selection: $targetScore) {
                                Text("6").tag(6)
                                Text("11").tag(11)
                                Text("13").tag(13)
                            }
                            .pickerStyle(.segmented)
                        }
                    }

                    VStack(alignment: .leading, spacing: 10) {
                        Text(languageManager.t(.terrain))
                            .font(.system(size: 18, weight: .semibold, design: .rounded))
                        Picker("", selection: selectedTerrain) {
                            ForEach(Terrain.allCases) { t in
                                Label(languageManager.t(t.titleKey), systemImage: t.icon).tag(t)
                            }
                        }
                        .pickerStyle(.segmented)
                    }

                    Button {
                        onStart(selectedMode, selectedDifficulty.wrappedValue, targetScore, selectedTerrain.wrappedValue, matchType)
                    } label: {
                        Text(languageManager.t(.start))
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                LinearGradient(colors: [Color("PrimaryOrange"), Color("BurntYellow")], startPoint: .leading, endPoint: .trailing)
                            )
                            .foregroundColor(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                            .shadow(color: Color("PrimaryOrange").opacity(0.35), radius: 12, y: 6)
                    }
                    .accessibilityIdentifier("newGame.start")
                    .padding(.top, 8)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
        }
        .background(Color(.systemBackground).ignoresSafeArea())
    }

    private func modeCard(_ mode: GameMode) -> some View {
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) { selectedMode = mode }
        } label: {
            HStack(spacing: 16) {
                Image(systemName: mode.icon)
                    .font(.system(size: 20, weight: .semibold))
                    .frame(width: 34)
                VStack(alignment: .leading, spacing: 2) {
                    Text(languageManager.t(mode.titleKey))
                        .font(.system(size: 17, weight: .semibold, design: .rounded))
                    Text("\(mode.playersPerTeam) x \(mode.playersPerTeam) · \(mode.ballsPerPlayer) \(languageManager.t(.ballsRemaining).lowercased())")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
                Spacer()
                if selectedMode == mode {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(Color("PrimaryOrange"))
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(.ultraThinMaterial)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(selectedMode == mode ? Color("PrimaryOrange") : Color.clear, lineWidth: 2)
            )
            .foregroundColor(.primary)
        }
        .accessibilityIdentifier("newGame.mode.\(mode.rawValue)")
    }
}
