import Foundation

class DecisionTrackingService: ObservableObject {
    static let shared = DecisionTrackingService()

    @Published var decisions: [Decision] = []

    private init() {}

    func recordDecision(title: String, outcome: String) {
        decisions.append(Decision(id: UUID(), title: title, outcome: outcome, date: Date()))
    }
}

struct Decision: Identifiable {
    let id: UUID
    let title: String
    let outcome: String
    let date: Date
}
