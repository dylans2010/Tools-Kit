import Foundation

struct WaveEnemy: Identifiable, Equatable {
    let id = UUID()
    var lane: Int
    var position: Double
    var health: Int
    var speed: Double
    var points: Int
}

struct WaveDefinition {
    let waveNumber: Int
    let enemyCount: Int
    let baseHealth: Int
    let baseSpeed: Double
    let pointsPerKill: Int

    func spawnEnemies() -> [WaveEnemy] {
        (0..<enemyCount).map { i in
            WaveEnemy(
                lane: i % 3,
                position: -Double(i) * 0.3,
                health: baseHealth + (waveNumber * 2),
                speed: baseSpeed + Double(waveNumber) * 0.05,
                points: pointsPerKill + waveNumber * 5
            )
        }
    }
}

struct WarZoneMapModel {
    static let waves: [WaveDefinition] = (1...10).map { wave in
        WaveDefinition(
            waveNumber: wave,
            enemyCount: 3 + wave,
            baseHealth: 2 + wave,
            baseSpeed: 0.8 + Double(wave) * 0.1,
            pointsPerKill: 10 + wave * 5
        )
    }
}
