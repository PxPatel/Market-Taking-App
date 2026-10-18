import Testing
@testable import GameCore

@Suite("Cards, deck and pools")
struct CardTests {
    @Test("Standard deck has 52 distinct cards, 13 values in each of 4 suits")
    func standardDeck() {
        let deck = Deck.standard
        #expect(deck.count == 52)
        #expect(Set(deck).count == 52)
        for suit in Suit.allCases {
            #expect(deck.filter { $0.suit == suit }.map(\.value) == Array(2...14))
        }
        #expect(CardPool.standardDeck.valueSum == 416)
    }

    @Test("Face card values: J 11, Q 12, K 13, A 14")
    func faceCardNames() {
        #expect(card(11, .spades).description == "J♠")
        #expect(card(12, .hearts).description == "Q♥")
        #expect(card(13, .diamonds).description == "K♦")
        #expect(card(14, .clubs).description == "A♣")
        #expect(card(7, .spades).description == "7♠")
    }

    @Test("Red and black suits")
    func colours() {
        #expect(Suit.hearts.isRed && Suit.diamonds.isRed)
        #expect(!Suit.spades.isRed && !Suit.clubs.isRed)
    }

    @Test("Event-style filters produce the right pools")
    func filteredPools() {
        #expect(TestPools.tenOrMore.count == 20)
        #expect(Set(TestPools.tenOrMore.cards.map(\.value)) == [10, 11, 12, 13, 14])
        #expect(TestPools.sevenOrLess.count == 24)
        #expect(Set(TestPools.sevenOrLess.cards.map(\.value)) == [2, 3, 4, 5, 6, 7])
        #expect(TestPools.even.count == 28)
        #expect(Set(TestPools.even.cards.map(\.value)) == [2, 4, 6, 8, 10, 12, 14])
        #expect(TestPools.odd.count == 24)
        #expect(Set(TestPools.odd.cards.map(\.value)) == [3, 5, 7, 9, 11, 13])
        #expect(TestPools.red.count == 26 && TestPools.red.cards.allSatisfy(\.suit.isRed))
        #expect(TestPools.black.count == 26 && TestPools.black.cards.allSatisfy { !$0.suit.isRed })
    }

    @Test("Unconditioned hidden-card means match the spec table")
    func poolMeans() {
        #expect(Rational(TestPools.all.valueSum, TestPools.all.count) == 8)
        #expect(Rational(TestPools.tenOrMore.valueSum, TestPools.tenOrMore.count) == 12)
        #expect(Rational(TestPools.sevenOrLess.valueSum, TestPools.sevenOrLess.count) == Rational(9, 2))
        #expect(Rational(TestPools.even.valueSum, TestPools.even.count) == 8)
        #expect(Rational(TestPools.odd.valueSum, TestPools.odd.count) == 8)
        #expect(Rational(TestPools.red.valueSum, TestPools.red.count) == 8)
    }

    @Test("Removing cards from a pool")
    func removing() {
        let pool = CardPool.standardDeck.removing([card(7, .spades), card(14, .hearts)])
        #expect(pool.count == 50)
        #expect(!pool.cards.contains(card(7, .spades)))
        #expect(pool.valueSum == 416 - 21)
    }

    @Test("A hand with no hidden card is rejected")
    func handNeedsHiddenCard() async {
        await #expect(processExitsWith: .failure) {
            _ = Hand([DealtCard(card: Card(value: 5, suit: .spades), isHidden: false)])
        }
    }

    @Test("A hand cannot repeat a card")
    func handRejectsDuplicates() async {
        await #expect(processExitsWith: .failure) {
            let seven = Card(value: 7, suit: .spades)
            _ = Hand([DealtCard(card: seven, isHidden: false), DealtCard(card: seven, isHidden: true)])
        }
    }

    @Test("True sum uses event overrides")
    func trueSumWithOverride() {
        let hand = Hand([up(10, .spades), down(3, .hearts, override: 9), down(5, .clubs)])
        #expect(hand.trueSum == 10 + 9 + 5)
    }
}

@Suite("Dealing")
struct DealerTests {
    @Test("Deals without replacement, from the pool, with the requested hidden count")
    func dealsCorrectly() {
        var rng = SeededGenerator(seed: 11)
        for _ in 0..<1000 {
            let pool = TestPools.everyPool[RandomDraws.int(in: 0...6, using: &rng)]
            let count = RandomDraws.int(in: 2...8, using: &rng)
            let hidden = RandomDraws.int(in: 1...count, using: &rng)
            let hand = Dealer.deal(cardCount: count, hiddenCount: hidden, from: pool, using: &rng)
            #expect(hand.cards.count == count)
            #expect(hand.hiddenCount == hidden)
            #expect(Set(hand.cards.map(\.card)).count == count)
            #expect(hand.cards.allSatisfy { pool.cards.contains($0.card) })
        }
    }

    @Test("Hidden positions vary across deals")
    func hiddenPositionsVary() {
        var rng = SeededGenerator(seed: 5)
        var patterns = Set<[Bool]>()
        for _ in 0..<200 {
            let hand = Dealer.deal(cardCount: 3, hiddenCount: 1, from: .standardDeck, using: &rng)
            patterns.insert(hand.cards.map(\.isHidden))
        }
        #expect(patterns.count == 3)
    }
}
