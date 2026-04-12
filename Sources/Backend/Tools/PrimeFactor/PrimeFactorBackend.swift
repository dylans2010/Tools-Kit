import Foundation

final class PrimeFactorBackend: ObservableObject {
    @Published var factors: String = ""

    func factorize(_ n: Int) {
        var number = n
        var results: [Int] = []
        var divisor = 2

        while number > 1 {
            while number % divisor == 0 {
                results.append(divisor)
                number /= divisor
            }
            divisor += 1
        }

        self.factors = results.map { String($0) }.joined(separator: " × ")
    }
}
