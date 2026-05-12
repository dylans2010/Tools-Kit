import Foundation
import Combine

/// Component system for Slides, managing reusable templates and design tokens.
final class SlideComponentSystem: ObservableObject {
    nonisolated(unsafe) static let shared = SlideComponentSystem()

    struct Component: Codable, Identifiable, Sendable {
        let id: UUID
        var name: String
        var rootNode: SlideNode
        var parameters: [String: ParameterType]
    }

    enum ParameterType: String, Codable, Sendable {
        case color, text, toggle, number
    }

    @Published var components: [Component] = []
    @Published var designTokens: [String: String] = [:] // TokenName -> Value

    private init() {}

    func createComponent(from node: SlideNode, named name: String) {
        let component = Component(id: UUID(), name: name, rootNode: node, parameters: [:])
        components.append(component)
    }

    func resolveToken(_ token: String) -> String {
        return designTokens[token] ?? token
    }
}
