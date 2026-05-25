import Foundation

class RedemptionEngine {
    static let shared = RedemptionEngine()

    func purchase(_ item: StoreItemModel) throws {
        let ledger = CurrencyLedger.shared
        if item.currency == .coins {
            try ledger.spendCoins(item.price)
        } else {
            try ledger.spendGems(item.price)
        }

        // Apply item effect
        applyEffect(for: item.id)
    }

    private func applyEffect(for itemID: String) {
        var profile = GamesPersistenceManager.shared.load()
        if itemID.contains("badge") {
            profile.unlockedBadges.append(itemID)
        }
        // Additional effects can be added here
        GamesPersistenceManager.shared.save(profile)
        CurrencyLedger.shared.reload()
    }
}
