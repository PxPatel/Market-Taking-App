/// A market maker quote: the player may sell at `bid` or buy at `ask`.
///
/// This is a plain value. Rules on what makes a quote acceptable (bid < ask,
/// spread, plausible range) are enforced by the game when a provider returns
/// one, in Phase 2.
public struct Quote: Hashable, Codable, Sendable, CustomStringConvertible {
    public let bid: Int
    public let ask: Int

    public init(bid: Int, ask: Int) {
        self.bid = bid
        self.ask = ask
    }

    public var spread: Int { ask - bid }

    public var description: String { "\(bid) at \(ask)" }
}
