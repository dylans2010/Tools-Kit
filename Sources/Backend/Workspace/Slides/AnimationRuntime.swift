import Foundation
import Combine

/// Animation runtime for Slides, handling physics-based motion and timeline sequencing.
final class AnimationRuntime: ObservableObject {
    static let shared = AnimationRuntime()

    @Published var currentTime: Double = 0
    @Published var isPlaying: Bool = false

    struct Keyframe: Codable, Identifiable, Sendable {
        let id: UUID
        let nodeID: UUID
        let property: String
        let value: Double
        let time: Double
        let easing: EasingType
    }

    enum EasingType: String, Codable, Sendable {
        case linear, spring, easeInOut, bounce
    }

    private var keyframes: [Keyframe] = []
    private var timer: AnyCancellable?

    private init() {}

    func play() {
        isPlaying = true
        timer = Timer.publish(every: 1.0/60.0, on: .main, in: .common).autoconnect().sink { _ in
            self.currentTime += 1.0/60.0
            // Apply property updates to nodes
        }
    }

    func pause() {
        isPlaying = false
        timer?.cancel()
    }

    func scrub(to time: Double) {
        currentTime = time
        // Calculate and apply interpolated values
    }
}
