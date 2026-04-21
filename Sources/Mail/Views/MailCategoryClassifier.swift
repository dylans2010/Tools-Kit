import Foundation
import SwiftUI

enum InboxCategory: String, CaseIterable, Identifiable {
    case all = "All"
    case primary = "Primary"
    case transactions = "Transactions"
    case offers = "Offers"
    case updates = "Updates"

    var id: String { rawValue }

    var title: String { rawValue }

    var tint: Color {
        switch self {
        case .all: return .gray
        case .primary: return .blue
        case .transactions: return .green
        case .offers: return .orange
        case .updates: return .purple
        }
    }

    static var selectableCases: [InboxCategory] {
        [.all, .primary, .transactions, .offers, .updates]
    }
}

enum MailCategoryClassifier {
    private static let cacheLock = NSLock()
    private static var categoryCache: [String: InboxCategory] = [:]
    private static let maxAnalyzedCharacters = 8_000

    static func category(for thread: MailThread) -> InboxCategory {
        let latest = thread.messages.last
        let cacheKey = "\(thread.id)|\(latest?.id ?? "")|\(latest?.date.timeIntervalSince1970 ?? 0)"

        cacheLock.lock()
        if let cached = categoryCache[cacheKey] {
            cacheLock.unlock()
            return cached
        }
        cacheLock.unlock()

        let text = [
            latest?.subject ?? thread.subject,
            latest?.from ?? "",
            latest?.body.prefix(maxAnalyzedCharacters / 2) ?? thread.snippet,
            thread.snippet
        ]
        .joined(separator: " ")
        .lowercased()
        let features = buildFeatures(from: text)

        let transactionScore = score(
            features: features,
            keys: ["invoice", "receipt", "payment", "order", "subscription", "billing", "statement", "transaction", "refund", "shipped"]
        )
        let offersScore = score(
            features: features,
            keys: ["discount", "sale", "offer", "promo", "coupon", "deal", "limited", "save", "off", "black friday"]
        )
        let updatesScore = score(
            features: features,
            keys: ["newsletter", "update", "digest", "announcement", "news", "release", "notification", "policy", "terms"]
        )
        let primaryScore = score(
            features: features,
            keys: ["meeting", "project", "follow up", "action required", "please review", "team", "request", "urgent"]
        )

        let ranked: [(InboxCategory, Double)] = [
            (.transactions, transactionScore),
            (.offers, offersScore),
            (.updates, updatesScore),
            (.primary, primaryScore)
        ]

        let resolved: InboxCategory
        if let best = ranked.max(by: { $0.1 < $1.1 }), best.1 > 0 {
            resolved = best.0
        } else {
            resolved = .primary
        }

        cacheLock.lock()
        categoryCache[cacheKey] = resolved
        cacheLock.unlock()
        return resolved
    }

    private static func buildFeatures(from text: String) -> [String: Double] {
        let boundedText = text.count > maxAnalyzedCharacters ? String(text.prefix(maxAnalyzedCharacters)) : text
        let normalized = boundedText
            .replacingOccurrences(of: "[^a-z0-9\\s]", with: " ", options: .regularExpression)
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
        let tokens = normalized.split(separator: " ").map(String.init)
        var counts: [String: Double] = [:]
        for token in tokens {
            counts[token, default: 0] += 1
        }

        if normalized.contains("black friday") {
            counts["black friday", default: 0] += 1
        }
        if normalized.contains("follow up") {
            counts["follow up", default: 0] += 1
        }
        if normalized.contains("action required") {
            counts["action required", default: 0] += 1
        }

        return counts
    }

    private static func score(features: [String: Double], keys: [String]) -> Double {
        return keys.reduce(0) { partialResult, key in
            partialResult + (features[key] ?? 0)
        }
    }
}
