import Foundation

actor LMLinkAPIValidator {
    enum PingResult {
        case reachable(modelCount: Int)
        case unreachable
    }

    func ping(serverURL: URL = URL(string: "http://localhost:1234")!) async -> PingResult {
        let endpoint = serverURL.appendingPathComponent("v1/models")
        var request = URLRequest(url: endpoint, timeoutInterval: 5)
        request.httpMethod = "GET"
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
                return .unreachable
            }
            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
            let models = json?["data"] as? [Any]
            LMLinkLogger.api.info("Local server reachable. Models: \(models?.count ?? 0, privacy: .public)")
            return .reachable(modelCount: models?.count ?? 0)
        } catch {
            LMLinkLogger.api.info("Local server unreachable: \(error.localizedDescription, privacy: .public)")
            return .unreachable
        }
    }
}
