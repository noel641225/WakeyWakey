import SwiftUI
import Combine

// MARK: - Animation State
enum CharacterAnimationState {
    case idle
    case moving
    case tapped
    case dismissed
}

// MARK: - Sprite Animator
@MainActor
final class SpriteAnimator: ObservableObject {
    @Published var currentFrameIndex: Int = 0
    @Published var animationState: CharacterAnimationState = .idle

    // Sprite sheet frames loaded from asset catalog (if available)
    private(set) var frameNames: [String] = []
    private var timer: Timer?
    private var fps: Double
    private var frameCount: Int { max(frameNames.count, 1) }

    init(fps: Double = 8) {
        self.fps = fps
    }

    // MARK: - Load Frames
    /// Loads frames named "sprite_<prefix>_0", "sprite_<prefix>_1", etc.
    func loadFrames(prefix: String, count: Int) {
        frameNames = (0..<count).map { "\(prefix)_\($0)" }
    }

    // MARK: - Playback Control
    func startAnimation(state: CharacterAnimationState = .idle) {
        animationState = state
        timer?.invalidate()
        guard frameCount > 1 else { return }
        timer = Timer.scheduledTimer(withTimeInterval: 1.0 / fps, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.advanceFrame()
            }
        }
        RunLoop.main.add(timer!, forMode: .common)
    }

    func stopAnimation() {
        timer?.invalidate()
        timer = nil
    }

    func transition(to state: CharacterAnimationState) {
        animationState = state
        currentFrameIndex = 0
    }

    private func advanceFrame() {
        guard frameCount > 1 else { return }
        currentFrameIndex = (currentFrameIndex + 1) % frameCount
    }

    deinit {
        timer?.invalidate()
    }
}
