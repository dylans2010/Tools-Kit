import Foundation
import Combine

@MainActor
public final class SDKTestHarness: ObservableObject {
    nonisolated(unsafe) public static let shared = SDKTestHarness()

    @Published public private(set) var testSuites: [SDKTestSuite] = []
    @Published public private(set) var isRunning = false
    @Published public private(set) var lastRunResult: TestRunResult?
    @Published public private(set) var runHistory: [TestRunResult] = []

    private init() {}

    // MARK: - Suite Management

    public func registerSuite(_ suite: SDKTestSuite) {
        if let index = testSuites.firstIndex(where: { $0.id == suite.id }) {
            testSuites[index] = suite
        } else {
            testSuites.append(suite)
        }
    }

    public func removeSuite(id: UUID) {
        testSuites.removeAll { $0.id == id }
    }

    // MARK: - Execution

    public func runAll() async -> TestRunResult {
        isRunning = true
        defer { isRunning = false }

        let startTime = Date()
        var caseResults: [TestCaseResult] = []

        for suite in testSuites {
            let suiteResults = await runSuite(suite)
            caseResults.append(contentsOf: suiteResults)
        }

        let result = TestRunResult(
            caseResults: caseResults,
            startedAt: startTime,
            completedAt: Date()
        )
        lastRunResult = result
        runHistory.append(result)

        SDKEventBus.shared.publish(SDKBusEvent(
            channel: "sdk.test",
            name: "run.completed",
            data: [
                "passed": "\(result.passedCount)",
                "failed": "\(result.failedCount)",
                "total": "\(result.totalCount)"
            ]
        ))
        return result
    }

    public func runSuite(_ suite: SDKTestSuite) async -> [TestCaseResult] {
        var results: [TestCaseResult] = []

        for testCase in suite.cases {
            let result = await runCase(testCase, suiteName: suite.name)
            results.append(result)
        }
        return results
    }

    public func runCase(_ testCase: SDKTestCase, suiteName: String) async -> TestCaseResult {
        let startTime = Date()
        do {
            try await testCase.body()
            return TestCaseResult(
                suiteName: suiteName,
                caseName: testCase.name,
                status: .passed,
                duration: Date().timeIntervalSince(startTime)
            )
        } catch {
            return TestCaseResult(
                suiteName: suiteName,
                caseName: testCase.name,
                status: .failed,
                duration: Date().timeIntervalSince(startTime),
                errorMessage: error.localizedDescription
            )
        }
    }

    // MARK: - Built-in Suites

    public func registerDefaultSuites() {
        let healthSuite = SDKTestSuite(name: "SDK Health", cases: [
            SDKTestCase(name: "Kernel is ready") {
                guard WorkspaceSDKKernel.shared.isReady else {
                    throw TestAssertionError(message: "Kernel not ready")
                }
            },
            SDKTestCase(name: "Event bus is functional") {
                var received = false
                let sub = SDKEventBus.shared.subscribe(channel: "test.probe") { _ in received = true }
                SDKEventBus.shared.publish(SDKBusEvent(channel: "test.probe", name: "ping", data: [:]))
                try await Task.sleep(nanoseconds: 100_000_000)
                sub.cancel()
                guard received else { throw TestAssertionError(message: "Event bus did not deliver") }
            },
            SDKTestCase(name: "Router responds") {
                let routes = SDKRouter.shared.routes()
                guard !routes.isEmpty else {
                    throw TestAssertionError(message: "No routes registered")
                }
            }
        ])
        registerSuite(healthSuite)
    }
}

// MARK: - Models

public struct SDKTestSuite: Identifiable, Sendable {
    public let id: UUID
    public let name: String
    public var cases: [SDKTestCase]

    public init(name: String, cases: [SDKTestCase] = []) {
        self.id = UUID()
        self.name = name
        self.cases = cases
    }
}

public struct SDKTestCase: Identifiable, @unchecked Sendable {
    public let id: UUID
    public let name: String
    public let body: () async throws -> Void

    public init(name: String, body: @escaping () async throws -> Void) {
        self.id = UUID()
        self.name = name
        self.body = body
    }
}

public struct TestCaseResult: Identifiable, Sendable {
    public let id: UUID
    public let suiteName: String
    public let caseName: String
    public let status: TestStatus
    public let duration: TimeInterval
    public let errorMessage: String?

    public init(suiteName: String, caseName: String, status: TestStatus, duration: TimeInterval, errorMessage: String? = nil) {
        self.id = UUID()
        self.suiteName = suiteName
        self.caseName = caseName
        self.status = status
        self.duration = duration
        self.errorMessage = errorMessage
    }
}

public struct TestRunResult: Identifiable, Sendable {
    public let id: UUID
    public let caseResults: [TestCaseResult]
    public let startedAt: Date
    public let completedAt: Date

    public var totalCount: Int { caseResults.count }
    public var passedCount: Int { caseResults.count(where: { $0.status == .passed }) }
    public var failedCount: Int { caseResults.count(where: { $0.status == .failed }) }
    public var skippedCount: Int { caseResults.count(where: { $0.status == .skipped }) }
    public var allPassed: Bool { failedCount == 0 && totalCount > 0 }
    public var duration: TimeInterval { completedAt.timeIntervalSince(startedAt) }

    public init(caseResults: [TestCaseResult], startedAt: Date, completedAt: Date) {
        self.id = UUID()
        self.caseResults = caseResults
        self.startedAt = startedAt
        self.completedAt = completedAt
    }
}

public enum TestStatus: String, Codable, Sendable {
    case passed, failed, skipped, running
}

public struct TestAssertionError: LocalizedError, Sendable {
    public let message: String
    public var errorDescription: String? { message }

    public init(message: String) {
        self.message = message
    }
}
