import Foundation

final class BlackjackProLogic: ObservableObject, GamesRewardable {
    let gameIdentifier = "blackjack_pro"
    let baseXPReward = 40
    let winXPBonus = 60
    let baseCoinReward = 0
    let winCoinBonus = 0

    @Published var playerHand: [PlayingCard] = []
    @Published var dealerHand: [PlayingCard] = []
    @Published var dealerRevealed = false
    @Published var bet = 50
    @Published var result: HandResult = .playing
    @Published var score = 0
    @Published var handsPlayed = 0
    @Published var wins: Int = 0
    @Published var dealerTotal: Int = 0
    @Published var playerTotal: Int = 0
    @Published var phase: GamePhase = .lobby
    @Published var streakMultiplier: Double = 1.0
    @Published var canDoubleDown = true
    @Published var splitHands: [[PlayingCard]] = []
    @Published var consecutiveWins = 0
    @Published var bestConsecutiveWins = 0
    @Published var handsWon = 0
    @Published var blackjackCount = 0
    @Published var insuranceActive = false
    @Published var surrenderAvailable = true
    @Published var biggestWin = 0
    @Published var totalBet = 0
    @Published var gameOver: Bool = false

    func newHand() { dealNewHand() }

    private var deck = CardDeck()

    enum GamePhase { case lobby, playing, results }
    enum HandResult: String { case playing, playerWin = "You Win!", dealerWin = "Dealer Wins", push = "Push", blackjack = "Blackjack!", bust = "Bust", surrender = "Surrendered" }

    func startGame() {
        // begin a new game
    }

    func startSession() {
        score = 0
        handsPlayed = 0
        handsWon = 0
        blackjackCount = 0
        consecutiveWins = 0
        bestConsecutiveWins = 0
        biggestWin = 0
        totalBet = 0
        phase = .playing
        dealNewHand()
    }

    func dealNewHand() {
        let balance = CurrencyLedger.shared.profile.coins
        guard bet <= balance else { return }
        do { try CurrencyLedger.shared.spendCoins(bet) } catch { return }
        totalBet += bet

        if deck.remaining < 15 { deck = CardDeck() }
        playerHand = [deck.draw()!, deck.draw()!]
        dealerHand = [deck.draw()!, deck.draw()!]
        dealerRevealed = false
        result = .playing
        canDoubleDown = true
        surrenderAvailable = true
        insuranceActive = false
        handsPlayed += 1

        if blackjackHandValue(playerHand) == 21 {
            dealerRevealed = true
            if blackjackHandValue(dealerHand) == 21 {
                result = .push
                CurrencyLedger.shared.awardCoins(bet, reason: "Blackjack push")
            } else {
                result = .blackjack
                blackjackCount += 1
                let win = Int(Double(bet) * 2.5)
                CurrencyLedger.shared.awardCoins(win, reason: "Blackjack!")
                score += win
                handsWon += 1
                consecutiveWins += 1
                bestConsecutiveWins = max(bestConsecutiveWins, consecutiveWins)
                biggestWin = max(biggestWin, win)
                streakMultiplier = min(3.0, streakMultiplier + 0.15)
            }
        }
    }

    func hit() {
        guard result == .playing, let card = deck.draw() else { return }
        playerHand.append(card)
        canDoubleDown = false
        surrenderAvailable = false
        let value = blackjackHandValue(playerHand)
        if value > 21 {
            result = .bust
            dealerRevealed = true
            consecutiveWins = 0
            streakMultiplier = max(1.0, streakMultiplier - 0.1)
        } else if value == 21 {
            stand()
        }
    }

    func stand() {
        guard result == .playing else { return }
        dealerRevealed = true
        while blackjackHandValue(dealerHand) < 17 {
            if let card = deck.draw() { dealerHand.append(card) }
        }
        resolveHand()
    }

    func doubleDown() {
        guard result == .playing, canDoubleDown else { return }
        do { try CurrencyLedger.shared.spendCoins(bet) } catch { return }
        totalBet += bet
        bet *= 2
        if let card = deck.draw() { playerHand.append(card) }
        if blackjackHandValue(playerHand) > 21 {
            result = .bust
            dealerRevealed = true
            consecutiveWins = 0
            streakMultiplier = max(1.0, streakMultiplier - 0.1)
            bet /= 2
        } else {
            stand()
            bet /= 2
        }
    }

    func surrender() {
        guard result == .playing, surrenderAvailable else { return }
        result = .surrender
        dealerRevealed = true
        let refund = bet / 2
        CurrencyLedger.shared.awardCoins(refund, reason: "Blackjack surrender")
        consecutiveWins = 0
    }

    func buyInsurance() {
        guard result == .playing, !insuranceActive else { return }
        guard dealerHand.first?.rank == .ace else { return }
        let cost = bet / 2
        do { try CurrencyLedger.shared.spendCoins(cost) } catch { return }
        totalBet += cost
        insuranceActive = true
    }

    private func resolveHand() {
        let pVal = blackjackHandValue(playerHand)
        let dVal = blackjackHandValue(dealerHand)
        if dVal > 21 || pVal > dVal {
            result = .playerWin
            let winBonus = consecutiveWins >= 3 ? 1.25 : 1.0
            let winAmount = Int(Double(bet * 2) * winBonus)
            CurrencyLedger.shared.awardCoins(winAmount, reason: "Blackjack win")
            score += winAmount
            handsWon += 1
            consecutiveWins += 1
            bestConsecutiveWins = max(bestConsecutiveWins, consecutiveWins)
            biggestWin = max(biggestWin, winAmount)
            streakMultiplier = min(3.0, streakMultiplier + 0.1)
        } else if pVal == dVal {
            result = .push
            CurrencyLedger.shared.awardCoins(bet, reason: "Blackjack push")
        } else {
            result = .dealerWin
            consecutiveWins = 0
            streakMultiplier = max(1.0, streakMultiplier - 0.05)
            if insuranceActive && blackjackHandValue(dealerHand) == 21 {
                CurrencyLedger.shared.awardCoins(bet, reason: "Insurance payout")
            }
        }
    }

    func endSession() { phase = .results }

    func finalReward() -> GameReward {
        let xp = Int(Double(baseXPReward * handsPlayed + (score > 0 ? winXPBonus : 0)) * streakMultiplier) + (score / 10)
        var badge: String?
        if score > 3000 { badge = "Card Shark" }
        if blackjackCount >= 3 { badge = badge ?? "Natural Blackjack" }
        if bestConsecutiveWins >= 5 { badge = badge ?? "Hot Hand" }
        if handsWon > 0 && handsWon == handsPlayed { badge = badge ?? "Unbeatable" }
        let winRate = handsPlayed > 0 ? Double(handsWon) / Double(handsPlayed) : 0
        if winRate >= 0.7 && handsPlayed >= 10 { badge = badge ?? "Blackjack Pro" }
        let gems = score > 5000 ? 1 : 0
        return GameReward(xp: max(1, xp), coins: 0, gems: gems, badgeUnlocked: badge)
    }
}
