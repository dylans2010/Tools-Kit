import Foundation

enum DiffElement: Equatable {
    case common(String)
    case added(String)
    case removed(String)
}

class DiffCheckerBackend: ObservableObject {
    @Published var text1 = ""
    @Published var text2 = ""
    @Published var diffResults: [DiffElement] = []

    func check() {
        let lines1 = text1.components(separatedBy: .newlines)
        let lines2 = text2.components(separatedBy: .newlines)
        diffResults = computeDiff(lines1, lines2)
    }

    private func computeDiff(_ a: [String], _ b: [String]) -> [DiffElement] {
        let n = a.count
        let m = b.count
        var dp = Array(repeating: Array(repeating: 0, count: m + 1), count: n + 1)

        for i in 1...n {
            for j in 1...m {
                if a[i-1] == b[j-1] {
                    dp[i][j] = dp[i-1][j-1] + 1
                } else {
                    dp[i][j] = max(dp[i-1][j], dp[i][j-1])
                }
            }
        }

        var result: [DiffElement] = []
        var i = n
        var j = m

        while i > 0 || j > 0 {
            if i > 0 && j > 0 && a[i-1] == b[j-1] {
                result.append(.common(a[i-1]))
                i -= 1
                j -= 1
            } else if j > 0 && (i == 0 || dp[i][j-1] >= dp[i-1][j]) {
                result.append(.added(b[j-1]))
                j -= 1
            } else if i > 0 && (j == 0 || dp[i-1][j] >= dp[i][j-1]) {
                result.append(.removed(a[i-1]))
                i -= 1
            }
        }

        return result.reversed()
    }
}
