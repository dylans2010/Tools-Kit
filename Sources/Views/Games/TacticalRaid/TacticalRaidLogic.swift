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
    @Published var difficulty = 0
    @Published var cardsPlayed: Int = 0
    @Published var turnsPlayed = 0
    @Published var totalDamageDealt = 0
    @Published var damageBlocked = 0
    @Published var healsUsed = 0
    @Published var perfectBlocks = 0
    @Published var consecutiveWins = 0
    @Published var bestConsecutiveWins = 0

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

    func startGame(difficulty: Int = 0) {
        self.difficulty = difficulty
        var deck = Self.fullDeck.shuffled()
        playerHand = Array(deck.prefix(10))
        deck.removeFirst(10)
        enemyHand = Array(deck.prefix(10))
        let healthBonus = difficulty * 5
        playerHealth = 30
        enemyHealth = 30 + healthBonus
        score = 0; gameOver = false; lastPlayerCard = nil; lastEnemyCard = nil; message = ""
        turnsPlayed = 0; totalDamageDealt = 0; damageBlocked = 0; healsUsed = 0; perfectBlocks = 0; cardsPlayed = 0
        phase = .playing
    }

    func playCard(_ card: TRCard) {
        guard !gameOver, let idx = playerHand.firstIndex(where: { $0.id == card.id }) else { return }
        playerHand.remove(at: idx)
        lastPlayerCard = card
        turnsPlayed += 1
        cardsPlayed += 1

        let enemyCard: TRCard?
        if difficulty >= 2 {
            enemyCard = pickSmartCard(against: card)
        } else if difficulty >= 1 {
            let attacks = enemyHand.filter { $0.type == .attack }
            enemyCard = (card.type == .attack && !attacks.isEmpty) ?
                enemyHand.filter { $0.type == .defense }.max(by: { $0.power < $1.power }) ?? enemyHand.randomElement() :
                enemyHand.randomElement()
        } else {
            enemyCard = enemyHand.randomElement()
        }

        if let ec = enemyCard, let eIdx = enemyHand.firstIndex(where: { $0.id == ec.id }) {
            enemyHand.remove(at: eIdx)
            lastEnemyCard = ec
            resolveTurn(playerCard: card, enemyCard: ec)
        }

        if enemyHealth <= 0 || playerHealth <= 0 || (playerHand.isEmpty && enemyHand.isEmpty) {
            endGame()
        }
    }

    private func pickSmartCard(against playerCard: TRCard) -> TRCard? {
        switch playerCard.type {
        case .attack:
            return enemyHand.filter { $0.type == .defense }.max(by: { $0.power < $1.power }) ?? enemyHand.randomElement()
        case .defense:
            return enemyHand.filter { $0.type == .special || $0.type == .attack }.max(by: { $0.power < $1.power }) ?? enemyHand.randomElement()
        case .special:
            return enemyHand.filter { $0.type == .attack }.max(by: { $0.power < $1.power }) ?? enemyHand.randomElement()
        }
    }

    private func resolveTurn(playerCard: TRCard, enemyCard: TRCard) {
        switch (playerCard.type, enemyCard.type) {
        case (.attack, .attack):
            enemyHealth -= playerCard.power
            playerHealth -= enemyCard.power
            totalDamageDealt += playerCard.power
            score += playerCard.power * 10
            message = "Clash! Both take damage."
        case (.attack, .defense):
            let dmg = max(0, playerCard.power - enemyCard.power)
            enemyHealth -= dmg
            totalDamageDealt += dmg
            score += dmg * 10
            message = dmg > 0 ? "Broke through defense for \(dmg)!" : "Attack blocked!"
        case (.defense, .attack):
            let dmg = max(0, enemyCard.power - playerCard.power)
            playerHealth -= dmg
            if dmg == 0 { perfectBlocks += 1; score += 30 }
            damageBlocked += max(0, enemyCard.power - dmg)
            score += (playerCard.power > enemyCard.power ? 15 : 5)
            message = dmg > 0 ? "Took \(dmg) damage through guard." : "Perfect block!"
        case (.special, _):
            if playerCard.name == "Heal Pulse" || playerCard.name == "Drain Life" {
                playerHealth += playerCard.power; healsUsed += 1
                if playerCard.name == "Drain Life" { enemyHealth -= playerCard.power / 2; totalDamageDealt += playerCard.power / 2 }
                score += playerCard.power * 8
                message = "Healed \(playerCard.power) HP!"
            } else if playerCard.name == "Double Edge" {
                enemyHealth -= playerCard.power; playerHealth -= playerCard.power / 2
                totalDamageDealt += playerCard.power
                score += playerCard.power * 15
                message = "Double Edge: dealt \(playerCard.power), took \(playerCard.power / 2)!"
            } else {
                enemyHealth -= playerCard.power
                totalDamageDealt += playerCard.power
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
        streakMultiplier = min(3.0, streakMultiplier + (playerHealth > enemyHealth ? 0.05 : 0.02))
    }

    private func endGame() {
        gameOver = true
        playerWon = playerHealth > enemyHealth
        if playerWon {
            totalWins += 1; consecutiveWins += 1
            bestConsecutiveWins = max(bestConsecutiveWins, consecutiveWins)
            streakMultiplier = min(3.0, streakMultiplier + 0.1)
        } else {
            consecutiveWins = 0; streakMultiplier = max(1.0, streakMultiplier - 0.1)
        }
        phase = .results
    }

    func finalReward() -> GameReward {
        var reward = calculateFinalReward(won: playerWon, score: score, streakMultiplier: streakMultiplier)
        let diffBonus = difficulty * 30
        var badge: String?
        if playerWon && playerHealth >= 25 { badge = "Flawless Victory" }
        if perfectBlocks >= 3 { badge = badge ?? "Shield Master" }
        if totalDamageDealt >= 50 { badge = badge ?? "Damage Dealer" }
        if bestConsecutiveWins >= 3 { badge = badge ?? "Raid Streak" }
        if playerWon && difficulty >= 2 { badge = badge ?? "Tactical Master" }
        let gems = totalWins > 0 && totalWins % 5 == 0 ? 1 : 0
        reward = GameReward(xp: reward.xp + diffBonus, coins: reward.coins, gems: gems, badgeUnlocked: badge)
        return reward
    }
}
