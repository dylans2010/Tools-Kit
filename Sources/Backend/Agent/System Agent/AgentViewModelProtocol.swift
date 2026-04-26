import Foundation

@MainActor
protocol AgentViewModelProtocol: ObservableObject {
    var messages: [SystemAgentMessage] { get }
    var state: SystemAgentState { get }
    var inputText: String { get set }
    func submit() async
    func reset()
}
