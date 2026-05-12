import Foundation

enum FileManagementFeatures: Sendable {
    static let supportedCreationTypes: [ManagedFileType] = [.text, .plist, .json, .xml]
    static let supportedTemplates: [FileTemplate] = FileTemplate.allCases
    static let capabilities: [String] = [
        "Create files and folders in app workspace",
        "Import and export user files",
        "Inspect file properties and metadata",
        "Generate AI summaries for text-based files",
        "Track workspace statistics"
    ]
}
