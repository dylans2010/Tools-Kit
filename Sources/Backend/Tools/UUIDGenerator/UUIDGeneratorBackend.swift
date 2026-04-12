import Foundation

final class UUIDGeneratorBackend: ObservableObject {
    @Published var uuids: [String] = []

    func generate(count: Int) {
        var results: [String] = []
        for _ in 0..<count {
            results.append(UUID().uuidString)
        }
        self.uuids = results
    }
}
