import SwiftUI

struct SplashView: View {
    @EnvironmentObject var languageManager: LanguageManager
    var onFinished: () -> Void

    @State private var logoOpacity = 0.0
    @State private var logoScale = 0.8
    @State private var creditsOpacity = 0.0
    @State private var rollOffset: CGFloat = -140

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color("PrimaryOrange"), Color("BurntYellow"), Color("Black")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 18) {
                Spacer()

                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.15))
                        .frame(width: 150, height: 150)
                        .scaleEffect(logoScale)

                    Circle()
                        .fill(
                            RadialGradient(colors: [.white, Color.white.opacity(0.7)], center: .topLeading, startRadius: 2, endRadius: 60)
                        )
                        .frame(width: 96, height: 96)
                        .overlay(Circle().stroke(.black.opacity(0.15), lineWidth: 1))
                        .shadow(color: .black.opacity(0.3), radius: 10, y: 6)
                        .offset(x: rollOffset)
                }
                .opacity(logoOpacity)
                .scaleEffect(logoScale)

                Text(languageManager.t(.appName))
                    .font(.system(size: 48, weight: .heavy, design: .rounded))
                    .foregroundColor(.white)
                    .opacity(logoOpacity)

                Text(languageManager.t(.tagline))
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.85))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                    .opacity(logoOpacity)

                Spacer()

                VStack(spacing: 10) {
                    Text("\(languageManager.t(.developedBy)) David Arsénio Martins")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.white.opacity(0.95))

                    HStack(spacing: 22) {
                        Link(destination: URL(string: "https://ividi.dev/")!) {
                            Label("ividi.dev", systemImage: "globe")
                        }
                        Link(destination: URL(string: "https://github.com/VidiPT89/")!) {
                            Label("GitHub", systemImage: "chevron.left.forward.slash.chevron.right")
                        }
                    }
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(Color.white.opacity(0.9))
                }
                .opacity(creditsOpacity)
                .offset(y: creditsOpacity == 1.0 ? 0 : 14)
                .padding(.bottom, 44)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.8)) {
                logoOpacity = 1.0
                logoScale = 1.0
            }
            withAnimation(.easeOut(duration: 1.4).delay(0.3)) {
                rollOffset = 0
            }
            withAnimation(.easeOut(duration: 0.8).delay(0.6)) {
                creditsOpacity = 1.0
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.8) {
                onFinished()
            }
        }
    }
}
