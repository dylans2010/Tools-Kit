import Foundation
import Combine

@MainActor
public final class SDKVersionManager: ObservableObject {
    public static let shared = SDKVersionManager()

    @Published public private(set) var currentVersion: SemanticVersion = SemanticVersion(major: 2, minor: 0, patch: 0)
    @Published public private(set) var changelog: [VersionEntry] = []
    @Published public private(set) var compatibilityMatrix: [String: VersionRange] = [:]
    @Published public private(set) var deprecations: [DeprecationNotice] = []
    @Published public private(set) var migrationHistory: [MigrationRecord] = []

    private init() {
        loadDefaultChangelog()
        loadDefaultCompatibility()
    }

    // MARK: - Version Queries

    public var versionString: String {
        currentVersion.description
    }

    public func isCompatible(with requirement: String) -> Bool {
        guard let range = VersionRange(string: requirement) else { return false }
        return range.contains(currentVersion)
    }

    public func checkComponentCompatibility(_ component: String) -> CompatibilityResult {
        guard let range = compatibilityMatrix[component] else {
            return CompatibilityResult(component: component, status: .unknown, message: "No compatibility data available")
        }
        if range.contains(currentVersion) {
            return CompatibilityResult(component: component, status: .compatible, message: "Compatible with SDK \(versionString)")
        } else {
            return CompatibilityResult(component: component, status: .incompatible, message: "Requires SDK \(range.description)")
        }
    }

    // MARK: - Deprecations

    public func registerDeprecation(_ notice: DeprecationNotice) {
        deprecations.append(notice)
        SDKEventBus.shared.publish(SDKBusEvent(
            channel: "sdk.version",
            name: "deprecation.registered",
            data: ["api": notice.api, "removedIn": notice.removedInVersion?.description ?? "TBD"]
        ))
    }

    public func activeDeprecations() -> [DeprecationNotice] {
        deprecations.filter { notice in
            if let removedIn = notice.removedInVersion {
                return currentVersion < removedIn
            }
            return true
        }
    }

    // MARK: - Migration

    public func recordMigration(from: SemanticVersion, to: SemanticVersion, steps: [String]) {
        let record = MigrationRecord(fromVersion: from, toVersion: to, steps: steps)
        migrationHistory.append(record)
        SDKEventBus.shared.publish(SDKBusEvent(
            channel: "sdk.version",
            name: "migration.completed",
            data: ["from": from.description, "to": to.description]
        ))
    }

    // MARK: - Changelog

    public func addEntry(_ entry: VersionEntry) {
        changelog.insert(entry, at: 0)
    }

    public func entries(for version: SemanticVersion) -> VersionEntry? {
        changelog.first { $0.version == version }
    }

    // MARK: - Defaults

    private func loadDefaultChangelog() {
        // Changelog entries are added via addEntry(_:) as versions are released.
    }

    private func loadDefaultCompatibility() {
        // Compatibility entries are registered by each module at initialization.
    }

    public func registerCompatibility(component: String, minimum: SemanticVersion) {
        compatibilityMatrix[component] = VersionRange(minimum: minimum)
    }
}

// MARK: - Models

public struct SemanticVersion: Codable, Comparable, Hashable, CustomStringConvertible, Sendable {
    public let major: Int
    public let minor: Int
    public let patch: Int

    public var description: String { "\(major).\(minor).\(patch)" }

    public init(major: Int, minor: Int, patch: Int) {
        self.major = major
        self.minor = minor
        self.patch = patch
    }

    public static func < (lhs: SemanticVersion, rhs: SemanticVersion) -> Bool {
        if lhs.major != rhs.major { return lhs.major < rhs.major }
        if lhs.minor != rhs.minor { return lhs.minor < rhs.minor }
        return lhs.patch < rhs.patch
    }
}

public struct VersionRange: CustomStringConvertible, Sendable {
    public let minimum: SemanticVersion
    public let maximum: SemanticVersion?

    public var description: String {
        if let max = maximum {
            return ">= \(minimum) < \(max)"
        }
        return ">= \(minimum)"
    }

    public init(minimum: SemanticVersion, maximum: SemanticVersion? = nil) {
        self.minimum = minimum
        self.maximum = maximum
    }

    public init?(string: String) {
        let parts = string.components(separatedBy: ".")
        guard parts.count == 3,
              let major = Int(parts[0].trimmingCharacters(in: CharacterSet(charactersIn: ">= "))),
              let minor = Int(parts[1]),
              let patch = Int(parts[2]) else { return nil }
        self.minimum = SemanticVersion(major: major, minor: minor, patch: patch)
        self.maximum = nil
    }

    public func contains(_ version: SemanticVersion) -> Bool {
        if version < minimum { return false }
        if let max = maximum, version >= max { return false }
        return true
    }
}

public struct VersionEntry: Identifiable, Sendable {
    public let id = UUID()
    public let version: SemanticVersion
    public let date: Date
    public let changes: [ChangeItem]
}

public struct ChangeItem: Identifiable, Sendable {
    public let id = UUID()
    public let type: ChangeType
    public let description: String
}

public enum ChangeType: String, Codable, CaseIterable, Sendable {
    case feature, improvement, fix, breaking, deprecation
}

public struct DeprecationNotice: Identifiable, Sendable {
    public let id = UUID()
    public let api: String
    public let message: String
    public let alternative: String
    public let deprecatedInVersion: SemanticVersion
    public let removedInVersion: SemanticVersion?
}

public struct CompatibilityResult: Sendable {
    public let component: String
    public let status: CompatibilityStatus
    public let message: String
}

public enum CompatibilityStatus: String, Sendable {
    case compatible, incompatible, unknown
}

public struct MigrationRecord: Identifiable, Sendable {
    public let id = UUID()
    public let fromVersion: SemanticVersion
    public let toVersion: SemanticVersion
    public let steps: [String]
    public let completedAt: Date

    public init(fromVersion: SemanticVersion, toVersion: SemanticVersion, steps: [String]) {
        self.fromVersion = fromVersion
        self.toVersion = toVersion
        self.steps = steps
        self.completedAt = Date()
    }
}
