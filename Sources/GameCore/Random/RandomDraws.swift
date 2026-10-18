/// Uniform draws implemented here rather than via `Int.random(in:using:)`, whose
/// algorithm is a standard-library detail that may change between Swift
/// releases. Owning it keeps seeded sessions replayable across toolchains.
public enum RandomDraws {
    /// A uniformly distributed integer in `range`, without modulo bias.
    public static func int<G: RandomNumberGenerator>(
        in range: ClosedRange<Int>,
        using rng: inout G
    ) -> Int {
        // Wrapping arithmetic: the width of e.g. Int.min...Int.max overflows Int.
        let span = UInt64(bitPattern: Int64(range.upperBound &- range.lowerBound)) &+ 1
        if span == 0 { // the full 64-bit range
            return Int(truncatingIfNeeded: rng.next())
        }
        // Lemire's method: reject the small biased tail.
        let threshold = (0 &- span) % span
        while true {
            let (high, low) = span.multipliedFullWidth(by: rng.next())
            if low >= threshold {
                return range.lowerBound &+ Int(truncatingIfNeeded: high)
            }
        }
    }

    /// `count` distinct elements of `items`, in random order (partial Fisher-Yates).
    public static func sample<T, G: RandomNumberGenerator>(
        _ count: Int,
        from items: [T],
        using rng: inout G
    ) -> [T] {
        precondition(count >= 0 && count <= items.count, "Cannot sample \(count) of \(items.count)")
        var pool = items
        for i in 0..<count {
            let j = int(in: i...(pool.count - 1), using: &rng)
            pool.swapAt(i, j)
        }
        return Array(pool.prefix(count))
    }
}
