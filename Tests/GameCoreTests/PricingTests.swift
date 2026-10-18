import Testing
@testable import GameCore

@Suite("Fair value, max and min sum")
struct PricingTests {
    @Test("Three hidden cards, no event: fair value 24, max 42, min 6")
    func allHiddenNoEvent() {
        let hand = Hand([down(2, .spades), down(9, .hearts), down(13, .clubs)])
        #expect(Pricing.fairValue(of: hand, eligible: TestPools.all) == 24)
        #expect(Pricing.maxPossibleSum(of: hand, eligible: TestPools.all) == 42)
        #expect(Pricing.minPossibleSum(of: hand, eligible: TestPools.all) == 6)
    }

    // The spec's example says 26. The exact value is 1322/51 ≈ 25.92: once a
    // 10 is visible, each hidden card averages 406/51, not 8. See DECISIONS.md.
    @Test("One visible 10 and two hidden cards: exactly 1322/51 (≈ 25.92)")
    func visibleTenTwoHidden() {
        let hand = Hand([up(10, .spades), down(4, .hearts), down(8, .clubs)])
        let fair = Pricing.fairValue(of: hand, eligible: TestPools.all)
        #expect(fair == Rational(1322, 51))
        #expect(abs(fair.doubleValue - 25.92) < 0.01)
    }

    @Test("Three hidden cards under 'only 10 or more': fair value 36")
    func tenOrMoreThreeHidden() {
        let hand = Hand([down(10, .spades), down(12, .hearts), down(14, .clubs)])
        #expect(Pricing.fairValue(of: hand, eligible: TestPools.tenOrMore) == 36)
        #expect(Pricing.maxPossibleSum(of: hand, eligible: TestPools.tenOrMore) == 42)
        #expect(Pricing.minPossibleSum(of: hand, eligible: TestPools.tenOrMore) == 30)
    }

    @Test("Three hidden under 'only 7 or less': fair value 13.5")
    func sevenOrLessThreeHidden() {
        let hand = Hand([down(2, .spades), down(3, .hearts), down(4, .clubs)])
        #expect(Pricing.fairValue(of: hand, eligible: TestPools.sevenOrLess) == Rational(27, 2))
        #expect(Pricing.maxPossibleSum(of: hand, eligible: TestPools.sevenOrLess) == 21)
    }

    @Test("Face-up aces lower the max possible sum")
    func faceUpAcesLimitMax() {
        // One ace showing: three aces remain, so two hidden cards can both be aces.
        let one = Hand([up(14, .spades), down(2, .hearts), down(3, .hearts)])
        #expect(Pricing.maxPossibleSum(of: one, eligible: TestPools.all) == 14 + 14 + 14)
        // Three aces showing: only one ace remains, so the next best is a king.
        let three = Hand([up(14, .spades), up(14, .hearts), up(14, .diamonds), down(2, .hearts), down(3, .hearts)])
        #expect(Pricing.maxPossibleSum(of: three, eligible: TestPools.all) == 42 + 14 + 13)
        // Same idea at the bottom: three 2s showing, one 2 left, then a 3.
        let twos = Hand([up(2, .spades), up(2, .hearts), up(2, .diamonds), down(9, .hearts), down(8, .hearts)])
        #expect(Pricing.minPossibleSum(of: twos, eligible: TestPools.all) == 6 + 2 + 3)
    }

    @Test("Face-up cards condition an event pool: 'only 10 or more' with an ace showing")
    func faceUpWithinEvent() {
        let hand = Hand([up(14, .spades), down(10, .hearts), down(11, .clubs), down(12, .clubs)])
        // 19 cards remain, summing 240 − 14 = 226.
        #expect(Pricing.fairValue(of: hand, eligible: TestPools.tenOrMore) == Rational(14) + Rational(3 * 226, 19))
    }

    @Test("'Only red cards' depends on the face-up cards")
    func redDependsOnFaceUp() {
        let lowShowing = Hand([up(2, .hearts), down(9, .diamonds)])
        let highShowing = Hand([up(14, .hearts), down(9, .diamonds)])
        // 25 red cards remain; their sum is 208 minus the face-up card.
        #expect(Pricing.fairValue(of: lowShowing, eligible: TestPools.red) == Rational(2) + Rational(206, 25))
        #expect(Pricing.fairValue(of: highShowing, eligible: TestPools.red) == Rational(14) + Rational(194, 25))
    }

    @Test("A fixed-value override on a hidden card counts as known")
    func hiddenOverride() {
        let hand = Hand([down(3, .spades, override: 10), down(7, .hearts), down(9, .clubs)])
        #expect(Pricing.fairValue(of: hand, eligible: TestPools.all) == Rational(10 + 16))
        #expect(Pricing.maxPossibleSum(of: hand, eligible: TestPools.all) == 10 + 28)
        #expect(Pricing.minPossibleSum(of: hand, eligible: TestPools.all) == 10 + 4)
        #expect(hand.trueSum == 10 + 7 + 9)
    }

    @Test("A fixed-value override on a face-up card replaces its face value")
    func faceUpOverride() {
        let hand = Hand([up(3, .spades).withOverride(12), down(7, .hearts)])
        // The 3♠ is still out of the pool, but counts as 12.
        #expect(Pricing.fairValue(of: hand, eligible: TestPools.all) == Rational(12) + Rational(413, 51))
    }

    @Test("Closed form matches brute-force enumeration on hand-picked hands")
    func matchesBruteForceHandPicked() {
        let cases: [(Hand, CardPool)] = [
            (Hand([up(10, .spades), down(4, .hearts), down(8, .clubs)]), TestPools.all),
            (Hand([up(14, .spades), up(13, .spades), down(4, .hearts), down(8, .clubs), down(2, .clubs)]), TestPools.all),
            (Hand([up(11, .hearts), down(12, .diamonds), down(10, .hearts)]), TestPools.tenOrMore),
            (Hand([up(4, .clubs), down(2, .spades)]), TestPools.even),
            (Hand([down(3, .spades, override: 10), down(7, .hearts), down(9, .clubs)]), TestPools.all),
            (Hand([up(5, .spades), down(9, .clubs), down(13, .spades)]), TestPools.black),
        ]
        for (hand, pool) in cases {
            expectMatchesBruteForce(hand, pool)
        }
    }

    @Test("Closed form matches brute-force enumeration on 150 random hands across every pool")
    func matchesBruteForceRandom() {
        var rng = SeededGenerator(seed: 2026)
        for _ in 0..<150 {
            let pool = TestPools.everyPool[RandomDraws.int(in: 0...6, using: &rng)]
            let count = RandomDraws.int(in: 1...8, using: &rng)
            // Brute force is exponential in hidden cards, so cap at 3 here.
            let hidden = RandomDraws.int(in: 1...min(count, 3), using: &rng)
            var hand = Dealer.deal(cardCount: count, hiddenCount: hidden, from: pool, using: &rng)
            if RandomDraws.int(in: 0...3, using: &rng) == 0 {
                let position = RandomDraws.int(in: 0...(count - 1), using: &rng)
                hand = hand.overridingValue(at: position, with: RandomDraws.int(in: 2...14, using: &rng))
            }
            expectMatchesBruteForce(hand, pool)
        }
    }

    @Test("Pricing eight cards with all hidden is fast")
    func eightHiddenIsFast() {
        let clock = ContinuousClock()
        var rng = SeededGenerator(seed: 1)
        let elapsed = clock.measure {
            for _ in 0..<1000 {
                let hand = Dealer.deal(cardCount: 8, hiddenCount: 8, from: .standardDeck, using: &rng)
                _ = Pricing.fairValue(of: hand, eligible: .standardDeck)
                _ = Pricing.maxPossibleSum(of: hand, eligible: .standardDeck)
            }
        }
        #expect(Pricing.fairValue(
            of: Dealer.deal(cardCount: 8, hiddenCount: 8, from: .standardDeck, using: &rng),
            eligible: .standardDeck
        ) == 64)
        #expect(elapsed < .seconds(1))
    }

    private func expectMatchesBruteForce(_ hand: Hand, _ pool: CardPool, sourceLocation: SourceLocation = #_sourceLocation) {
        let brute = BruteForce(hand: hand, eligible: pool)
        #expect(Pricing.fairValue(of: hand, eligible: pool) == brute.mean, "\(hand.cards)", sourceLocation: sourceLocation)
        #expect(Pricing.maxPossibleSum(of: hand, eligible: pool) == brute.max, "\(hand.cards)", sourceLocation: sourceLocation)
        #expect(Pricing.minPossibleSum(of: hand, eligible: pool) == brute.min, "\(hand.cards)", sourceLocation: sourceLocation)
    }
}

private extension DealtCard {
    func withOverride(_ value: Int) -> DealtCard {
        DealtCard(card: card, isHidden: isHidden, valueOverride: value)
    }
}

@Suite("Rational")
struct RationalTests {
    @Test("Reduces and normalises sign")
    func reduces() {
        #expect(Rational(6, 4) == Rational(3, 2))
        #expect(Rational(3, -6) == Rational(-1, 2))
        #expect(Rational(3, -6).denominator == 2)
        #expect(Rational(0, 5) == .zero)
    }

    @Test("Arithmetic and ordering")
    func arithmetic() {
        #expect(Rational(1, 2) + Rational(1, 3) == Rational(5, 6))
        #expect(Rational(1, 2) - Rational(1, 3) == Rational(1, 6))
        #expect(Rational(2, 3) * Rational(3, 4) == Rational(1, 2))
        #expect(Rational(1322, 51) < 26)
        #expect(Rational(1322, 51) > 25)
        #expect(Rational(24) == 24)
    }
}
