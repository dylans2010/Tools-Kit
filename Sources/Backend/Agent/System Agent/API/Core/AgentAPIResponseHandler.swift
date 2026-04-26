import Foundation

struct AgentAPIResponseHandler {
    func decodeResponse(from data: Data) throws -> AgentAPIResponse {
        try JSONDecoder().decode(AgentAPIResponse.self, from: data)
    }
}
