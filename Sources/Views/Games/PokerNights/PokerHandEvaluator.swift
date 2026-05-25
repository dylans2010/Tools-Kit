import Foundation

enum PokerHandRank: Int, Comparable {
    case highCard = 0, pair, twoPair, threeOfAKind, straight, flush, fullHouse, fourOfAKind, straightFlush, royalFlush
    static func < (lhs: PokerHandRank, rhs: PokerHandRank) -> Bool { lhs.rawValue < rhs.rawValue }
    var name: String {
        switch self {
        case .highCard: return "High Card"; case .pair: return "Pair"; case .twoPair: return "Two Pair"
        case .threeOfAKind: return "Three of a Kind"; case .straight: return "Straight"; case .flush: return "Flush"
        case .fullHouse: return "Full House"; case .fourOfAKind: return "Four of a Kind"
        case .straightFlush: return "Straight Flush"; case .royalFlush: return "Royal Flush"
        }
    }
}

struct EvaluatedHand: Comparable {
    let rank: PokerHandRank
    let highCards: [Int]
    static func < (lhs: EvaluatedHand, rhs: EvaluatedHand) -> Bool {
        if lhs.rank != rhs.rank { return lhs.rank < rhs.rank }
        for (l, r) in zip(lhs.highCards, rhs.highCards) { if l != r { return l < r } }
        return false
    }
}

struct PokerHandEvaluator {
    static func evaluate(_ hand: [PlayingCard]) -> EvaluatedHand {
        let values = hand.map { $0.rank.rawValue }.sorted(by: >)
        let suits = hand.map { $0.suit }
        let isFlush = Set(suits).count == 1
        let uniqueVals = Set(values)
        let counts = values.reduce(into: [Int: Int]()) { $0[$1, default: 0] += 1 }
        let sorted = counts.sorted { $0.value == $1.value ? $0.key > $1.key : $0.value > $1.value }
        let isStraight = uniqueVals.count == 5 && (values[0] - values[4] == 4 || values == [14, 5, 4, 3, 2])
        let topCards = sorted.map { $0.key }

        if isFlush && isStraight {
            return values[0] == 14 && values[1] == 13 ? EvaluatedHand(rank: .royalFlush, highCards: topCards) : EvaluatedHand(rank: .straightFlush, highCards: topCards)
        }
        if sorted[0].value == 4 { return EvaluatedHand(rank: .fourOfAKind, highCards: topCards) }
        if sorted[0].value == 3 && sorted[1].value == 2 { return EvaluatedHand(rank: .fullHouse, highCards: topCards) }
        if isFlush { return EvaluatedHand(rank: .flush, highCards: topCards) }
        if isStraight { return EvaluatedHand(rank: .straight, highCards: topCards) }
        if sorted[0].value == 3 { return EvaluatedHand(rank: .threeOfAKind, highCards: topCards) }
        if sorted[0].value == 2 && sorted[1].value == 2 { return EvaluatedHand(rank: .twoPair, highCards: topCards) }
        if sorted[0].value == 2 { return EvaluatedHand(rank: .pair, highCards: topCards) }
        return EvaluatedHand(rank: .highCard, highCards: topCards)
    }
}
