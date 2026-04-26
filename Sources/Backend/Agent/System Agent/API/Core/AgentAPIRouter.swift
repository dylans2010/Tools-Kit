import Foundation

struct AgentAPIRouter {
    let baseURL: URL

    func endpoint(path: String) -> URL {
        baseURL.appendingPathComponent(path)
    }
}
