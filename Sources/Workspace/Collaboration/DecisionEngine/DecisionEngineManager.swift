import Foundation

/// Represents a decision-making session.
struct DecisionSession: Identifiable, Codable {
    let id: UUID
    let title: String
    var options: [DecisionOption]
    var status: DecisionStatus

    enum DecisionStatus: String, Codable {
        case active
        case resolved
        case cancelled
    }
}

/// Represents an option in a decision session.
struct DecisionOption: Identifiable, Codable {
    let id: UUID
    let text: String
    var votes: Int = 0
    var weightedScore: Double = 0.0
}

/// Manages collaborative decision making within a space.
final class DecisionEngineManager: ObservableObject {
    static let shared = DecisionEngineManager()

    @Published var sessions: [UUID: [DecisionSession]] = [:] // SpaceID: Sessions

    private init() {}

    func createSession(spaceID: UUID, title: String, options: [String]) {
        let session = DecisionSession(
            id: UUID(),
            title: title,
            options: options.map { DecisionOption(id: UUID(), text: $0) },
            status: .active
        )
        var current = sessions[spaceID] ?? []
        current.append(session)
        sessions[spaceID] = current
    }

    func vote(spaceID: UUID, sessionID: UUID, optionID: UUID, weight: Double) {
        guard let sIndex = sessions[spaceID]?.firstIndex(where: { $0.id == sessionID }),
              let oIndex = sessions[spaceID]?[sIndex].options.firstIndex(where: { $0.id == optionID }) else { return }

        sessions[spaceID]?[sIndex].options[oIndex].votes += 1
        sessions[spaceID]?[sIndex].options[oIndex].weightedScore += weight
    }
}
