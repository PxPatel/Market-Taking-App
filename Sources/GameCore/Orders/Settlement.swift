public enum Settlement {
    /// Realised profit of `order` once the true sum is revealed.
    /// Buy: `size × (sum − ask)`. Sell: `size × (bid − sum)`. Skip: 0.
    public static func profit(of order: Order, quote: Quote, trueSum: Int) -> Int {
        switch order {
        case .buy(let size): size * (trueSum - quote.ask)
        case .sell(let size): size * (quote.bid - trueSum)
        case .skip: 0
        }
    }

    /// Budget after settling a valid order. The validity rules guarantee this is
    /// never negative: a buy can lose at most its cost, and a sell at most the
    /// worst-case loss it was checked against.
    public static func settle(_ order: Order, quote: Quote, trueSum: Int, in context: OrderContext) -> Int {
        precondition(OrderValidator.isValid(order, in: context), "Cannot settle an invalid order")
        let budget = context.budget + profit(of: order, quote: quote, trueSum: trueSum)
        assert(budget >= 0, "Validity rules should make a negative budget impossible")
        return budget
    }
}
