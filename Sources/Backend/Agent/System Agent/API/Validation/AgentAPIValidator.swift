import Foundation

struct AgentAPIValidator {
    func validateStatus(_ response: HTTPURLResponse) -> Bool {
        (200..<300).contains(response.statusCode)
    }
}
