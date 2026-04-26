import Foundation

enum AgentStreamEvent {
    case textDelta(String)
    case toolCallStart(name: String)
    case toolCallInputDelta(String)
    case toolCallComplete(AgentToolCall)
    case done(AgentAPIResponse)
    case error(AgentAPIError)
}

struct AgentStreamingHandler {
    func stream(request: AgentAPIRequest) -> AsyncThrowingStream<AgentStreamEvent, Error> {
        AsyncThrowingStream { continuation in
            continuation.yield(.textDelta("Streaming is not enabled for this provider."))
            continuation.finish()
        }
    }
}
