/// A set of distinct cards that can still be drawn.
///
/// The eligible pool for a round is the standard deck, optionally filtered by a
/// market event. Pricing removes face-up cards from it to get what a hidden card
/// could be.
public struct CardPool: Hashable, Sendable {
    /// Cards in the pool, in deck order (so draws are reproducible).
    public let cards: [Card]

    public init(_ cards: [Card]) {
        precondition(Set(cards).count == cards.count, "A card pool cannot contain duplicate cards")
        self.cards = cards
    }

    public static let standardDeck = CardPool(Deck.standard)

    public var count: Int { cards.count }

    public func filter(_ isIncluded: (Card) -> Bool) -> CardPool {
        CardPool(cards.filter(isIncluded))
    }

    public func removing<S: Sequence>(_ removed: S) -> CardPool where S.Element == Card {
        let removedSet = Set(removed)
        return CardPool(cards.filter { !removedSet.contains($0) })
    }

    public var valueSum: Int {
        cards.reduce(0) { $0 + $1.value }
    }

    /// Values in ascending order, duplicates kept.
    public var sortedValues: [Int] {
        cards.map(\.value).sorted()
    }
}
