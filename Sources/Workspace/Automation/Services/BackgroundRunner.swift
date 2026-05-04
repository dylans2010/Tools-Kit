import Foundation

class BackgroundRunner {
    static let shared = BackgroundRunner()

    private init() {}

    func startMonitoring() {
        // Monitor for triggers in background
        Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { _ in
            print("Background automation runner checking for triggers...")
        }
    }
}
