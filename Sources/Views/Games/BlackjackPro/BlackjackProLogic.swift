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
    @Published var phase: GamePhase = .lobby
    @Published var streakMultiplier: Double = 1.0
    @Published var canDoubleDown = true
    @Published var splitHands: [[PlayingCard]] = []

    private var deck = CardDeck()

    enum GamePhase { case lobby, playing, results }
    enum HandResult: String { case playing, playerWin = "You Win!", dealerWin = "Dealer Wins", push = "Push", blackjack = "Blackjack!", bust = "Bust" }

    func startSession() {
        score = 0
        handsPlayed = 0
        phase = .playing
        dealNewHand()
    }

    func dealNewHand() {
        let balance = CurrencyLedger.shared.profile.coins
        guard bet <= balance else { return }
        do { try CurrencyLedger.shared.spendCoins(bet) } catch { return }

        if deck.remaining < 15 { deck = CardDeck() }
        playerHand = [deck.draw()!, deck.draw()!]
        dealerHand = [deck.draw()!, deck.draw()!]
        dealerRevealed = false
        result = .playing
        canDoubleDown = true
        handsPlayed += 1

        if blackjackHandValue(playerHand) == 21 {
            dealerRevealed = true
            if blackjackHandValue(dealerHand) == 21 {
                result = .push
                CurrencyLedger.shared.awardCoins(bet, reason: "Blackjack push")
            } else {
                result = .blackjack
                let win = Int(Double(bet) * 2.5)
                CurrencyLedger.shared.awardCoins(win, reason: "Blackjack!")
                score += win
            }
        }
    }

    func hit() {
        guard result == .playing, let card = deck.draw() else { return }
        playerHand.append(card)
        canDoubleDown = false
        let value = blackjackHandValue(playerHand)
        if value > 21 {
            result = .bust
            dealerRevealed = true
            streakMultiplier = 1.0
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
        bet *= 2
        if let card = deck.draw() { playerHand.append(card) }
        if blackjackHandValue(playerHand) > 21 {
            result = .bust
            dealerRevealed = true
            streakMultiplier = 1.0
            bet /= 2
        } else {
            stand()
            bet /= 2
        }
    }

    private func resolveHand() {
        let pVal = blackjackHandValue(playerHand)
        let dVal = blackjackHandValue(dealerHand)
        if dVal > 21 || pVal > dVal {
            result = .playerWin
            CurrencyLedger.shared.awardCoins(bet * 2, reason: "Blackjack win")
            score += bet * 2
            streakMultiplier = min(3.0, streakMultiplier + 0.1)
        } else if pVal == dVal {
            result = .push
            CurrencyLedger.shared.awardCoins(bet, reason: "Blackjack push")
        } else {
            result = .dealerWin
            streakMultiplier = 1.0
        }
    }

    func endSession() { phase = .results }

    func finalReward() -> GameReward {
        let xp = Int(Double(baseXPReward * handsPlayed + (score > 0 ? winXPBonus : 0)) * streakMultiplier) + (score / 10)
        return GameReward(xp: max(1, xp), coins: 0, gems: 0, badgeUnlocked: score > 3000 ? "Card Shark" : nil)
    }
}
