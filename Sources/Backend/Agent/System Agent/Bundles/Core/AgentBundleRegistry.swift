import Foundation

final class AgentBundleRegistry {
    static let shared = AgentBundleRegistry()
    private var bundles: [String: AgentBundle] = [:]

    private init() {}

    func register(bundle: AgentBundle) {
        bundles[bundle.id] = bundle
    }

    func bundle(for id: String) -> AgentBundle? {
        bundles[id]
    }

    var allBundles: [AgentBundle] {
        Array(bundles.values)
    }
}
