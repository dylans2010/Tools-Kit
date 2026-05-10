// ToolsKit — SDKCancellationManager.swift
// SDK Expansion — Phase 3

import Foundation
import Combine

/// Protocol for managing async task cancellation.
@MainActor
public protocol SDKCancellationManagerProtocol: AnyObject {
    func register(id: String, task: Task<Void, Never>)
    func cancel(id: String)
    func cancelAll()
    func isActive(id: String) -> Bool
    var activeTaskIDs: [String] { get }
}

/// Centralized manager for tracking and cancelling async operations across the SDK.
@MainActor
public final class SDKCancellationManager: SDKCancellationManagerProtocol, ObservableObject {
    public static let shared = SDKCancellationManager()

    @Published public private(set) var activeTasks: [String: TaskRecord] = [:]

    public struct TaskRecord: Identifiable {
        public let id: String
        public let registeredAt: Date
        public let label: String

        public init(id: String, label: String = "") {
            self.id = id
            self.registeredAt = Date()
            self.label = label
        }
    }

    private var tasks: [String: Task<Void, Never>] = [:]

    private init() {}

    public func register(id: String, task: Task<Void, Never>) {
        tasks[id]?.cancel()
        tasks[id] = task
        activeTasks[id] = TaskRecord(id: id, label: id)
        SDKEventBus.shared.publish(SDKBusEvent(
            channel: "sdk.tasks",
            name: "task.registered",
            data: ["id": id]
        ))
    }

    public func register(id: String, label: String, operation: @escaping @Sendable () async -> Void) {
        tasks[id]?.cancel()
        let task = Task { await operation() }
        tasks[id] = task
        activeTasks[id] = TaskRecord(id: id, label: label)
    }

    public func cancel(id: String) {
        guard let task = tasks.removeValue(forKey: id) else { return }
        task.cancel()
        activeTasks.removeValue(forKey: id)
        SDKEventBus.shared.publish(SDKBusEvent(
            channel: "sdk.tasks",
            name: "task.cancelled",
            data: ["id": id]
        ))
    }

    public func cancelAll() {
        for (_, task) in tasks {
            task.cancel()
        }
        tasks.removeAll()
        activeTasks.removeAll()
        SDKEventBus.shared.publish(SDKBusEvent(
            channel: "sdk.tasks",
            name: "tasks.allCancelled",
            data: [:]
        ))
    }

    public func isActive(id: String) -> Bool {
        guard let task = tasks[id] else { return false }
        return !task.isCancelled
    }

    public var activeTaskIDs: [String] {
        Array(activeTasks.keys).sorted()
    }

    public var activeCount: Int {
        tasks.filter { !$0.value.isCancelled }.count
    }

    public func cleanup() {
        let cancelledIDs = tasks.filter { $0.value.isCancelled }.map { $0.key }
        for id in cancelledIDs {
            tasks.removeValue(forKey: id)
            activeTasks.removeValue(forKey: id)
        }
    }
}
