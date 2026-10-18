#if canImport(SwiftUI)
import GameCore
import SwiftUI

/// Phase 0 placeholder: proves the app installs and links GameCore.
struct HelloScreen: View {
    /// Fair value of a single hidden card from a full deck, computed by GameCore.
    private let oneHiddenCardValue: String = {
        var rng = SeededGenerator(seed: 1)
        let hand = Dealer.deal(cardCount: 1, hiddenCount: 1, from: .standardDeck, using: &rng)
        return Pricing.fairValue(of: hand, eligible: .standardDeck).description
    }()

    var body: some View {
        VStack(spacing: 16) {
            Text("Market Taking Trainer")
                .font(.title.bold())
            Text("A hidden card is worth \(oneHiddenCardValue) on average.")
                .font(.body)
                .foregroundStyle(.secondary)
        }
        .multilineTextAlignment(.center)
        .padding()
    }
}
#endif
