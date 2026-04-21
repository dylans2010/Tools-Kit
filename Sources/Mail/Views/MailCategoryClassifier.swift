import CoreML
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
    static func category(for thread: MailThread) -> InboxCategory {
        let latest = thread.messages.last
        let text = [
            latest?.subject ?? thread.subject,
            latest?.from ?? "",
            latest?.body ?? thread.snippet,
            thread.snippet
        ]
        .joined(separator: " ")
        .lowercased()

        let features = buildFeatures(from: text)
        let provider = try? MLDictionaryFeatureProvider(
            dictionary: features.reduce(into: [String: MLFeatureValue]()) { partialResult, item in
                partialResult[item.key] = MLFeatureValue(double: item.value)
            }
        )

        let transactionScore = score(
            provider: provider,
            keys: ["invoice", "receipt", "payment", "order", "subscription", "billing", "statement", "transaction", "refund", "shipped"]
        )
        let offersScore = score(
            provider: provider,
            keys: ["discount", "sale", "offer", "promo", "coupon", "deal", "limited", "save", "off", "black friday"]
        )
        let updatesScore = score(
            provider: provider,
            keys: ["newsletter", "update", "digest", "announcement", "news", "release", "notification", "policy", "terms"]
        )
        let primaryScore = score(
            provider: provider,
            keys: ["meeting", "project", "follow up", "action required", "please review", "team", "request", "urgent"]
        )

        let ranked: [(InboxCategory, Double)] = [
            (.transactions, transactionScore),
            (.offers, offersScore),
            (.updates, updatesScore),
            (.primary, primaryScore)
        ]

        if let best = ranked.max(by: { $0.1 < $1.1 }), best.1 > 0 {
            return best.0
        }
        return .primary
    }

    private static func buildFeatures(from text: String) -> [String: Double] {
        let normalized = text
            .replacingOccurrences(of: "[^a-z0-9\\s]", with: " ", options: .regularExpression)
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
        let tokens = normalized.split(separator: " ").map(String.init)
        var counts: [String: Double] = [:]
        for token in tokens {
            counts[token, default: 0] += 1
        }
        return counts
    }

    private static func score(provider: MLFeatureProvider?, keys: [String]) -> Double {
        guard let provider else { return 0 }
        return keys.reduce(0) { partialResult, key in
            partialResult + (provider.featureValue(for: key)?.doubleValue ?? 0)
        }
    }
}
