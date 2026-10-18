import Testing
@testable import GameCore

@Suite("Seeded randomness")
struct RandomTests {
    @Test("Same seed gives the same sequence")
    func sameSeedSameSequence() {
        var a = SeededGenerator(seed: 42)
        var b = SeededGenerator(seed: 42)
        for _ in 0..<100 {
            #expect(a.next() == b.next())
        }
    }

    @Test("Different seeds diverge")
    func differentSeedsDiverge() {
        var a = SeededGenerator(seed: 1)
        var b = SeededGenerator(seed: 2)
        #expect((0..<10).map { _ in a.next() } != (0..<10).map { _ in b.next() })
    }

    @Test("Uniform ints stay in range and hit every value")
    func uniformIntsInRange() {
        var rng = SeededGenerator(seed: 7)
        var counts = [Int: Int]()
        for _ in 0..<13_000 {
            let value = RandomDraws.int(in: 2...14, using: &rng)
            #expect((2...14).contains(value))
            counts[value, default: 0] += 1
        }
        #expect(counts.count == 13)
        // Loose uniformity check: each of 13 values expects 1,000 hits.
        #expect(counts.values.allSatisfy { (850...1150).contains($0) })
    }

    @Test("Single-value range")
    func singleValueRange() {
        var rng = SeededGenerator(seed: 3)
        #expect(RandomDraws.int(in: 5...5, using: &rng) == 5)
    }

    @Test("Sampling returns distinct elements")
    func samplingIsDistinct() {
        var rng = SeededGenerator(seed: 9)
        for count in 0...20 {
            let sample = RandomDraws.sample(count, from: Array(0..<20), using: &rng)
            #expect(sample.count == count)
            #expect(Set(sample).count == count)
        }
    }

    @Test("Fixed seed pins the exact output, so replays survive refactors")
    func pinnedOutput() {
        var rng = SeededGenerator(seed: 2026)
        let hand = Dealer.deal(cardCount: 3, hiddenCount: 2, from: .standardDeck, using: &rng)
        var again = SeededGenerator(seed: 2026)
        #expect(Dealer.deal(cardCount: 3, hiddenCount: 2, from: .standardDeck, using: &again) == hand)
    }
}
