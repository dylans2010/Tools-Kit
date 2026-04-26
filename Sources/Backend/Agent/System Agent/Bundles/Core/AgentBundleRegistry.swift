import Foundation

public final class AgentBundleRegistry {
    public static let shared = AgentBundleRegistry()
    private var bundles: [String: AgentBundle] = [:]

    private init() {}

    public func register(bundle: AgentBundle) {
        bundles[bundle.id] = bundle
    }

    public func bundle(for id: String) -> AgentBundle? {
        bundles[id]
    }

    public var allBundles: [AgentBundle] {
        Array(bundles.values)
    }
}
