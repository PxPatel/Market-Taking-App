import Foundation
import Testing
@testable import GameCore

@Suite("Guards and edge cases")
struct RobustnessTests {
    @Test("Uniform draws work on ranges wider than Int.max")
    func wideRanges() {
        var rng = SeededGenerator(seed: 4)
        for range in [Int.min...Int.max, -1...Int.max, (Int.min / 2 - 10)...(Int.max / 2 + 10), -5 ... -5] {
            for _ in 0..<100 {
                #expect(range.contains(RandomDraws.int(in: range, using: &rng)))
            }
        }
    }

    @Test("Decoded Rationals are normalised; a zero denominator is rejected")
    func rationalDecoding() throws {
        let half = try JSONDecoder().decode(Rational.self, from: Data(#"{"numerator":2,"denominator":4}"#.utf8))
        #expect(half == Rational(1, 2))
        #expect(throws: DecodingError.self) {
            _ = try JSONDecoder().decode(Rational.self, from: Data(#"{"numerator":1,"denominator":0}"#.utf8))
        }
        let fair = Rational(1322, 51)
        #expect(try JSONDecoder().decode(Rational.self, from: JSONEncoder().encode(fair)) == fair)
    }

    @Test("Decoding a hand with no hidden card is rejected, a valid hand round-trips")
    func handDecoding() throws {
        let valid = Hand([up(10, .spades), down(3, .hearts, override: 9)])
        #expect(try JSONDecoder().decode(Hand.self, from: JSONEncoder().encode(valid)) == valid)
        let allUp = #"{"cards":[{"card":{"value":5,"suit":"spades"},"isHidden":false}]}"#
        #expect(throws: DecodingError.self) {
            _ = try JSONDecoder().decode(Hand.self, from: Data(allUp.utf8))
        }
    }

    @Test("An override outside 2...14 is rejected")
    func overrideRange() async {
        await #expect(processExitsWith: .failure) {
            _ = DealtCard(card: Card(value: 5, suit: .spades), isHidden: true, valueOverride: -100)
        }
    }

    @Test("Settling with a true sum above the max possible sum is rejected")
    func settleChecksTrueSum() async {
        await #expect(processExitsWith: .failure) {
            let ctx = OrderContext(quote: Quote(bid: 20, ask: 24), budget: 220, maxPossibleSum: 42)
            _ = Settlement.settle(.sell(size: 10), trueSum: 43, in: ctx)
        }
    }
}
