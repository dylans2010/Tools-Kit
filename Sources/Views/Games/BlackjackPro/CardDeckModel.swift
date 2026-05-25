import Foundation

enum Suit: String, CaseIterable {
    case hearts = "♥️"
    case diamonds = "♦️"
    case clubs = "♣️"
    case spades = "♠️"
}

enum Rank: Int, CaseIterable {
    case two = 2, three, four, five, six, seven, eight, nine, ten
    case jack = 11, queen = 12, king = 13, ace = 14

    var display: String {
        switch self {
        case .two: return "2"; case .three: return "3"; case .four: return "4"; case .five: return "5"
        case .six: return "6"; case .seven: return "7"; case .eight: return "8"; case .nine: return "9"
        case .ten: return "10"; case .jack: return "J"; case .queen: return "Q"; case .king: return "K"; case .ace: return "A"
        }
    }

    var blackjackValue: Int {
        switch self {
        case .jack, .queen, .king: return 10
        case .ace: return 11
        default: return rawValue
        }
    }
}

struct PlayingCard: Identifiable, Equatable {
    let id = UUID()
    let suit: Suit
    let rank: Rank
    var display: String { "\(rank.display)\(suit.rawValue)" }
}

struct CardDeck {
    private var cards: [PlayingCard] = []

    init(shuffled: Bool = true) {
        for suit in Suit.allCases {
            for rank in Rank.allCases {
                cards.append(PlayingCard(suit: suit, rank: rank))
            }
        }
        if shuffled { cards.shuffle() }
    }

    mutating func draw() -> PlayingCard? {
        cards.isEmpty ? nil : cards.removeFirst()
    }

    var remaining: Int { cards.count }
}

func blackjackHandValue(_ hand: [PlayingCard]) -> Int {
    var total = hand.reduce(0) { $0 + $1.rank.blackjackValue }
    var aces = hand.filter { $0.rank == .ace }.count
    while total > 21 && aces > 0 {
        total -= 10
        aces -= 1
    }
    return total
}
