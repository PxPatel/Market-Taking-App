public enum Dealer {
    /// Deals `cardCount` distinct cards from `pool` (without replacement) and hides
    /// `hiddenCount` of them at random positions.
    public static func deal<G: RandomNumberGenerator>(
        cardCount: Int,
        hiddenCount: Int,
        from pool: CardPool,
        using rng: inout G
    ) -> Hand {
        precondition(cardCount >= 1 && cardCount <= pool.count, "Cannot deal \(cardCount) from \(pool.count)")
        precondition(hiddenCount >= 1 && hiddenCount <= cardCount, "Hidden count \(hiddenCount) invalid")
        let cards = RandomDraws.sample(cardCount, from: pool.cards, using: &rng)
        let hiddenPositions = Set(RandomDraws.sample(hiddenCount, from: Array(0..<cardCount), using: &rng))
        return Hand(cards.enumerated().map { index, card in
            DealtCard(card: card, isHidden: hiddenPositions.contains(index))
        })
    }
}
