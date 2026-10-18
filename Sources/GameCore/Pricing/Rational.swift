/// An exact fraction, always stored reduced with a positive denominator.
///
/// Fair value is usually not a whole number (one visible 10 plus two hidden
/// cards is 1322/51). Keeping it exact means comparisons against a quote, such
/// as "is fair value above the Ask?", never go wrong through floating-point
/// rounding.
public struct Rational: Hashable, Comparable, Codable, Sendable, CustomStringConvertible {
    public let numerator: Int
    public let denominator: Int

    public init(_ numerator: Int, _ denominator: Int = 1) {
        precondition(denominator != 0, "Denominator cannot be zero")
        let divisor = Self.gcd(abs(numerator), abs(denominator))
        let sign = denominator < 0 ? -1 : 1
        self.numerator = sign * numerator / max(divisor, 1)
        self.denominator = sign * denominator / max(divisor, 1)
    }

    public static let zero = Rational(0)

    public var doubleValue: Double {
        Double(numerator) / Double(denominator)
    }

    public var isInteger: Bool {
        denominator == 1
    }

    public var description: String {
        isInteger ? String(numerator) : "\(numerator)/\(denominator)"
    }

    public static func + (lhs: Rational, rhs: Rational) -> Rational {
        Rational(lhs.numerator * rhs.denominator + rhs.numerator * lhs.denominator, lhs.denominator * rhs.denominator)
    }

    public static func - (lhs: Rational, rhs: Rational) -> Rational {
        lhs + Rational(-rhs.numerator, rhs.denominator)
    }

    public static func * (lhs: Rational, rhs: Rational) -> Rational {
        Rational(lhs.numerator * rhs.numerator, lhs.denominator * rhs.denominator)
    }

    public static func < (lhs: Rational, rhs: Rational) -> Bool {
        lhs.numerator * rhs.denominator < rhs.numerator * lhs.denominator
    }

    private static func gcd(_ a: Int, _ b: Int) -> Int {
        b == 0 ? a : gcd(b, a % b)
    }
}

extension Rational: ExpressibleByIntegerLiteral {
    public init(integerLiteral value: Int) {
        self.init(value)
    }
}
