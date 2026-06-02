import Foundation

public struct SDKTemplate: Identifiable, Codable, Hashable {
    public var id: UUID
    public var name: String
    public var description: String
    public var category: String
    public var icon: String
    public var language: String
    public var version: String

    public init(id: UUID = UUID(), name: String, description: String, category: String, icon: String, language: String, version: String) {
        self.id = id
        self.name = name
        self.description = description
        self.category = category
        self.icon = icon
        self.language = language
        self.version = version
    }
}

public struct SDKVersion: Identifiable, Codable, Hashable {
    public var id: UUID
    public var sdkID: UUID
    public var versionString: String
    public var releaseNotes: String
    public var status: SDKVersionStatus
    public var createdAt: Date

    public enum SDKVersionStatus: String, Codable {
        case alpha, beta, stable, deprecated
    }

    public init(id: UUID = UUID(), sdkID: UUID, versionString: String, releaseNotes: String, status: SDKVersionStatus, createdAt: Date = Date()) {
        self.id = id
        self.sdkID = sdkID
        self.versionString = versionString
        self.releaseNotes = releaseNotes
        self.status = status
        self.createdAt = createdAt
    }
}

public struct SDKBuildArtifact: Identifiable, Codable, Hashable {
    public var id: UUID
    public var sdkID: UUID
    public var name: String
    public var type: String // .framework, .a, .xcframework
    public var sizeBytes: Int64
    public var createdAt: Date
    public var downloadURL: String?

    public init(id: UUID = UUID(), sdkID: UUID, name: String, type: String, sizeBytes: Int64, createdAt: Date = Date(), downloadURL: String? = nil) {
        self.id = id
        self.sdkID = sdkID
        self.name = name
        self.type = type
        self.sizeBytes = sizeBytes
        self.createdAt = createdAt
        self.downloadURL = downloadURL
    }
}

public struct SDKTestResult: Identifiable, Codable, Hashable {
    public var id: UUID
    public var sdkID: UUID
    public var testName: String
    public var duration: TimeInterval
    public var status: TestStatus
    public var failureMessage: String?
    public var timestamp: Date

    public enum TestStatus: String, Codable {
        case passed, failed, skipped
    }

    public init(id: UUID = UUID(), sdkID: UUID, testName: String, duration: TimeInterval, status: TestStatus, failureMessage: String? = nil, timestamp: Date = Date()) {
        self.id = id
        self.sdkID = sdkID
        self.testName = testName
        self.duration = duration
        self.status = status
        self.failureMessage = failureMessage
        self.timestamp = timestamp
    }
}

public struct SDKDependency: Identifiable, Codable, Hashable {
    public var id: UUID
    public var name: String
    public var type: String // System, Internal, External
    public var version: String
    public var parentID: UUID?

    public init(id: UUID = UUID(), name: String, type: String, version: String = "1.0.0", parentID: UUID? = nil) {
        self.id = id
        self.name = name
        self.type = type
        self.version = version
        self.parentID = parentID
    }
}

public struct SDKModule: Identifiable, Codable, Hashable {
    public var id: UUID
    public var name: String
    public var version: String
    public var status: String
    public var size: String

    public init(id: UUID = UUID(), name: String, version: String, status: String, size: String) {
        self.id = id
        self.name = name
        self.version = version
        self.status = status
        self.size = size
    }
}

public struct SDKBenchmarkResult: Identifiable, Codable, Hashable {
    public var id: UUID
    public var name: String
    public var value: String
    public var delta: String
    public var status: String // Improved, Regressed, Stable

    public init(id: UUID = UUID(), name: String, value: String, delta: String, status: String) {
        self.id = id
        self.name = name
        self.value = value
        self.delta = delta
        self.status = status
    }
}

public struct SDKArchive: Identifiable, Codable, Hashable {
    public var id: UUID
    public var name: String
    public var date: Date
    public var size: String

    public init(id: UUID = UUID(), name: String, date: Date = Date(), size: String) {
        self.id = id
        self.name = name
        self.date = date
        self.size = size
    }
}
