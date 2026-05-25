import Foundation

struct WarZoneMapModel {
    let waves: [Wave]
    struct Wave {
        let enemyCount: Int
        let spawnRate: Double
    }

    static let defaultProgression = (1...10).map { Wave(enemyCount: $0 * 5, spawnRate: 1.0 - (Double($0) * 0.05)) }
}
