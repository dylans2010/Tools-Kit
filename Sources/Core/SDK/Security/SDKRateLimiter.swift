import Foundation

public actor SDKRateLimiter {
    nonisolated(unsafe) public static let shared = SDKRateLimiter()

    public struct Rule: Sendable {
        public let requestsPerMinute: Int
        public let dataFetchLimit: Int
        public let executionFrequencyCap: Int

        public init(requestsPerMinute: Int, dataFetchLimit: Int, executionFrequencyCap: Int) {
            self.requestsPerMinute = requestsPerMinute
            self.dataFetchLimit = dataFetchLimit
            self.executionFrequencyCap = executionFrequencyCap
        }
    }

    public struct UsageSnapshot: Codable, Sendable {
        public let key: String
        public let requestsInWindow: Int
        public let fetchUnitsInWindow: Int
        public let executionsInWindow: Int
        public let requestsPerMinute: Int
        public let dataFetchLimit: Int
        public let executionFrequencyCap: Int
    }

    private struct WindowCounters: Sendable {
        var start: Date
        var requests: Int
        var fetchUnits: Int
        var executions: Int
    }

    private struct TokenBucket: Sendable {
        var tokens: Double
        var lastRefill: Date
        let capacity: Double
        let refillPerSecond: Double
    }

    private var counters: [String: WindowCounters] = [:]
    private var buckets: [String: TokenBucket] = [:]

    private init() {}

    public func enforce(key: String, rule: Rule, fetchUnits: Int = 0, executions: Int = 1) throws -> UsageSnapshot {
        let now = Date()
        var counter = counters[key] ?? WindowCounters(start: now, requests: 0, fetchUnits: 0, executions: 0)

        if now.timeIntervalSince(counter.start) >= 60 {
            counter = WindowCounters(start: now, requests: 0, fetchUnits: 0, executions: 0)
        }

        var bucket = buckets[key] ?? TokenBucket(
            tokens: Double(rule.requestsPerMinute),
            lastRefill: now,
            capacity: Double(rule.requestsPerMinute),
            refillPerSecond: Double(rule.requestsPerMinute) / 60.0
        )

        let elapsed = now.timeIntervalSince(bucket.lastRefill)
        if elapsed > 0 {
            bucket.tokens = min(bucket.capacity, bucket.tokens + elapsed * bucket.refillPerSecond)
            bucket.lastRefill = now
        }

        guard bucket.tokens >= 1 else {
            throw SDKError.executionFailed(reason: "Rate limit exceeded for \(key): requests per minute")
        }

        if counter.fetchUnits + fetchUnits > rule.dataFetchLimit {
            throw SDKError.executionFailed(reason: "Rate limit exceeded for \(key): data fetch limit")
        }

        if counter.executions + executions > rule.executionFrequencyCap {
            throw SDKError.executionFailed(reason: "Rate limit exceeded for \(key): execution frequency")
        }

        bucket.tokens -= 1
        counter.requests += 1
        counter.fetchUnits += fetchUnits
        counter.executions += executions

        buckets[key] = bucket
        counters[key] = counter

        return UsageSnapshot(
            key: key,
            requestsInWindow: counter.requests,
            fetchUnitsInWindow: counter.fetchUnits,
            executionsInWindow: counter.executions,
            requestsPerMinute: rule.requestsPerMinute,
            dataFetchLimit: rule.dataFetchLimit,
            executionFrequencyCap: rule.executionFrequencyCap
        )
    }

    public func currentUsage() -> [UsageSnapshot] {
        counters.map { key, counter in
            let rpm = Int(buckets[key]?.capacity ?? 60)
            return UsageSnapshot(
                key: key,
                requestsInWindow: counter.requests,
                fetchUnitsInWindow: counter.fetchUnits,
                executionsInWindow: counter.executions,
                requestsPerMinute: rpm,
                dataFetchLimit: max(counter.fetchUnits, 1),
                executionFrequencyCap: max(counter.executions, 1)
            )
        }
        .sorted { $0.key < $1.key }
    }

    public func resetAllCounters() {
        counters.removeAll()
        buckets.removeAll()
    }
}
