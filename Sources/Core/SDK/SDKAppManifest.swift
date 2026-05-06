import Foundation

/// Manifest for full SDK-built mini apps.
public struct SDKAppManifest: Identifiable, Codable {
    public var id: UUID
    public var name: String
    public var version: String
    public var description: String
    public var author: String
    public var icon: String
    public var requiredScopes: [SDKScope]
    public var screens: [SDKScreenConfig]
    public var initialScreenID: UUID
    public var modules: [String]

    public init(id: UUID = UUID(), name: String, version: String, description: String, author: String, icon: String, requiredScopes: [SDKScope], screens: [SDKScreenConfig], initialScreenID: UUID, modules: [String]) {
        self.id = id
        self.name = name
        self.version = version
        self.description = description
        self.author = author
        self.icon = icon
        self.requiredScopes = requiredScopes
        self.screens = screens
        self.initialScreenID = initialScreenID
        self.modules = modules
    }
}
