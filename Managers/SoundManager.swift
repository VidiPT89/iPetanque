import AVFoundation
import SwiftUI

/// Plays short system-provided haptics/sounds. No bundled audio assets are
/// required: throws and collisions use system sound IDs, keeping the game
/// fully playable out of the box while still respecting the user's
/// sound/music preferences.
final class SoundManager: ObservableObject {
    @AppStorage("soundEnabled") var soundEnabled: Bool = true

    func playThrow() {
        guard soundEnabled else { return }
        AudioServicesPlaySystemSound(1104)
    }

    func playCollision() {
        guard soundEnabled else { return }
        AudioServicesPlaySystemSound(1105)
    }

    func playVictory() {
        guard soundEnabled else { return }
        AudioServicesPlaySystemSound(1025)
    }

    func haptic(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .medium) {
        UIImpactFeedbackGenerator(style: style).impactOccurred()
    }
}
