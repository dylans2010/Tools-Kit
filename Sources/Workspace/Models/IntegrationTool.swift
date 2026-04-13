import Foundation

struct IntegrationTool: Codable, Identifiable, Equatable {
    var id: UUID = UUID()
    var name: String = ""
    var description: String = ""
    var promptTemplate: String = ""
    var isEnabled: Bool = true
    var createdAt: Date = Date()
}
