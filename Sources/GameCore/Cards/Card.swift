/// A playing card. Value runs 2...14, where J = 11, Q = 12, K = 13, A = 14.
public struct Card: Hashable, Codable, Sendable, CustomStringConvertible {
    public static let valueRange: ClosedRange<Int> = 2...14

    public let value: Int
    public let suit: Suit

    public init(value: Int, suit: Suit) {
        precondition(Self.valueRange.contains(value), "Card value \(value) out of range")
        self.value = value
        self.suit = suit
    }

    public var description: String {
        let rank: String
        switch value {
        case 11: rank = "J"
        case 12: rank = "Q"
        case 13: rank = "K"
        case 14: rank = "A"
        default: rank = String(value)
        }
        let symbol: String
        switch suit {
        case .spades: symbol = "♠"
        case .hearts: symbol = "♥"
        case .diamonds: symbol = "♦"
        case .clubs: symbol = "♣"
        }
        return rank + symbol
    }
}
