public enum Suit: String, CaseIterable, Codable, Hashable, Sendable {
    case spades, hearts, diamonds, clubs

    public var isRed: Bool {
        self == .hearts || self == .diamonds
    }
}
