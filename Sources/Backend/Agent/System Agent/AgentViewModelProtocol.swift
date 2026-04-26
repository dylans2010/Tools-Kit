import Foundation
import Combine

public protocol AgentViewModelProtocol: ObservableObject {
    var messages: [SystemAgentMessage] { get }
    var state: SystemAgentState { get }
    var isThinking: Bool { get }

    func sendMessage(_ content: String) async
    func reset()
}
