import Foundation
import Messages

@MainActor
class MessageManager {
    nonisolated(unsafe) static let shared = MessageManager()

    private init() {}

    func createMessage(payload: MessagePayload, session: MSSession?, summary: String) -> MSMessage {
        let message = MSMessage(session: session ?? MSSession())

        var components = URLComponents()
        if let payloadString = JSONCoder.encodeToString(payload) {
            components.queryItems = [URLQueryItem(name: "payload", value: payloadString)]
        }

        message.url = components.url

        let layout = MSMessageTemplateLayout()
        layout.caption = summary
        message.layout = layout

        return message
    }

    func decodePayload(from message: MSMessage?) -> MessagePayload? {
        guard let url = message?.url,
              let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let payloadString = components.queryItems?.first(where: { $0.name == "payload" })?.value else {
            return nil
        }

        return JSONCoder.decodeFromString(MessagePayload.self, from: payloadString)
    }
}
