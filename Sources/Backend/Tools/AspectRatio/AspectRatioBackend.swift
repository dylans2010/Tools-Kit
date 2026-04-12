import Foundation

final class AspectRatioBackend: ObservableObject {
    @Published var result: String = ""

    func calculate(width: Double, height: Double) {
        let common = gcd(Int(width), Int(height))
        self.result = "\(Int(width)/common):\(Int(height)/common)"
    }

    private func gcd(_ a: Int, _ b: Int) -> Int {
        let r = a % b
        if r != 0 { return gcd(b, r) }
        else { return b }
    }
}
