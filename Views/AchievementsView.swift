import SwiftUI

struct AchievementsView: View {
    @EnvironmentObject var languageManager: LanguageManager
    @EnvironmentObject var statsManager: StatsManager
    var onBack: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            TopNavigationBar(showBack: true, onBack: onBack)

            ScrollView {
                VStack(spacing: 14) {
                    Text(languageManager.t(.achievements))
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top, 20)

                    if statsManager.unlocked.isEmpty {
                        Text(languageManager.t(.noAchievementsYet))
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.top, 8)
                    }

                    ForEach(AchievementID.allCases) { achievement in
                        row(for: achievement)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
        }
        .background(Color(.systemBackground).ignoresSafeArea())
    }

    private func row(for achievement: AchievementID) -> some View {
        let isUnlocked = statsManager.unlocked.contains(achievement)
        return HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(isUnlocked
                        ? AnyShapeStyle(LinearGradient(colors: [Color("PrimaryOrange"), Color("BurntYellow")], startPoint: .top, endPoint: .bottom))
                        : AnyShapeStyle(Color.gray.opacity(0.25)))
                    .frame(width: 46, height: 46)
                Image(systemName: isUnlocked ? achievement.icon : "lock.fill")
                    .foregroundColor(isUnlocked ? .white : .secondary)
                    .font(.system(size: 18, weight: .semibold))
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(languageManager.t(achievement.titleKey))
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(isUnlocked ? .primary : .secondary)
                Text(languageManager.t(achievement.descriptionKey))
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }

            Spacer()

            Text(languageManager.t(isUnlocked ? .unlocked : .locked))
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(isUnlocked ? Color("PrimaryOrange") : .secondary)
        }
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(.ultraThinMaterial))
        .opacity(isUnlocked ? 1 : 0.7)
    }
}
