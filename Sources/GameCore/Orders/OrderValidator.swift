/// Everything needed to decide whether an order is allowed.
public struct OrderContext: Hashable, Sendable {
    public let quote: Quote
    public let budget: Int
    /// Exact max possible sum for the round (see `Pricing.maxPossibleSum`).
    public let maxPossibleSum: Int

    public init(quote: Quote, budget: Int, maxPossibleSum: Int) {
        precondition(budget >= 0, "Budget cannot be negative")
        self.quote = quote
        self.budget = budget
        self.maxPossibleSum = maxPossibleSum
    }
}

public enum OrderRejection: Hashable, Sendable {
    case sizeNotPositive
    case sizeAboveLimit(limit: Int)
    case insufficientBudget(required: Int, budget: Int)

    /// Short reason shown under a disabled button.
    public var message: String {
        switch self {
        case .sizeNotPositive: "Size must be at least 1"
        case .sizeAboveLimit(let limit): "Max size is \(limit)"
        case .insufficientBudget(let required, let budget): "Needs \(required), budget \(budget)"
        }
    }
}

/// The single source of truth for order validity. The UI asks this module
/// before enabling a button, and the session asks it again before settling,
/// so the UI can never accept an order the engine would reject.
public enum OrderValidator {
    /// Hard ceiling on any order size. Keeps arithmetic far from overflow and
    /// bounds the custom-size field. With a 10,000 budget it never binds on a
    /// sensible quote.
    public static let maximumSize = 10_000

    /// Capital an order ties up.
    /// - Buy: the full cost, `size × ask`.
    /// - Sell: the worst-case loss, `size × (maxPossibleSum − bid)`, floored at 0.
    public static func requiredCapital(side: Side, size: Int, in context: OrderContext) -> Int {
        switch side {
        case .buy: size * context.quote.ask
        case .sell: size * max(0, context.maxPossibleSum - context.quote.bid)
        }
    }

    /// `nil` when the order is valid, otherwise why it is not. Skip is always valid.
    public static func rejection(for order: Order, in context: OrderContext) -> OrderRejection? {
        guard let side = order.side else { return nil }
        let size = order.size
        if size < 1 { return .sizeNotPositive }
        if size > maximumSize { return .sizeAboveLimit(limit: maximumSize) }
        let required = requiredCapital(side: side, size: size, in: context)
        if required > context.budget {
            return .insufficientBudget(required: required, budget: context.budget)
        }
        return nil
    }

    public static func isValid(_ order: Order, in context: OrderContext) -> Bool {
        rejection(for: order, in: context) == nil
    }

    /// The largest valid size for `side`, or 0 if not even one unit is affordable.
    public static func maxValidSize(side: Side, in context: OrderContext) -> Int {
        let perUnit = requiredCapital(side: side, size: 1, in: context)
        guard perUnit > 0 else { return maximumSize }
        return min(maximumSize, context.budget / perUnit)
    }
}
