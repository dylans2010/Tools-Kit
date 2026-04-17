import Foundation
import Combine

final class WorkoutTimerService: ObservableObject {
    @Published var elapsedSeconds: Int = 0
    @Published var restSecondsRemaining: Int = 0
    @Published var isRunning: Bool = false

    private var timerCancellable: AnyCancellable?

    func startWorkout() {
        guard !isRunning else { return }
        isRunning = true
        timerCancellable = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self else { return }
                self.elapsedSeconds += 1
                if self.restSecondsRemaining > 0 {
                    self.restSecondsRemaining -= 1
                }
            }
    }

    func stopWorkout() {
        isRunning = false
        timerCancellable?.cancel()
        timerCancellable = nil
    }

    func resetWorkout() {
        stopWorkout()
        elapsedSeconds = 0
        restSecondsRemaining = 0
    }

    func startRest(seconds: Int) {
        restSecondsRemaining = max(seconds, 0)
    }
}
