import Foundation

@MainActor
final class PiPController: ObservableObject {
    @Published private(set) var isActive = false

    func start() {
        isActive = true
    }

    func stop() {
        isActive = false
    }
}
