import Foundation

struct TRCard: Identifiable, Equatable {
    let id = UUID()
    let name: String
    let type: CardType
    let power: Int
    let icon: String

    enum CardType: String { case attack, defense, special }
}

final class TacticalRaidLogic: ObservableObject, GamesRewardable {
    let gameIdentifier = "tactical_raid"
    let baseXPReward = 100
    let winXPBonus = 70
    let baseCoinReward = 0
    let winCoinBonus = 0

    @Published var playerHand: [TRCard] = []
    @Published var enemyHand: [TRCard] = []
    @Published var playerHealth = 30
    @Published var enemyHealth = 30
    @Published var lastPlayerCard: TRCard?
    @Published var lastEnemyCard: TRCard?
    @Published var gameOver = false
    @Published var playerWon = false
    @Published var score = 0
    @Published var totalWins = 0
    @Published var phase: GamePhase = .lobby
    @Published var streakMultiplier: Double = 1.0
    @Published var message = ""

    enum GamePhase { case lobby, playing, results }

    static let fullDeck: [TRCard] = [
        TRCard(name: "Slash", type: .attack, power: 4, icon: "bolt.fill"),
        TRCard(name: "Heavy Strike", type: .attack, power: 6, icon: "flame.fill"),
        TRCard(name: "Quick Jab", type: .attack, power: 3, icon: "hand.raised.fill"),
        TRCard(name: "Power Surge", type: .attack, power: 7, icon: "bolt.circle.fill"),
        TRCard(name: "Arrow Rain", type: .attack, power: 5, icon: "cloud.bolt.fill"),
        TRCard(name: "Shield Wall", type: .defense, power: 5, icon: "shield.fill"),
        TRCard(name: "Iron Guard", type: .defense, power: 6, icon: "shield.lefthalf.filled"),
        TRCard(name: "Dodge Roll", type: .defense, power: 3, icon: "figure.walk"),
        TRCard(name: "Magic Barrier", type: .defense, power: 7, icon: "sparkles"),
        TRCard(name: "Parry", type: .defense, power: 4, icon: "arrow.uturn.left"),
        TRCard(name: "Heal Pulse", type: .special, power: 5, icon: "heart.fill"),
        TRCard(name: "Drain Life", type: .special, power: 4, icon: "drop.fill"),
        TRCard(name: "Stun Blast", type: .special, power: 3, icon: "staroflife.fill"),
        TRCard(name: "Double Edge", type: .special, power: 8, icon: "exclamationmark.triangle.fill"),
        TRCard(name: "Poison Cloud", type: .special, power: 3, icon: "aqi.medium"),
        TRCard(name: "War Cry", type: .special, power: 2, icon: "speaker.wave.3.fill"),
        TRCard(name: "Backstab", type: .attack, power: 8, icon: "eye.slash.fill"),
        TRCard(name: "Counter Strike", type: .defense, power: 5, icon: "arrow.left.arrow.right"),
        TRCard(name: "Fireball", type: .attack, power: 9, icon: "flame"),
        TRCard(name: "Fortify", type: .defense, power: 8, icon: "building.columns.fill"),
    ]

    func startGame() {
        var deck = Self.fullDeck.shuffled()
        playerHand = Array(deck.prefix(10))
        deck.removeFirst(10)
        enemyHand = Array(deck.prefix(10))
        playerHealth = 30
        enemyHealth = 30
        score = 0
        gameOver = false
        lastPlayerCard = nil
        lastEnemyCard = nil
        message = ""
        phase = .playing
    }

    func playCard(_ card: TRCard) {
        guard !gameOver, let idx = playerHand.firstIndex(where: { $0.id == card.id }) else { return }
        playerHand.remove(at: idx)
        lastPlayerCard = card

        let enemyCard = enemyHand.randomElement()
        if let ec = enemyCard, let eIdx = enemyHand.firstIndex(where: { $0.id == ec.id }) {
            enemyHand.remove(at: eIdx)
            lastEnemyCard = ec
            resolveTurn(playerCard: card, enemyCard: ec)
        }

        if enemyHealth <= 0 || playerHealth <= 0 || (playerHand.isEmpty && enemyHand.isEmpty) {
            endGame()
        }
    }

    private func resolveTurn(playerCard: TRCard, enemyCard: TRCard) {
        switch (playerCard.type, enemyCard.type) {
        case (.attack, .attack):
            enemyHealth -= playerCard.power
            playerHealth -= enemyCard.power
            score += playerCard.power * 10
            message = "Clash! Both take damage."
        case (.attack, .defense):
            let dmg = max(0, playerCard.power - enemyCard.power)
            enemyHealth -= dmg
            score += dmg * 10
            message = dmg > 0 ? "Broke through defense for \(dmg)!" : "Attack blocked!"
        case (.defense, .attack):
            let dmg = max(0, enemyCard.power - playerCard.power)
            playerHealth -= dmg
            score += (playerCard.power > enemyCard.power ? 15 : 5)
            message = dmg > 0 ? "Took \(dmg) damage through guard." : "Perfect block!"
        case (.special, _):
            if playerCard.name == "Heal Pulse" || playerCard.name == "Drain Life" {
                playerHealth += playerCard.power
                if playerCard.name == "Drain Life" { enemyHealth -= playerCard.power / 2 }
                score += playerCard.power * 8
                message = "Healed \(playerCard.power) HP!"
            } else {
                enemyHealth -= playerCard.power
                score += playerCard.power * 12
                message = "Special: \(playerCard.name) for \(playerCard.power)!"
            }
        case (_, .special):
            if enemyCard.name == "Heal Pulse" || enemyCard.name == "Drain Life" {
                enemyHealth += enemyCard.power
            } else {
                playerHealth -= enemyCard.power
            }
            score += 5
            message = "Enemy used \(enemyCard.name)."
        default:
            message = "Both defended."
            score += 5
        }
    }

    private func endGame() {
        gameOver = true
        playerWon = playerHealth > enemyHealth
        if playerWon { totalWins += 1; streakMultiplier = min(3.0, streakMultiplier + 0.1) }
        else { streakMultiplier = 1.0 }
        phase = .results
    }

    func finalReward() -> GameReward {
        var reward = calculateFinalReward(won: playerWon, score: score, streakMultiplier: streakMultiplier)
        let gems = totalWins > 0 && totalWins % 5 == 0 ? 1 : 0
        reward = GameReward(xp: reward.xp, coins: reward.coins, gems: gems, badgeUnlocked: reward.badgeUnlocked)
        return reward
    }
}
