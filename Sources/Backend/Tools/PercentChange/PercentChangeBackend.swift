import Foundation

final class PercentChangeBackend: ObservableObject {
    @Published var result: String = ""

    func calculate(oldValue: Double, newValue: Double) {
        let change = ((newValue - oldValue) / oldValue) * 100
        self.result = String(format: "%.2f%%", change)
    }
}
