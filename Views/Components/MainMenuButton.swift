import SwiftUI

struct MainMenuButton: View {
    let title: String
    let icon: String
    var isPrimary: Bool = false
    var identifier: String? = nil
    let action: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button {
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
            action()
        } label: {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                    .frame(width: 26)
                Text(title)
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .bold))
                    .opacity(0.5)
            }
            .padding(.vertical, 16)
            .padding(.horizontal, 20)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(
                        isPrimary
                        ? AnyShapeStyle(LinearGradient(colors: [Color("PrimaryOrange"), Color("BurntYellow")], startPoint: .leading, endPoint: .trailing))
                        : AnyShapeStyle(.ultraThinMaterial)
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(Color("PrimaryOrange").opacity(isPrimary ? 0 : 0.25), lineWidth: 1)
            )
            .foregroundColor(isPrimary ? .white : .primary)
            .shadow(color: Color("PrimaryOrange").opacity(isPrimary ? 0.35 : 0), radius: 12, x: 0, y: 6)
        }
        .scaleEffect(isPressed ? 0.96 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressed)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
        .accessibilityIdentifier(identifier ?? "")
    }
}
