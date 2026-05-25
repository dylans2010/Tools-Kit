import SwiftUI

struct BattlefieldAssets {
    static let terrainColors: [Color] = [
        Color(red: 0.2, green: 0.35, blue: 0.2),
        Color(red: 0.25, green: 0.4, blue: 0.25),
        Color(red: 0.18, green: 0.3, blue: 0.18),
    ]

    static let unitLabels: [BCUnitType: String] = [
        .infantry: "INF",
        .tank: "TNK",
        .artillery: "ART",
        .scout: "SCT",
        .medic: "MED",
    ]

    static func unitDescription(_ type: BCUnitType) -> String {
        switch type {
        case .infantry: return "Balanced unit with moderate attack and defense."
        case .tank: return "Heavy armor with high defense and strong attack."
        case .artillery: return "Long-range power, but fragile."
        case .scout: return "Fast and nimble, low damage."
        case .medic: return "Support unit."
        default: return "Unit type: \(type.rawValue)"
        }
    }
}
