// ToolsKit — SDKMigrationManager.swift
// SDK Expansion — Phase 3

import Foundation
import Combine

/// Protocol for data migration management.
@MainActor
public protocol SDKMigrationManagerProtocol: AnyObject {
    func registerMigration(_ migration: SDKMigrationStep)
    func runPendingMigrations() async throws
    var currentVersion: Int { get }
    var pendingMigrations: [SDKMigrationStep] { get }
    var migrationHistory: [SDKMigrationRecord] { get }
}

/// Defines a single migration step.
public struct SDKMigrationStep: Identifiable, Sendable {
    public let id: String
    public let fromVersion: Int
    public let toVersion: Int
    public let description: String
    public let migrate: @Sendable () async throws -> Void

    public init(
        fromVersion: Int,
        toVersion: Int,
        description: String,
        migrate: @escaping @Sendable () async throws -> Void
    ) {
        self.id = "migration_v\(fromVersion)_to_v\(toVersion)"
        self.fromVersion = fromVersion
        self.toVersion = toVersion
        self.description = description
        self.migrate = migrate
    }
}

/// Record of a completed migration.
public struct SDKMigrationRecord: Identifiable, Codable, Sendable {
    public let id: UUID
    public let migrationID: String
    public let fromVersion: Int
    public let toVersion: Int
    public let completedAt: Date
    public let durationSeconds: TimeInterval
    public let status: Status

    public enum Status: String, Codable, Sendable {
        case success
        case failed
    }

    public init(
        migrationID: String,
        fromVersion: Int,
        toVersion: Int,
        durationSeconds: TimeInterval,
        status: Status
    ) {
        self.id = UUID()
        self.migrationID = migrationID
        self.fromVersion = fromVersion
        self.toVersion = toVersion
        self.completedAt = Date()
        self.durationSeconds = durationSeconds
        self.status = status
    }
}

/// Manages data model migrations across SDK versions.
@MainActor
public final class SDKMigrationManager: SDKMigrationManagerProtocol, ObservableObject {
    nonisolated(unsafe) public static let shared = SDKMigrationManager()

    @Published public private(set) var currentVersion: Int = 0
    @Published public private(set) var migrationHistory: [SDKMigrationRecord] = []
    @Published public private(set) var isRunning: Bool = false

    private var registeredMigrations: [SDKMigrationStep] = []
    private let versionKey = "sdk_schema_version"
    private let historyKey = "sdk_migration_history_v1"

    private init() {
        loadCurrentVersion()
        loadHistory()
    }

    public func registerMigration(_ migration: SDKMigrationStep) {
        guard !registeredMigrations.contains(where: { $0.id == migration.id }) else { return }
        registeredMigrations.append(migration)
        registeredMigrations.sort { $0.fromVersion < $1.fromVersion }
    }

    public var pendingMigrations: [SDKMigrationStep] {
        registeredMigrations.filter { $0.fromVersion >= currentVersion }
    }

    public func runPendingMigrations() async throws {
        guard !isRunning else { return }
        isRunning = true

        let pending = pendingMigrations
        guard !pending.isEmpty else {
            isRunning = false
            return
        }

        SDKEventBus.shared.publish(SDKBusEvent(
            channel: "sdk.migration",
            name: "migration.started",
            data: ["pending": "\(pending.count)", "currentVersion": "\(currentVersion)"]
        ))

        for migration in pending {
            let startTime = Date()
            do {
                try await migration.migrate()
                let duration = Date().timeIntervalSince(startTime)
                let record = SDKMigrationRecord(
                    migrationID: migration.id,
                    fromVersion: migration.fromVersion,
                    toVersion: migration.toVersion,
                    durationSeconds: duration,
                    status: .success
                )
                migrationHistory.insert(record, at: 0)
                currentVersion = migration.toVersion
                saveCurrentVersion()
                saveHistory()

                SDKEventBus.shared.publish(SDKBusEvent(
                    channel: "sdk.migration",
                    name: "migration.stepCompleted",
                    data: [
                        "id": migration.id,
                        "from": "\(migration.fromVersion)",
                        "to": "\(migration.toVersion)",
                        "duration": String(format: "%.2f", duration)
                    ]
                ))
            } catch {
                let duration = Date().timeIntervalSince(startTime)
                let record = SDKMigrationRecord(
                    migrationID: migration.id,
                    fromVersion: migration.fromVersion,
                    toVersion: migration.toVersion,
                    durationSeconds: duration,
                    status: .failed
                )
                migrationHistory.insert(record, at: 0)
                saveHistory()
                isRunning = false

                SDKEventBus.shared.publish(SDKBusEvent(
                    channel: "sdk.migration",
                    name: "migration.failed",
                    data: ["id": migration.id, "error": error.localizedDescription]
                ))

                throw SDKDataError.migrationFailed(
                    fromVersion: migration.fromVersion,
                    toVersion: migration.toVersion,
                    reason: error.localizedDescription
                )
            }
        }

        isRunning = false

        SDKEventBus.shared.publish(SDKBusEvent(
            channel: "sdk.migration",
            name: "migration.completed",
            data: ["version": "\(currentVersion)"]
        ))
    }

    public func setVersion(_ version: Int) {
        currentVersion = version
        saveCurrentVersion()
    }

    public var hasPendingMigrations: Bool {
        !pendingMigrations.isEmpty
    }

    private func loadCurrentVersion() {
        currentVersion = UserDefaults.standard.integer(forKey: versionKey)
    }

    private func saveCurrentVersion() {
        UserDefaults.standard.set(currentVersion, forKey: versionKey)
    }

    private func loadHistory() {
        guard let data = UserDefaults.standard.data(forKey: historyKey),
              let loaded = try? JSONDecoder().decode([SDKMigrationRecord].self, from: data)
        else { return }
        migrationHistory = loaded
    }

    private func saveHistory() {
        if let data = try? JSONEncoder().encode(migrationHistory) {
            UserDefaults.standard.set(data, forKey: historyKey)
        }
    }
}
