import Foundation
import SwiftUI

// This file contains models that are not yet moved to the modular Models/ directory.

// TKProject is used specifically for project export/import functionality.
public struct TKProject: Codable {
    public var metadata: ProjectMetadata
    public var type: DeveloperAppType
    public var payload: Data

    public struct ProjectMetadata: Codable {
        public var name: String
        public var version: String
        public var developerName: String
        public var description: String
        public var credits: String
        public var socialLinks: [String: String]

        public init(name: String, version: String, developerName: String, description: String, credits: String, socialLinks: [String: String]) {
            self.name = name
            self.version = version
            self.developerName = developerName
            self.description = description
            self.credits = credits
            self.socialLinks = socialLinks
        }
    }

    public init(metadata: ProjectMetadata, type: DeveloperAppType, payload: Data) {
        self.metadata = metadata
        self.type = type
        self.payload = payload
    }
}
