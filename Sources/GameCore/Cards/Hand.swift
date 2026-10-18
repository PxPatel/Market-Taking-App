/// One card in a dealt round, at a fixed position.
public struct DealtCard: Hashable, Codable, Sendable {
    public let card: Card
    public let isHidden: Bool
    /// A value set by a market event ("card X is worth Y"); replaces the face value.
    public let valueOverride: Int?

    public init(card: Card, isHidden: Bool, valueOverride: Int? = nil) {
        self.card = card
        self.isHidden = isHidden
        self.valueOverride = valueOverride
    }

    /// What this card counts for in the true price.
    public var value: Int {
        valueOverride ?? card.value
    }

    /// True when the player knows this card's value: it is face up, or an event fixed it.
    public var isValueKnown: Bool {
        !isHidden || valueOverride != nil
    }
}

/// The cards dealt for one round, in display order.
public struct Hand: Hashable, Codable, Sendable {
    public let cards: [DealtCard]

    public init(_ cards: [DealtCard]) {
        precondition(!cards.isEmpty, "A hand needs at least one card")
        precondition(cards.contains(where: \.isHidden), "At least one card must be hidden")
        precondition(Set(cards.map(\.card)).count == cards.count, "A hand cannot repeat a card")
        self.cards = cards
    }

    /// The true market price: the sum of every card's value, revealed after the decision.
    public var trueSum: Int {
        cards.reduce(0) { $0 + $1.value }
    }

    public var faceUpCards: [Card] {
        cards.filter { !$0.isHidden }.map(\.card)
    }

    public var hiddenCount: Int {
        cards.filter(\.isHidden).count
    }

    /// Returns a copy with `value` fixed on the card at `position`.
    public func overridingValue(at position: Int, with value: Int) -> Hand {
        var updated = cards
        let old = updated[position]
        updated[position] = DealtCard(card: old.card, isHidden: old.isHidden, valueOverride: value)
        return Hand(updated)
    }
}
