// ToolsKit — SDKRetryPolicy.swift
// SDK Expansion — Phase 3

import Foundation

/// Protocol for defining retry behavior.
public protocol SDKRetryPolicyProtocol: Sendable {
    var maxAttempts: Int { get }
    func delay(for attempt: Int) -> TimeInterval
    func shouldRetry(error: Error, attempt: Int) -> Bool
}

/// Configurable retry policy with exponential backoff and jitter.
public struct SDKRetryPolicy: SDKRetryPolicyProtocol, Sendable {
    public let maxAttempts: Int
    public let baseDelay: TimeInterval
    public let maxDelay: TimeInterval
    public let multiplier: Double
    public let jitterEnabled: Bool

    public init(
        maxAttempts: Int = 3,
        baseDelay: TimeInterval = 1.0,
        maxDelay: TimeInterval = 30.0,
        multiplier: Double = 2.0,
        jitterEnabled: Bool = true
    ) {
        self.maxAttempts = max(1, maxAttempts)
        self.baseDelay = max(0, baseDelay)
        self.maxDelay = max(baseDelay, maxDelay)
        self.multiplier = max(1.0, multiplier)
        self.jitterEnabled = jitterEnabled
    }

    public func delay(for attempt: Int) -> TimeInterval {
        let exponential = baseDelay * pow(multiplier, Double(attempt))
        let clamped = min(exponential, maxDelay)
        if jitterEnabled {
            let jitter = Double.random(in: 0...(clamped * 0.25))
            return clamped + jitter
        }
        return clamped
    }

    public func shouldRetry(error: Error, attempt: Int) -> Bool {
        guard attempt < maxAttempts else { return false }
        if error is CancellationError { return false }
        if let networkError = error as? SDKNetworkError {
            switch networkError {
            case .cancelled: return false
            case .invalidURL: return false
            default: return true
            }
        }
        return true
    }

    /// Predefined policies for common use cases.
    public static let `default` = SDKRetryPolicy()

    public static let aggressive = SDKRetryPolicy(
        maxAttempts: 5,
        baseDelay: 0.5,
        maxDelay: 60.0,
        multiplier: 2.0
    )

    public static let conservative = SDKRetryPolicy(
        maxAttempts: 2,
        baseDelay: 2.0,
        maxDelay: 10.0,
        multiplier: 1.5,
        jitterEnabled: false
    )

    public static let noRetry = SDKRetryPolicy(
        maxAttempts: 1,
        baseDelay: 0,
        maxDelay: 0
    )
}

/// Retry execution result containing outcome and attempt metadata.
public struct SDKRetryResult<T: Sendable>: Sendable {
    public let value: T
    public let attempts: Int
    public let totalDuration: TimeInterval

    public init(value: T, attempts: Int, totalDuration: TimeInterval) {
        self.value = value
        self.attempts = attempts
        self.totalDuration = totalDuration
    }
}

/// Executor that applies a retry policy to an async operation.
public actor SDKRetryExecutor {
    nonisolated(unsafe) public static let shared = SDKRetryExecutor()

    private var executionCount: Int = 0

    private init() {}

    public func execute<T: Sendable>(
        policy: SDKRetryPolicyProtocol,
        operation: @Sendable () async throws -> T
    ) async throws -> SDKRetryResult<T> {
        let startTime = Date()
        var lastError: Error?
        executionCount += 1

        for attempt in 0..<policy.maxAttempts {
            do {
                let result = try await operation()
                return SDKRetryResult(
                    value: result,
                    attempts: attempt + 1,
                    totalDuration: Date().timeIntervalSince(startTime)
                )
            } catch {
                lastError = error
                if !policy.shouldRetry(error: error, attempt: attempt) {
                    throw error
                }
                if attempt < policy.maxAttempts - 1 {
                    let delay = policy.delay(for: attempt)
                    try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                }
            }
        }

        throw lastError ?? SDKKernelError.timeout(operation: "retry", seconds: Date().timeIntervalSince(startTime))
    }

    public func totalExecutions() -> Int {
        executionCount
    }
}
