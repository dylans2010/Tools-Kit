import Foundation
import SwiftUI

struct StoreItemModel: Identifiable {
    let id: String
    let name: String
    let description: String
    let price: Int
    let currency: CurrencyType
    let category: StoreCategory

    enum CurrencyType {
        case coins, gems
    }

    enum StoreCategory: String, CaseIterable {
        case cosmetics = "Cosmetics"
        case powerUps = "Power-Ups"
        case unlockables = "Unlockables"
        case gemRewards = "Gem Rewards"
    }
}
