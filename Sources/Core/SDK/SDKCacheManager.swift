// ToolsKit — SDKCacheManager.swift
// SDK Expansion — Phase 3

import Foundation
import Combine

/// Protocol for SDK cache operations.
@MainActor
public protocol SDKCacheManagerProtocol: AnyObject {
    func set<T: Codable & Sendable>(_ value: T, forKey key: String, ttl: TimeInterval?)
    func get<T: Codable & Sendable>(_ type: T.Type, forKey key: String) -> T?
    func remove(forKey key: String)
    func removeAll()
    var entryCount: Int { get }
    var totalSizeBytes: Int { get }
}

/// In-memory cache with optional TTL expiration and size tracking.
@MainActor
public final class SDKCacheManager: SDKCacheManagerProtocol, ObservableObject {
    nonisolated(unsafe) public static let shared = SDKCacheManager()

    @Published public private(set) var entryCount: Int = 0
    @Published public private(set) var totalSizeBytes: Int = 0
    @Published public private(set) var hitCount: Int = 0
    @Published public private(set) var missCount: Int = 0

    private var storage: [String: CacheEntry] = [:]
    private let maxEntries: Int
    private let maxSizeBytes: Int

    private struct CacheEntry: Sendable {
        let data: Data
        let createdAt: Date
        let expiresAt: Date?
        let key: String

        var isExpired: Bool {
            guard let expiresAt = expiresAt else { return false }
            return Date() >= expiresAt
        }
    }

    private init(maxEntries: Int = 500, maxSizeBytes: Int = 50 * 1024 * 1024) {
        self.maxEntries = maxEntries
        self.maxSizeBytes = maxSizeBytes
    }

    public func set<T: Codable & Sendable>(_ value: T, forKey key: String, ttl: TimeInterval? = nil) {
        guard let data = try? JSONEncoder().encode(value) else { return }

        let expiresAt = ttl.map { Date().addingTimeInterval($0) }
        let entry = CacheEntry(data: data, createdAt: Date(), expiresAt: expiresAt, key: key)
        storage[key] = entry

        evictIfNeeded()
        updateStats()
    }

    public func get<T: Codable & Sendable>(_ type: T.Type, forKey key: String) -> T? {
        guard let entry = storage[key] else {
            missCount += 1
            return nil
        }

        if entry.isExpired {
            storage.removeValue(forKey: key)
            updateStats()
            missCount += 1
            return nil
        }

        hitCount += 1
        return try? JSONDecoder().decode(T.self, from: entry.data)
    }

    public func remove(forKey key: String) {
        storage.removeValue(forKey: key)
        updateStats()
    }

    public func removeAll() {
        storage.removeAll()
        updateStats()
    }

    public func removeExpired() {
        let expiredKeys = storage.filter { $0.value.isExpired }.map { $0.key }
        for key in expiredKeys {
            storage.removeValue(forKey: key)
        }
        updateStats()
    }

    public var hitRate: Double {
        let total = hitCount + missCount
        guard total > 0 else { return 0 }
        return Double(hitCount) / Double(total)
    }

    public func keys() -> [String] {
        Array(storage.keys).sorted()
    }

    public func contains(key: String) -> Bool {
        guard let entry = storage[key] else { return false }
        return !entry.isExpired
    }

    public func entryInfo(forKey key: String) -> CacheEntryInfo? {
        guard let entry = storage[key] else { return nil }
        return CacheEntryInfo(
            key: key,
            sizeBytes: entry.data.count,
            createdAt: entry.createdAt,
            expiresAt: entry.expiresAt,
            isExpired: entry.isExpired
        )
    }

    public func allEntryInfo() -> [CacheEntryInfo] {
        storage.map { key, entry in
            CacheEntryInfo(
                key: key,
                sizeBytes: entry.data.count,
                createdAt: entry.createdAt,
                expiresAt: entry.expiresAt,
                isExpired: entry.isExpired
            )
        }
        .sorted { $0.createdAt > $1.createdAt }
    }

    public func resetStats() {
        hitCount = 0
        missCount = 0
    }

    private func evictIfNeeded() {
        while storage.count > maxEntries {
            let oldest = storage.min { $0.value.createdAt < $1.value.createdAt }
            if let key = oldest?.key {
                storage.removeValue(forKey: key)
            }
        }

        var currentSize = storage.values.reduce(0) { $0 + $1.data.count }
        while currentSize > maxSizeBytes, !storage.isEmpty {
            let oldest = storage.min { $0.value.createdAt < $1.value.createdAt }
            if let key = oldest?.key, let entry = storage.removeValue(forKey: key) {
                currentSize -= entry.data.count
            }
        }
    }

    private func updateStats() {
        entryCount = storage.count
        totalSizeBytes = storage.values.reduce(0) { $0 + $1.data.count }
    }
}

/// Public info about a cache entry.
public struct CacheEntryInfo: Identifiable, Sendable {
    public let id: String
    public let key: String
    public let sizeBytes: Int
    public let createdAt: Date
    public let expiresAt: Date?
    public let isExpired: Bool

    public init(key: String, sizeBytes: Int, createdAt: Date, expiresAt: Date?, isExpired: Bool) {
        self.id = key
        self.key = key
        self.sizeBytes = sizeBytes
        self.createdAt = createdAt
        self.expiresAt = expiresAt
        self.isExpired = isExpired
    }
}
