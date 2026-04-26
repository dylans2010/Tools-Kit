import Foundation

struct AgentStreamBuffer {
    var text = ""
    mutating func append(delta: String) { text += delta }
}
