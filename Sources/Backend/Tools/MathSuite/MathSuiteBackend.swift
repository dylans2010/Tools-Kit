import Foundation

final class MathSuiteBackend: ObservableObject {
    @Published var gcdResult: String = ""
    @Published var lcmResult: String = ""

    func calculate(a: Int, b: Int) {
        let g = gcd(a, b)
        let l = abs(a * b) / g
        self.gcdResult = "\(g)"
        self.lcmResult = "\(l)"
    }

    private func gcd(_ a: Int, _ b: Int) -> Int {
        var x = abs(a)
        var y = abs(b)
        while y != 0 {
            let t = x % y
            x = y
            y = t
        }
        return x
    }
}
