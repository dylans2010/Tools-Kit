import Foundation

struct MessagesAIRequest: Codable, Sendable {
    let input: String
    let subtype: PayloadSubtype
    let parameters: [String: String]

    init(input: String, subtype: PayloadSubtype, parameters: [String: String] = [:]) {
        self.input = input
        self.subtype = subtype
        self.parameters = parameters
    }
}
