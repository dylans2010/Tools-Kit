import Foundation
import Combine

@MainActor
protocol AgentViewModelProtocol: ObservableObject {
    var messages: [SystemAgentMessage] { get }
    var state: SystemAgentState { get }
    var isThinking: Bool { get }
    var inputText: String { get set }

    func submit() async
    func retryLastSubmission() async
    func reset()
}
