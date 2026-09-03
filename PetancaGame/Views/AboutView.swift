import SwiftUI

struct AboutView: View {
    @EnvironmentObject var languageManager: LanguageManager
    var onBack: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            TopNavigationBar(showBack: true, onBack: onBack)

            ScrollView {
                VStack(spacing: 28) {
                    Circle()
                        .fill(RadialGradient(colors: [.white, Color("MediumGray")], center: .topLeading, startRadius: 2, endRadius: 60))
                        .frame(width: 96, height: 96)
                        .shadow(color: Color("PrimaryOrange").opacity(0.3), radius: 12, y: 6)
                        .padding(.top, 20)

                    Text(languageManager.t(.appName))
                        .font(.system(size: 36, weight: .heavy, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(colors: [Color("PrimaryOrange"), Color("BurntYellow")], startPoint: .leading, endPoint: .trailing)
                        )

                    Text(languageManager.t(.aboutDescription))
                        .font(.body)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)

                    VStack(alignment: .leading, spacing: 12) {
                        Text(languageManager.t(.aboutRulesTitle))
                            .font(.system(size: 17, weight: .semibold, design: .rounded))
                        ruleRow(.rule1)
                        ruleRow(.rule2)
                        ruleRow(.rule3)
                        ruleRow(.rule4)
                    }
                    .padding(18)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(.ultraThinMaterial))

                    VStack(spacing: 14) {
                        Text(languageManager.t(.developedBy))
                            .font(.headline)
                            .foregroundColor(.secondary)

                        Text("David Arsénio Martins")
                            .font(.system(size: 22, weight: .bold, design: .rounded))

                        HStack(spacing: 24) {
                            Link(destination: URL(string: "https://ividi.dev/")!) {
                                Label(languageManager.t(.website), systemImage: "globe")
                            }
                            Link(destination: URL(string: "https://github.com/VidiPT89/")!) {
                                Label(languageManager.t(.github), systemImage: "chevron.left.forward.slash.chevron.right")
                            }
                        }
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(Color("PrimaryOrange"))
                    }
                    .padding(20)
                    .frame(maxWidth: .infinity)
                    .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(.ultraThinMaterial))

                    Text("MIT License")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.bottom, 24)
                }
                .padding(.horizontal, 24)
            }
        }
        .background(Color(.systemBackground).ignoresSafeArea())
    }

    private func ruleRow(_ key: L10nKey) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "circle.fill").font(.system(size: 5)).padding(.top, 6).foregroundColor(Color("PrimaryOrange"))
            Text(languageManager.t(key)).font(.system(size: 14))
        }
    }
}
