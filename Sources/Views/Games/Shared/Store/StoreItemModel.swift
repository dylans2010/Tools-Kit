import Foundation

enum StoreSection: String, CaseIterable, Identifiable {
    case cosmetics = "Cosmetics"
    case powerUps = "Power-Ups"
    case unlockables = "Unlockables"
    case gemRewards = "Gem Rewards"
    var id: String { rawValue }
}

enum StoreCurrency {
    case coins
    case gems
}

struct StoreItem: Identifiable, Equatable {
    let id: String
    let name: String
    let description: String
    let icon: String
    let section: StoreSection
    let cost: Int
    let currency: StoreCurrency

    static let allItems: [StoreItem] = [
        StoreItem(id: "border_gold", name: "Gold Border", description: "Premium gold profile border", icon: "circle.hexagongrid", section: .cosmetics, cost: 500, currency: .coins),
        StoreItem(id: "border_neon", name: "Neon Border", description: "Electric neon profile border", icon: "circle.hexagongrid.fill", section: .cosmetics, cost: 800, currency: .coins),
        StoreItem(id: "border_diamond", name: "Diamond Border", description: "Exclusive diamond profile border", icon: "diamond", section: .cosmetics, cost: 1200, currency: .coins),
        StoreItem(id: "border_flame", name: "Flame Border", description: "Animated flame profile border", icon: "flame", section: .cosmetics, cost: 1500, currency: .coins),
        StoreItem(id: "border_royal", name: "Royal Border", description: "Majestic royal profile border", icon: "crown", section: .cosmetics, cost: 2000, currency: .coins),

        StoreItem(id: "double_xp", name: "Double XP", description: "2x XP for one session", icon: "bolt.fill", section: .powerUps, cost: 500, currency: .coins),
        StoreItem(id: "extra_life", name: "Extra Life", description: "One extra life token", icon: "heart.fill", section: .powerUps, cost: 300, currency: .coins),
        StoreItem(id: "hint_pack", name: "Hint Pack ×5", description: "5 hint tokens for puzzles", icon: "lightbulb.fill", section: .powerUps, cost: 150, currency: .coins),

        StoreItem(id: "skin_dark_chess", name: "Dark Chess Theme", description: "Dark theme for Chess Lite", icon: "crown.fill", section: .unlockables, cost: 600, currency: .coins),
        StoreItem(id: "skin_neon_slots", name: "Neon Slots Theme", description: "Neon theme for Slot Machine", icon: "sparkles", section: .unlockables, cost: 750, currency: .coins),
        StoreItem(id: "skin_retro_minesweeper", name: "Retro Minesweeper", description: "Retro theme for Minesweeper X", icon: "circle.grid.cross", section: .unlockables, cost: 500, currency: .coins),

        StoreItem(id: "badge_legendary", name: "Legendary Badge", description: "Exclusive legendary badge card", icon: "medal.fill", section: .gemRewards, cost: 10, currency: .gems),
        StoreItem(id: "badge_mythic", name: "Mythic Badge", description: "Ultra-rare mythic badge card", icon: "medal.star.fill", section: .gemRewards, cost: 25, currency: .gems),
        StoreItem(id: "badge_cosmic", name: "Cosmic Badge", description: "Cosmic-tier badge card", icon: "sparkles", section: .gemRewards, cost: 50, currency: .gems),
    ]

    static func items(in section: StoreSection) -> [StoreItem] {
        allItems.filter { $0.section == section }
    }
}
