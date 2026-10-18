/// Exact pricing of a round from the player's point of view.
///
/// Inputs are the dealt hand and the round's eligible pool: the standard deck,
/// filtered by any active market event, *before* dealing. A hidden card could
/// be any eligible card that is not face up.
///
/// Why no full enumeration: every unknown hidden card is an equally likely draw
/// from the same remaining pool, so by linearity of expectation each one is
/// worth exactly the pool's mean. Fair value is therefore
/// `known values + unknownCount × poolSum / poolCount`, which is exact, not an
/// approximation. Brute-force enumeration lives in the tests as an independent
/// check of this formula.
public enum Pricing {
    /// Expected true sum given what the player can see.
    public static func fairValue(of hand: Hand, eligible pool: CardPool) -> Rational {
        let unknown = unknownPool(for: hand, eligible: pool)
        let unknownCount = unknownCardCount(in: hand)
        return Rational(knownSum(of: hand)) + Rational(unknownCount * unknown.valueSum, unknown.count)
    }

    /// The largest sum the round could have: unknown cards take the highest
    /// values left in the pool. Used for the short-sale risk check.
    public static func maxPossibleSum(of hand: Hand, eligible pool: CardPool) -> Int {
        let values = unknownPool(for: hand, eligible: pool).sortedValues
        return knownSum(of: hand) + values.suffix(unknownCardCount(in: hand)).reduce(0, +)
    }

    /// The smallest sum the round could have: unknown cards take the lowest values left.
    public static func minPossibleSum(of hand: Hand, eligible pool: CardPool) -> Int {
        let values = unknownPool(for: hand, eligible: pool).sortedValues
        return knownSum(of: hand) + values.prefix(unknownCardCount(in: hand)).reduce(0, +)
    }

    /// Cards a hidden card could be: the eligible pool minus the face-up cards.
    ///
    /// A hidden card whose value an event fixed still occupies a real card from
    /// this pool, but which one is unknown, so it does not change what the other
    /// hidden cards could be.
    public static func unknownPool(for hand: Hand, eligible pool: CardPool) -> CardPool {
        let faceUp = hand.faceUpCards
        precondition(faceUp.allSatisfy(pool.cards.contains), "Face-up cards must come from the eligible pool")
        let remaining = pool.removing(faceUp)
        precondition(remaining.count >= hand.hiddenCount, "Pool too small for the hidden cards")
        return remaining
    }

    /// Hidden cards whose value the player does not know.
    public static func unknownCardCount(in hand: Hand) -> Int {
        hand.cards.filter { !$0.isValueKnown }.count
    }

    /// Sum of the values the player knows: face-up cards plus any event-fixed values.
    public static func knownSum(of hand: Hand) -> Int {
        hand.cards.filter(\.isValueKnown).reduce(0) { $0 + $1.value }
    }
}
