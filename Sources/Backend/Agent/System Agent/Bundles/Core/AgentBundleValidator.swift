import Foundation

public struct AgentBundleValidator {
    public init() {}

    public func validate(bundle: AgentBundle) -> Bool {
        !bundle.id.isEmpty && !bundle.name.isEmpty && !bundle.version.isEmpty
    }
}
