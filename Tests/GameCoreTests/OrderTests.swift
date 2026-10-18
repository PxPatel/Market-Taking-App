import Testing
@testable import GameCore

@Suite("Order validation")
struct OrderValidatorTests {
    // Quote 20 at 24; max possible sum 42, so a short risks 22 per unit.
    private func context(budget: Int, bid: Int = 20, ask: Int = 24, max: Int = 42) -> OrderContext {
        OrderContext(quote: Quote(bid: bid, ask: ask), budget: budget, maxPossibleSum: max)
    }

    @Test("Buy costing exactly the budget is valid; one more unit is not")
    func buyBoundary() {
        let ctx = context(budget: 240)
        #expect(OrderValidator.isValid(.buy(size: 10), in: ctx))
        #expect(OrderValidator.rejection(for: .buy(size: 11), in: ctx) == .insufficientBudget(required: 264, budget: 240))
        #expect(OrderValidator.maxValidSize(side: .buy, in: ctx) == 10)
    }

    @Test("Sell whose max loss equals the budget is valid; one more unit is not")
    func sellBoundary() {
        let ctx = context(budget: 220)
        #expect(OrderValidator.requiredCapital(side: .sell, size: 10, in: ctx) == 220)
        #expect(OrderValidator.isValid(.sell(size: 10), in: ctx))
        #expect(OrderValidator.rejection(for: .sell(size: 11), in: ctx) == .insufficientBudget(required: 242, budget: 220))
        #expect(OrderValidator.maxValidSize(side: .sell, in: ctx) == 10)
    }

    @Test("Size zero and negative are rejected for both sides")
    func nonPositiveSizes() {
        let ctx = context(budget: 500)
        for size in [0, -1, -10] {
            #expect(OrderValidator.rejection(for: .buy(size: size), in: ctx) == .sizeNotPositive)
            #expect(OrderValidator.rejection(for: .sell(size: size), in: ctx) == .sizeNotPositive)
        }
    }

    @Test("Skip is always valid, even with no budget")
    func skipAlwaysValid() {
        #expect(OrderValidator.isValid(.skip, in: context(budget: 0)))
        #expect(OrderValidator.isValid(.skip, in: context(budget: 500)))
    }

    @Test("When nothing is affordable only Skip remains")
    func nothingAffordable() {
        let ctx = context(budget: 10)
        #expect(OrderValidator.maxValidSize(side: .buy, in: ctx) == 0)
        #expect(OrderValidator.maxValidSize(side: .sell, in: ctx) == 0)
        #expect(!OrderValidator.isValid(.buy(size: 1), in: ctx))
        #expect(!OrderValidator.isValid(.sell(size: 1), in: ctx))
        #expect(OrderValidator.isValid(.skip, in: ctx))
    }

    @Test("Short risk uses the exact max sum, not a constant")
    func sellUsesExactMax() {
        // Same quote, but an event limits the max sum to 30: risk 10 per unit.
        let ctx = context(budget: 100, max: 30)
        #expect(OrderValidator.maxValidSize(side: .sell, in: ctx) == 10)
    }

    @Test("A bid at or above the max sum risks nothing, but the hard size cap still applies")
    func riskFreeSellCapped() {
        let ctx = context(budget: 100, bid: 42, ask: 44, max: 42)
        #expect(OrderValidator.requiredCapital(side: .sell, size: 50, in: ctx) == 0)
        #expect(OrderValidator.maxValidSize(side: .sell, in: ctx) == OrderValidator.maximumSize)
        #expect(OrderValidator.rejection(for: .sell(size: OrderValidator.maximumSize + 1), in: ctx)
            == .sizeAboveLimit(limit: OrderValidator.maximumSize))
    }

    @Test("Rejection message reads like the spec: 'Needs 240, budget 180'")
    func message() {
        #expect(OrderRejection.insufficientBudget(required: 240, budget: 180).message == "Needs 240, budget 180")
    }

    @Test("maxValidSize is valid and maxValidSize + 1 is not, across random contexts")
    func maxValidSizeIsTight() {
        var rng = SeededGenerator(seed: 99)
        for _ in 0..<2000 {
            let bid = RandomDraws.int(in: 1...100, using: &rng)
            let ask = bid + RandomDraws.int(in: 1...6, using: &rng)
            let max = RandomDraws.int(in: (bid + 1)...130, using: &rng)
            let ctx = OrderContext(quote: Quote(bid: bid, ask: ask), budget: RandomDraws.int(in: 0...10_000, using: &rng), maxPossibleSum: max)
            for side in [Side.buy, .sell] {
                let size = OrderValidator.maxValidSize(side: side, in: ctx)
                if size > 0 {
                    #expect(OrderValidator.isValid(Order(side: side, size: size), in: ctx))
                }
                #expect(!OrderValidator.isValid(Order(side: side, size: size + 1), in: ctx))
            }
        }
    }
}

@Suite("Settlement")
struct SettlementTests {
    private let quote = Quote(bid: 20, ask: 24)

    @Test("Buy profit is size × (sum − ask)")
    func buy() {
        #expect(Settlement.profit(of: .buy(size: 5), quote: quote, trueSum: 30) == 30)
        #expect(Settlement.profit(of: .buy(size: 5), quote: quote, trueSum: 18) == -30)
    }

    @Test("Sell profit is size × (bid − sum)")
    func sell() {
        #expect(Settlement.profit(of: .sell(size: 5), quote: quote, trueSum: 30) == -50)
        #expect(Settlement.profit(of: .sell(size: 5), quote: quote, trueSum: 12) == 40)
    }

    @Test("Skip earns nothing")
    func skip() {
        #expect(Settlement.profit(of: .skip, quote: quote, trueSum: 40) == 0)
    }

    @Test("Settling updates the budget")
    func settleUpdatesBudget() {
        let ctx = OrderContext(quote: quote, budget: 500, maxPossibleSum: 42)
        #expect(Settlement.settle(.buy(size: 10), quote: quote, trueSum: 30, in: ctx) == 560)
        #expect(Settlement.settle(.sell(size: 10), quote: quote, trueSum: 30, in: ctx) == 400)
        #expect(Settlement.settle(.skip, quote: quote, trueSum: 30, in: ctx) == 500)
    }

    @Test("Worst case: a max-size sell that hits the max sum lands exactly on zero")
    func worstCaseSellHitsZero() {
        let ctx = OrderContext(quote: quote, budget: 220, maxPossibleSum: 42)
        #expect(Settlement.settle(.sell(size: 10), quote: quote, trueSum: 42, in: ctx) == 0)
    }

    @Test("Budget never goes below zero across 1,000 seeded random sessions")
    func budgetNeverNegative() {
        for seed in UInt64(0)..<1000 {
            var rng = SeededGenerator(seed: seed)
            var budget = 500
            for _ in 0..<10 {
                let pool = TestPools.everyPool[RandomDraws.int(in: 0...6, using: &rng)]
                let count = RandomDraws.int(in: 2...8, using: &rng)
                let hand = Dealer.deal(
                    cardCount: count,
                    hiddenCount: RandomDraws.int(in: 1...count, using: &rng),
                    from: pool,
                    using: &rng
                )
                let fair = Int(Pricing.fairValue(of: hand, eligible: pool).doubleValue.rounded())
                let bid = max(1, fair + RandomDraws.int(in: -8...8, using: &rng))
                let quote = Quote(bid: bid, ask: bid + RandomDraws.int(in: 1...4, using: &rng))
                let ctx = OrderContext(
                    quote: quote,
                    budget: budget,
                    maxPossibleSum: Pricing.maxPossibleSum(of: hand, eligible: pool)
                )
                let side: Side = RandomDraws.int(in: 0...1, using: &rng) == 0 ? .buy : .sell
                // Mostly go all-in to stress the boundary.
                let maxSize = OrderValidator.maxValidSize(side: side, in: ctx)
                let order: Order = maxSize == 0 ? .skip : Order(side: side, size: RandomDraws.int(in: max(1, maxSize - 2)...maxSize, using: &rng))
                budget = Settlement.settle(order, quote: quote, trueSum: hand.trueSum, in: ctx)
                #expect(budget >= 0)
            }
        }
    }
}
