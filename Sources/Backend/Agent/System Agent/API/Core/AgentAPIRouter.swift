import Foundation

struct AgentAPIRouter: Sendable {
    let baseURL: URL

    func endpoint(path: String) -> URL {
        baseURL.appendingPathComponent(path)
    }
}
