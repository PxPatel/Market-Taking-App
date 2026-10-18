@testable import GameCore

/// Event-style pool filters. The real `MarketEvent` types arrive in Phase 2;
/// these let Phase 1 pricing tests cover the same pools.
enum TestPools {
    static let all = CardPool.standardDeck
    static let tenOrMore = CardPool.standardDeck.filter { $0.value >= 10 }
    static let sevenOrLess = CardPool.standardDeck.filter { $0.value <= 7 }
    static let even = CardPool.standardDeck.filter { $0.value.isMultiple(of: 2) }
    static let odd = CardPool.standardDeck.filter { !$0.value.isMultiple(of: 2) }
    static let red = CardPool.standardDeck.filter(\.suit.isRed)
    static let black = CardPool.standardDeck.filter { !$0.suit.isRed }

    static let everyPool = [all, tenOrMore, sevenOrLess, even, odd, red, black]
}

func card(_ value: Int, _ suit: Suit) -> Card {
    Card(value: value, suit: suit)
}

func up(_ value: Int, _ suit: Suit) -> DealtCard {
    DealtCard(card: Card(value: value, suit: suit), isHidden: false)
}

func down(_ value: Int, _ suit: Suit, override: Int? = nil) -> DealtCard {
    DealtCard(card: Card(value: value, suit: suit), isHidden: true, valueOverride: override)
}

/// Independent brute-force pricing: assign every ordered tuple of distinct
/// cards from the unknown pool to the hidden positions, and average / max / min
/// the resulting true sums. Deliberately shares no logic with `Pricing`.
struct BruteForce {
    let mean: Rational
    let max: Int
    let min: Int

    init(hand: Hand, eligible pool: CardPool) {
        let faceUp = Set(hand.cards.filter { !$0.isHidden }.map(\.card))
        let candidates = pool.cards.filter { !faceUp.contains($0) }
        let hiddenSlots = hand.cards.filter(\.isHidden)
        let visibleSum = hand.cards.filter { !$0.isHidden }.reduce(0) { $0 + $1.value }

        var total = 0
        var count = 0
        var best = Int.min
        var worst = Int.max
        var used = [Bool](repeating: false, count: candidates.count)

        func assign(_ slot: Int, _ partial: Int) {
            if slot == hiddenSlots.count {
                let sum = visibleSum + partial
                total += sum
                count += 1
                best = Swift.max(best, sum)
                worst = Swift.min(worst, sum)
                return
            }
            for i in candidates.indices where !used[i] {
                used[i] = true
                let value = hiddenSlots[slot].valueOverride ?? candidates[i].value
                assign(slot + 1, partial + value)
                used[i] = false
            }
        }
        assign(0, 0)

        mean = Rational(total, count)
        max = best
        min = worst
    }
}
