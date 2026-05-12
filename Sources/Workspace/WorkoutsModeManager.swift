import Foundation
import Combine

final class WorkoutsModeManager: ObservableObject {
    static let shared = WorkoutsModeManager()

    private let key = "workoutsModeEnabled"

    @Published var isWorkoutsModeEnabled: Bool {
        didSet {
            UserDefaults.standard.set(isWorkoutsModeEnabled, forKey: key)
        }
    }

    private init() {
        isWorkoutsModeEnabled = UserDefaults.standard.bool(forKey: key)
    }
}
