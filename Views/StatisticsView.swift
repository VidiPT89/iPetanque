import SwiftUI

struct StatisticsView: View {
    @EnvironmentObject var languageManager: LanguageManager
    @EnvironmentObject var statsManager: StatsManager
    var onBack: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            TopNavigationBar(showBack: true, onBack: onBack)

            ScrollView {
                VStack(spacing: 16) {
                    Text(languageManager.t(.statistics))
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top, 20)

                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 14) {
                        statTile(languageManager.t(.gamesPlayed), "\(statsManager.gamesPlayed)", "gamecontroller.fill")
                        statTile(languageManager.t(.gamesWon), "\(statsManager.gamesWon)", "trophy.fill")
                        statTile(languageManager.t(.winRate), "\(statsManager.winRatePercent)%", "percent")
                        statTile(languageManager.t(.pointsTaken), "\(statsManager.pointsTaken)", "scope")
                        statTile(languageManager.t(.shotsTaken), "\(statsManager.shotsTaken)", "bolt.fill")
                        statTile(languageManager.t(.achievementStreak5), "\(statsManager.currentStreak)", "flame.fill")
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
        }
        .background(Color(.systemBackground).ignoresSafeArea())
    }

    private func statTile(_ title: String, _ value: String, _ icon: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(Color("PrimaryOrange"))
            Text(value)
                .font(.system(size: 26, weight: .heavy, design: .rounded))
            Text(title)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(.ultraThinMaterial))
    }
}
