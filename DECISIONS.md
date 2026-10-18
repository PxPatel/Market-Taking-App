# Decisions

Choices the spec leaves open or gets wrong, and why. Newest at the bottom of each section.

## Maths

**D1. Fair value is exact; the spec's "26" example is ≈ 25.92.** With one visible 10 and two hidden cards, each hidden card averages 406/51 (the 10 is out of the deck), so fair value is 1322/51 ≈ 25.92. The spec's own rule ("computed exactly from the remaining deck") wins over its example. Teaching a rounded 26 would mislead the player.

**D2. Fair value uses linearity of expectation, not enumeration.** Every unknown hidden card is an equally likely draw from the same remaining pool, so each is worth exactly the pool's mean, and fair value = known values + unknown count × pool mean. This is exact and instant. Max/min possible sums take the top/bottom values left in the pool. The tests include a brute-force enumeration (independent code) and check it against the closed form on hand-picked hands and 150 random hands across every event pool.

**D3. Fair value is a `Rational`, not a `Double`.** Questions like "is fair value above the Ask?" decide the correct action and the edge. Exact fractions mean ties are real ties, never floating-point noise.

**D4. Event-fixed hidden cards still use a real card.** For "card X is worth Y", the slot still holds a real drawn card (so the deck stays consistent and the reveal shows a real card), but it counts as Y. Which card it is stays unknown, so it doesn't change what the other hidden cards could be.

## Orders

**D5. Buy and sell checks follow the spec as written.** A buy must be fully paid for (size × Ask ≤ budget); a sell must cover its worst-case loss (size × (max sum − Bid) ≤ budget). The asymmetry is intended: cash for a long, margin for a short. Together they make a negative budget impossible (tested over 1,000 seeded sessions).

**D6. Hard size cap of 10,000.** If Bid ≥ max sum, a short risks nothing and the spec's rule allows any size. Phase 2 quote repair will prevent such quotes (D9), but the validator is total on its own: no order may exceed 10,000 units. This also bounds the custom size field and keeps arithmetic far from overflow.

## Quotes and events (applied in Phase 2)

**D7. "Card X is worth Y" targets a hidden card, needs ≥ 2 hidden cards, and Y is 2–14.** It reveals information about something the player can't see, which is the interesting part. Requiring a second hidden card means the price is never fully known, so there's always a judgement to make. Keeping Y within normal card values keeps the value chart meaningful.

**D8. Ties count Skip as correct.** If fair value equals the Ask (or Bid), the trade has zero edge: Skip is the correct action, and trading there counts as an "unnecessary trade" in the review.

**D9. Quotes never offer a risk-free trade.** After any provider returns a quote, the game repairs it so that Bid ≥ min sum, Ask ≤ max sum, Bid < max sum and Ask > min sum, with spread ≥ 1 and both positive. A quote you can't lose on would teach nothing.

**D10. Quote noise varies with the preset.** Easy quotes sit further from fair value (clear edges, so the player learns to spot them); Hard quotes sit closer (subtle edges and more correct skips). This is a `RandomQuoteProvider` parameter, not a different provider.

## Session and settings

**D11. Card count and hidden count are drawn per round.** A preset sets a range of card counts (Easy 3, Standard 3–4, Hard 4–6) and each round picks one at random. Card values never change except through a market event. Hidden count is either "all hidden" or "random", where 0 to n−1 cards are face up (1 to n hidden), drawn per round. Custom settings default to all hidden, as in the spec; all three presets use random so the player has to condition on visible cards.

**D12. Backgrounding redeals the round.** If the app is backgrounded mid-round, the timer stops and on return the round is dealt again (new cards, new quote, any event re-rolled). Showing the same cards with a fresh quote would give the player free thinking time. The redeal comes from the same seeded generator, so a replay stays deterministic given the same background events.

**D13. Reported return is the round's profit or loss.** In return-reporting mode the player types that round's P&L, not the running budget. The review also derives the player's mental budget from their answers, to find the first round it diverged.

**D14. Spec open questions (section 14).**
- **Default session length: 10 rounds.** Four rounds is too few to separate skill from luck in the review.
- **Budget shown on Easy and Standard: yes.** It updates quietly after the reveal. It reflects the outcome (partly luck), not decision quality, so it doesn't break the no-feedback rule. Hard hides it.
- **Timeout: no penalty, equal to a skip.** It is recorded and counted separately in the review, so slowness is visible without punishing the budget.
- **Quote difficulty varies by preset** (D10).

## Build

**D15. Package at the repo root, Swift 6.4, iOS 18.** The package follows `xtool new`'s layout: one library product (`TrainerApp`), plus `xtool.yml`. Tools version 6.0. Developed and tested against the Swift 6.4.1 toolchain, which current xtool docs require.

**D16. `TrainerApp` sources are guarded by `#if canImport(SwiftUI)`.** `swift test` builds every target, and SwiftUI doesn't exist on Linux. A `#if os(Linux)` switch in Package.swift would not work, because xtool also evaluates the manifest on Linux when cross-compiling.

**D17. Own uniform-int and sampling code.** `Int.random(in:using:)`'s algorithm is a standard-library detail that may change between Swift releases; owning it (Lemire's method, partial Fisher–Yates) keeps seeded replays stable.
