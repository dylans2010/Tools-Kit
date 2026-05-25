import Foundation

struct TowerDefenseWaveModel {
    struct Wave {
        let enemyType: String
        let count: Int
    }
    static let waves = [
        Wave(enemyType: "Soldier", count: 10),
        Wave(enemyType: "Tank", count: 5),
        Wave(enemyType: "Boss", count: 1)
    ]
}
