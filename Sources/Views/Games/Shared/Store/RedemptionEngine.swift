import Foundation

final class RedemptionEngine: ObservableObject {
    static let shared = RedemptionEngine()

    @Published var purchasedItems: Set<String> = []
    @Published var lastPurchaseError: String?
    @Published var lastPurchaseSuccess: String?

    private let purchasedKey = "games_purchased_items"

    private init() {
        if let data = GamesUserDefaults.data(forKey: purchasedKey),
           let items = try? JSONDecoder().decode(Set<String>.self, from: data) {
            purchasedItems = items
        }
    }

    func purchase(item: StoreItem) -> Bool {
        lastPurchaseError = nil
        lastPurchaseSuccess = nil

        if purchasedItems.contains(item.id) {
            lastPurchaseError = "Already purchased"
            return false
        }

        do {
            switch item.currency {
            case .coins:
                try CurrencyLedger.shared.spendCoins(item.cost)
            case .gems:
                try CurrencyLedger.shared.spendGems(item.cost)
            }
        } catch let error as InsufficientFundsError {
            lastPurchaseError = error.localizedDescription
            return false
        } catch {
            lastPurchaseError = error.localizedDescription
            return false
        }

        purchasedItems.insert(item.id)
        savePurchases()

        if item.section == .gemRewards {
            var profile = GamesPersistenceManager.shared.load()
            if !profile.unlockedBadges.contains(item.name) {
                profile.unlockedBadges.append(item.name)
                GamesPersistenceManager.shared.save(profile)
                CurrencyLedger.shared.reload()
            }
        }

        lastPurchaseSuccess = "Purchased \(item.name)!"
        return true
    }

    func hasPurchased(_ itemId: String) -> Bool {
        purchasedItems.contains(itemId)
    }

    private func savePurchases() {
        if let data = try? JSONEncoder().encode(purchasedItems) {
            GamesUserDefaults.setData(data, forKey: purchasedKey)
        }
    }
}
