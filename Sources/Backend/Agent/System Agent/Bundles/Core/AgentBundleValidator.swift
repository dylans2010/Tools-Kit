import Foundation

struct AgentBundleValidator: Sendable {
    init() {}

    func validate(bundle: AgentBundle) -> Bool {
        !bundle.id.isEmpty && !bundle.name.isEmpty && !bundle.version.isEmpty
    }
}
