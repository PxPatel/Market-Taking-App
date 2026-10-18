public enum Deck {
    /// The 52-card standard deck, in a fixed order (suit, then value).
    public static let standard: [Card] = Suit.allCases.flatMap { suit in
        Card.valueRange.map { Card(value: $0, suit: suit) }
    }
}
