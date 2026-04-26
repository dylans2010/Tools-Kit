import Foundation

struct AgentBundleValidator {
    init() {}

    func validate(bundle: AgentBundle) -> Bool {
        !bundle.id.isEmpty && !bundle.name.isEmpty && !bundle.version.isEmpty
    }
}
