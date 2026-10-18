public enum Side: String, Codable, Hashable, Sendable {
    case buy, sell
}

/// The player's decision for a round.
public enum Order: Hashable, Codable, Sendable {
    case buy(size: Int)
    case sell(size: Int)
    case skip

    public init(side: Side, size: Int) {
        switch side {
        case .buy: self = .buy(size: size)
        case .sell: self = .sell(size: size)
        }
    }

    public var side: Side? {
        switch self {
        case .buy: .buy
        case .sell: .sell
        case .skip: nil
        }
    }

    public var size: Int {
        switch self {
        case .buy(let size), .sell(let size): size
        case .skip: 0
        }
    }
}
