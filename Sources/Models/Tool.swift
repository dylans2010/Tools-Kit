import SwiftUI

enum ToolCategory: String, CaseIterable, Codable {
    case general = "General"
    case conversion = "Conversion"
    case development = "Development"
    case utility = "Utility"
    case ai = "AI"
}

enum ToolComplexity: String, CaseIterable, Codable {
    case basic = "Basic"
    case advanced = "Advanced"
}

protocol Tool: Identifiable {
    var id: String { get }
    var name: String { get }
    var icon: String { get }
    var category: ToolCategory { get }
    var complexity: ToolComplexity { get }
    var description: String { get }
    var requiresAPI: Bool { get }

    @ViewBuilder var view: AnyView { get }
}

extension Tool {
    var id: String { name }
}
