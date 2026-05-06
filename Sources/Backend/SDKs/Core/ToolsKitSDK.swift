import Foundation

/// The primary entry point for SDK-based data access and orchestration.
public final class ToolsKitSDK {
    public static let shared = ToolsKitSDK()

    internal let api = WorkspaceAPI.shared
    private let permissionManager = SDKPermissionManager.shared
    private let cacheManager = SDKCacheManager.shared

    private init() {}

    /// The central data pipeline for all SDK tools.
    /// Fetches, streams, diffs, and transforms workspace data based on the request.
    public func fetchData(_ request: SDKFetchRequest) async throws -> SDKFetchResult {
        let startTime = Date()

        // 1. Validate Scopes (Bypass if NoSandbox scope is present)
        if !request.scopes.contains(.sdkDeveloperNoSandbox) {
            try validateScopes(request.scopes)
        } else {
            SDKConsoleView.LogBus.shared.log("fetchData: Bypassing scope validation (NoSandbox Mode)", type: .warning)
        }

        // 2. Check Cache if enabled
        if let cachedResult = cacheManager.get(request) {
            return updatePerformanceMetrics(cachedResult, startTime: startTime, cacheHit: true)
        }

        // 3. Resolve Data Sources and Fetch (Parallel)
        var allNodes: [SDKDataNode] = []

        try await withThrowingTaskGroup(of: [SDKDataNode].self) { group in
            for dataType in request.dataTypes {
                group.addTask {
                    return try await self.fetchSourceData(dataType, filters: request.filters)
                }
            }

            for try await nodes in group {
                allNodes.append(contentsOf: nodes)
            }
        }

        // 4. Apply Pagination (Limit/Offset)
        let totalCount = allNodes.count
        let paginatedNodes = applyPagination(allNodes, limit: request.limit, offset: request.offset)

        // 5. Attach Relationships
        var relations: [SDKRelation] = []
        if request.includeRelations {
            relations = try resolveRelationships(for: paginatedNodes)
        }

        // 6. Attach History or Diff
        var timeline: [SDKTimelineEvent] = []
        var diffResult: SDKDiffResult?

        if request.includeHistory || request.mode == .snapshot {
            timeline = try fetchTimeline(for: paginatedNodes)
        }

        if request.includeDiff || request.mode == .diff {
            diffResult = try calculateDiff(for: paginatedNodes)
        }

        // 7. Construct Result
        let metadata = SDKMetadata(
            totalCount: totalCount,
            resultCount: paginatedNodes.count,
            sourceSystems: request.dataTypes.map { $0.rawValue },
            permissionsGranted: request.scopes
        )

        let performance = SDKPerformanceMetrics(
            fetchTime: Date().timeIntervalSince(startTime),
            processingTime: Date().timeIntervalSince(startTime) * 0.1, // Simulated
            cacheHit: false,
            parallelExecution: request.dataTypes.count > 1
        )

        let result = SDKFetchResult(
            data: paginatedNodes,
            relations: relations,
            metadata: metadata,
            timeline: timeline,
            diff: diffResult,
            performance: performance
        )

        // 8. Cache Result
        cacheManager.set(result, for: request)

        return result
    }

    // MARK: - Private Helpers

    private func validateScopes(_ scopes: [PluginCapability]) throws {
        for scope in scopes {
            if !permissionManager.isScopeAuthorized(scope.rawValue) {
                throw SDKError.permissionDenied(scope: scope.rawValue)
            }
        }
    }

    private func fetchSourceData(_ type: SDKDataType, filters: SDKDataFilter) async throws -> [SDKDataNode] {
        let nodes: [SDKDataNode]
        switch type {
        case .notes:
            nodes = api.notes.listNotes().map { node in
                SDKDataNode(id: node.id.uuidString, type: .notes, title: node.title, content: node.content, createdAt: node.createdAt, updatedAt: node.updatedAt)
            }
        case .tasks:
            nodes = api.tasks.listTasks().map { node in
                SDKDataNode(id: node.id.uuidString, type: .tasks, title: node.title, content: node.description, createdAt: node.createdAt, updatedAt: node.createdAt)
            }
        case .mail:
            nodes = api.mail.listMessages().map { node in
                SDKDataNode(id: node.id, type: .mail, title: node.subject, content: node.body, createdAt: node.date, updatedAt: node.date)
            }
        case .calendar:
            nodes = await MainActor.run {
                api.calendar.listEvents().map { node in
                    SDKDataNode(id: node.id.uuidString, type: .calendar, title: node.title, content: node.location, createdAt: node.startTime, updatedAt: node.endTime)
                }
            }
        case .files:
            nodes = api.files.listFiles().map { node in
                SDKDataNode(id: node.id, type: .files, title: node.name, content: node.path, createdAt: node.createdAt, updatedAt: node.updatedAt)
            }
        case .whiteboards:
            nodes = [] // Map when available
        case .slides:
            nodes = api.slides.listDecks().map { node in
                SDKDataNode(id: node.id.uuidString, type: .slides, title: node.title, content: "\(node.slides.count) slides", createdAt: node.createdAt, updatedAt: node.updatedAt)
            }
        case .media:
            nodes = []
        case .meet:
            nodes = []
        case .github:
            nodes = []
        case .automation:
            nodes = []
        case .intelligence:
            nodes = []
        case .collaboration:
            nodes = []
        case .persona:
            nodes = []
        case .timeTravelSnapshots:
            nodes = api.timeTravel.listSnapshots().map { node in
                SDKDataNode(id: node.id.uuidString, type: .timeTravelSnapshots, title: node.message, content: node.deviceInfo, createdAt: node.timestamp, updatedAt: node.timestamp)
            }
        }

        return applyFilters(nodes, filters: filters)
    }

    private func applyFilters(_ nodes: [SDKDataNode], filters: SDKDataFilter) -> [SDKDataNode] {
        return nodes.filter { node in
            if let query = filters.query?.lowercased() {
                guard node.title.lowercased().contains(query) || node.content.lowercased().contains(query) else { return false }
            }
            if let start = filters.startDate, node.createdAt < start { return false }
            if let end = filters.endDate, node.createdAt > end { return false }
            if let status = filters.status, node.metadata["status"] != status { return false }
            return true
        }
    }

    private func applyPagination(_ nodes: [SDKDataNode], limit: Int, offset: Int) -> [SDKDataNode] {
        guard offset < nodes.count else { return [] }
        let end = min(offset + limit, nodes.count)
        return Array(nodes[offset..<end])
    }

    private func resolveRelationships(for nodes: [SDKDataNode]) throws -> [SDKRelation] {
        // Integrate with Intelligence graph
        let graph = api.intelligence.getGraph()
        // Simulated mapping for SDK demonstration
        return nodes.enumerated().compactMap { index, node in
            if index > 0 {
                return SDKRelation(sourceID: nodes[index-1].id, targetID: node.id, type: "relates_to")
            }
            return nil
        }
    }

    private func fetchTimeline(for nodes: [SDKDataNode]) throws -> [SDKTimelineEvent] {
        return nodes.map { node in
            SDKTimelineEvent(eventType: "fetch", description: "Fetched \(node.type.rawValue) node: \(node.title)", dataNodeID: node.id)
        }
    }

    private func calculateDiff(for nodes: [SDKDataNode]) throws -> SDKDiffResult {
        // Simplified diff for Demo
        return SDKDiffResult(added: nodes, removed: [], modified: [])
    }

    private func updatePerformanceMetrics(_ result: SDKFetchResult, startTime: Date, cacheHit: Bool) -> SDKFetchResult {
        let metrics = SDKPerformanceMetrics(
            fetchTime: Date().timeIntervalSince(startTime),
            processingTime: 0.001,
            cacheHit: cacheHit,
            parallelExecution: false
        )
        return SDKFetchResult(data: result.data, relations: result.relations, metadata: result.metadata, timeline: result.timeline, diff: result.diff, performance: metrics)
    }
}

/// Simple thread-safe cache for SDK fetch requests
public final class SDKCacheManager {
    public static let shared = SDKCacheManager()
    private var cache: [String: SDKFetchResult] = [:]
    private let lock = NSRecursiveLock()

    private init() {}

    func get(_ request: SDKFetchRequest) -> SDKFetchResult? {
        lock.lock(); defer { lock.unlock() }
        let key = cacheKey(for: request)
        return cache[key]
    }

    func set(_ result: SDKFetchResult, for request: SDKFetchRequest) {
        lock.lock(); defer { lock.unlock() }
        let key = cacheKey(for: request)
        cache[key] = result
    }

    private func cacheKey(for request: SDKFetchRequest) -> String {
        let types = request.dataTypes.map { $0.rawValue }.joined(separator: ",")
        return "\(types)-\(request.mode.rawValue)-\(request.limit)-\(request.offset)"
    }
}
