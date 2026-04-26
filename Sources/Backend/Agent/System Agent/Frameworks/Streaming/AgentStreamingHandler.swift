import Foundation

public final class AgentStreamingHandler {
    private let parser = AgentStreamEventParser()
    private let buffer = AgentStreamBuffer()

    public init() {}

    public func handle(chunk: String, onEvent: (AgentStreamEvent) -> Void) {
        buffer.append(chunk)
        let events = parser.parse(chunk: chunk)
        events.forEach(onEvent)
    }
}
