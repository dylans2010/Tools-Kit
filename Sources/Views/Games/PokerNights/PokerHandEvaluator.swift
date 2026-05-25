import Foundation

struct PokerHandEvaluator {
    enum HandRank: Int, Comparable {
        case highCard, pair, twoPair, threeOfAKind, straight, flush, fullHouse, fourOfAKind, straightFlush, royalFlush

        static func < (lhs: HandRank, rhs: HandRank) -> Bool { lhs.rawValue < rhs.rawValue }
    }

    static func evaluate(hand: [CardDeckModel.Card]) -> HandRank {
        let ranks = hand.map { $0.rank.value }.sorted()
        let suits = Set(hand.map { $0.suit })
        let counts = Dictionary(grouping: ranks, by: { $0 }).mapValues { $0.count }
        let sortedCounts = counts.values.sorted(by: >)

        let isFlush = suits.count == 1
        let isStraight = ranks.last! - ranks.first! == 4 && Set(ranks).count == 5

        if isFlush && isStraight && ranks.last == 14 { return .royalFlush }
        if isFlush && isStraight { return .straightFlush }
        if sortedCounts == [4, 1] { return .fourOfAKind }
        if sortedCounts == [3, 2] { return .fullHouse }
        if isFlush { return .flush }
        if isStraight { return .straight }
        if sortedCounts == [3, 1, 1] { return .threeOfAKind }
        if sortedCounts == [2, 2, 1] { return .twoPair }
        if sortedCounts == [2, 1, 1, 1] { return .pair }
        return .highCard
    }
}
