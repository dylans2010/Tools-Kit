import Foundation

struct CardDeckModel {
    enum Suit: String, CaseIterable {
        case hearts = "❤️", diamonds = "💎", clubs = "♣️", spades = "♠️"
    }
    enum Rank: String, CaseIterable {
        case two = "2", three = "3", four = "4", five = "5", six = "6", seven = "7", eight = "8", nine = "9", ten = "10", jack = "J", queen = "Q", king = "K", ace = "A"
        var value: Int {
            switch self {
            case .jack, .queen, .king: return 10
            case .ace: return 11
            default: return Int(self.rawValue) ?? 0
            }
        }
    }
    struct Card {
        let suit: Suit
        let rank: Rank
        var display: String { "\(rank.rawValue)\(suit.rawValue)" }
    }

    static func newDeck() -> [Card] {
        var deck: [Card] = []
        for suit in Suit.allCases {
            for rank in Rank.allCases {
                deck.append(Card(suit: suit, rank: rank))
            }
        }
        return deck.shuffled()
    }
}
