# Market Taking Trainer: Claude Code Brief and Product Spec

Oct 15, 2026 · @Tanya

## 1. Kickoff prompt for Claude Code

Paste this into Claude Code as your first message, after saving the rest of this document into your repo as `SPEC.md`.

```text
You are building an iOS app called "Market Taking Trainer" in Swift and SwiftUI. It is a speed-training game for aspiring quant traders: the player trades against a market maker quoting a hand of mostly hidden playing cards, works out the expected value in their head, and chooses Buy, Sell or Skip before a timer runs out.

The full product spec is in SPEC.md. Read all of it before writing any code, then reply with (1) a short summary of what you understood, (2) any ambiguities or risks you see, and (3) the plan for Phase 0 and Phase 1. Wait for my go-ahead before building past Phase 1.

Hard constraints:
- I develop on Windows using WSL2 (Ubuntu). There is no Mac and no Xcode project. The app is built with xtool (https://github.com/xtool-org/xtool) as a SwiftPM package and installed on my physical iPhone (iOS 18) over USB with a free Apple ID.
- There is no iOS Simulator, no SwiftUI previews, and no Xcode debugger. All game logic must therefore live in a pure Swift library target with zero UIKit/SwiftUI imports, fully unit tested on Linux with `swift test`. The SwiftUI app target is a thin layer on top.
- Do not add third-party dependencies unless I approve them.
- The market maker quote logic must sit behind a protocol so I can swap or extend strategies later without touching game flow code (see spec section 7).
- The player gets NO per-round feedback on correctness or EV. Review happens only after the final round of a session (see spec section 9).
- The UI must be clean and simple, with a dark and a light theme.

Working style:
- Work in the phases defined in SPEC.md section 14. At the end of each phase, run the tests, summarise what exists, tell me exactly how to build and run it on my phone with xtool, and stop for my feedback.
- Write tests alongside the logic, not after. Every rule in sections 5 to 8 of the spec should map to at least one test.
- Keep files small and named by responsibility. Explain any non-obvious decision in a short comment or in DECISIONS.md.
- If a spec detail is missing or contradictory, ask me rather than guessing silently. If you must assume, record the assumption in DECISIONS.md.
- Before telling me something works on-device, say clearly whether you verified it (tests run, build succeeded) or are only expecting it to work, since you cannot run the app on my iPhone yourself.
```

## 2. Skills and capabilities for the agent

The agent needs these skills to build this app well without a Mac.

| Skill | Why this project needs it | How the agent should use it |
| --- | --- | --- |
| Swift 6 and SwiftPM | The whole app is a Swift package built by xtool | Structure targets (`GameCore`, `TrainerApp`), manage `Package.swift`, keep strict concurrency clean |
| SwiftUI | The UI layer, including animation and theming | Build small, composable views driven by observable state; avoid UIKit unless unavoidable |
| State machines | The game is a session of rounds with phases (quoting, deciding, revealing, review) | Model session and round state as explicit enums with legal transitions, tested without UI |
| Probability and expected value | Core domain: fair value, variance, event-conditioned card distributions | Implement exact calculation by enumeration over the remaining deck, not approximation |
| Protocol-oriented design | The quote engine and event system must be swappable | Define protocols and inject implementations; no strategy logic inside game flow |
| Swift Testing or XCTest on Linux | There is no simulator, so tests are the main safety net | Run `swift test` in WSL after every change; seed random number generators for reproducibility |
| Seeded random number generation | Deterministic tests and replayable sessions | Inject a `RandomNumberGenerator`; never call global random inside logic |
| xtool workflow | Build, sign and install to the iPhone from WSL | Use `xtool new`, `xtool dev`, `xtool devices`; document the exact commands in README.md |
| WSL and USB troubleshooting | usbipd passthrough, trust prompts and Developer Mode are common blockers | Give me a short checklist when a device step fails rather than guessing |
| Timer and concurrency in SwiftUI | Per-round countdown must be accurate and cancellable | Use a monotonic clock and structured concurrency; test timer logic with an injectable clock |
| Local persistence | Settings and session history survive app restarts | Use `Codable` JSON in the app's documents directory; keep it behind a storage protocol |
| UI/UX design for speed games | Layout must support fast, error-free tapping under time pressure | Large tap targets, stable layout with no shifting buttons, thumb-reachable controls |
| Accessibility | Dynamic Type, VoiceOver labels, contrast in both themes | Label cards and quote values; never rely on colour alone for buy and sell |
| Git hygiene | Phased delivery with checkpoints | Commit at the end of each phase with a clear message; keep DECISIONS.md current |

Claude Code features worth using:

- **Plan mode** at the start of each phase, so the plan is reviewed before files change.
- **A `CLAUDE.md` file** in the repo root holding the hard constraints from section 1 (WSL, xtool, no simulator, pure-logic target, no per-round feedback). Ask the agent to create it in Phase 0.
- **Custom slash commands or a small script** for the repeated loop: run tests, then build with xtool. Optional, but it saves time.
- **Subagents** for an independent review of the EV maths and the order-validation rules, since errors there silently teach the player wrong things.

## 3. Product description

Market Taking Trainer is an iPhone game that builds the one skill quant trading interviews test hardest: judging a price against expected value, fast, under pressure. Inspired by the Market Taking Game on tradermath.org, it is a cleaner, mobile-first version built for repeated short practice sessions.

**The core loop.** Each round shows a hand of playing cards, some face up and some face down, and a market maker quote of the form Bid at Ask. The sum of all cards is the true market price, revealed only after the player decides. The player buys at the Ask, sells at the Bid, or skips, in a chosen size, before a countdown ends. Profit or loss is settled against the revealed sum.

**Who it is for.**

- Primary: students and career-changers preparing for quant trading internships and interviews, who need mental-maths and EV fluency.
- Secondary: the builder presenting the app on their own phone as a portfolio piece, so it must look polished and run reliably in a demo.

**What users need.**

- Practice that mimics the time pressure of a real trading interview.
- An uninterrupted flow state: no feedback mid-session that breaks concentration.
- Honest, useful feedback once the session is done, showing where their judgment lost or left money on the table.
- Control over difficulty so the game stays challenging as they improve.

**What users want.**

- A clean, calm interface with no clutter, readable at a glance and tappable in a hurry.
- Quick sessions they can fit into a few minutes.
- A sense of progress over time: better decisions, not just luckier outcomes.

**Product principles.**

1. Momentum over hand-holding. Nothing interrupts the player between rounds except the next round.
2. Skill over luck. Results are judged on decision quality (expected value captured) as well as realised profit.
3. Configurable difficulty. Every parameter that changes difficulty is a setting.
4. Extensible by design. Market maker behaviour and market events can be changed or added without reworking the game.

## 4. Use cases and user stories

| ID | As a... | I want to... | So that... |
| --- | --- | --- | --- |
| U1 | Learner | Start a session with sensible defaults in one tap | I can practise immediately |
| U2 | Learner | Choose number of cards, hidden cards, time per round and number of rounds | I can match difficulty to my level |
| U3 | Learner | Toggle market events on or off | I can add complexity once the basics are comfortable |
| U4 | Learner | See the cards, the quote, my budget and a visible countdown | I can decide quickly with full context |
| U5 | Learner | Pick an order size from presets (1, 5, 10) or enter a custom number | I can size by conviction |
| U6 | Learner | Be blocked, with a clear reason, from placing an invalid order | I understand budget and risk limits without guessing |
| U7 | Learner | Skip a round | I can decline a quote that has no edge |
| U8 | Learner | Have a missed deadline treated as a skip | The game keeps moving and time pressure is real |
| U9 | Learner | See all cards revealed and their sum at the end of each round, without being told whether I was right | I stay in flow |
| U10 | Learner | Report my return after each round (advanced difficulty) | I train mental book-keeping |
| U11 | Learner | Receive a full review only after the final round | I can reflect without losing momentum |
| U12 | Learner | Compare realised profit against expected value captured | I can separate skill from luck |
| U13 | Learner | See my session history and trends | I can see whether I am improving |
| U14 | Builder | Swap the market maker strategy without editing game flow | I can iterate on difficulty and realism |
| U15 | Builder | Add a new market event by writing one small type | I can extend the game cheaply |
| U16 | Builder | Replay a session from a seed | I can reproduce bugs and demo reliably |

**Primary scenario.** A learner opens the app on the train, taps Start with defaults (3 cards, 10 rounds, 10 seconds), plays ten uninterrupted rounds, and then sees a review showing that they left 14 points of expected value on the table, mostly by skipping quotes with clear edge. They tap Play again.

## 5. Game mechanics

**Session.** A session is a fixed number of rounds played with a starting budget of 500. One session produces one review at the end.

**Cards.**

- Card values run from 2 to 14, where J = 11, Q = 12, K = 13, A = 14.
- Cards are drawn from a standard 52-card deck, so the four suits are tracked (needed for red and black events). Draws within a round are without replacement: if a 7 of spades is face up, it cannot also be hidden.
- Each round deals N cards (default 3). Between 1 and N cards are hidden. At least one card is always hidden.
- Face-up cards are shown with their value and suit. Face-down cards show the card back.

**Market price.** The true price for the round is the sum of all card values after any event adjustments (section 6). It is decided when the round is dealt, kept hidden from the UI, and revealed after the decision.

**Quote.** The market maker shows Bid at Ask, with Bid < Ask. Quotes come from a pluggable engine (section 7).

**Decision.** Before the timer ends the player chooses one of:

- **Buy** Q units at the Ask. Profit = Q × (price − Ask).
- **Sell** Q units at the Bid. Profit = Q × (Bid − price).
- **Skip**. No position, profit = 0.

If the timer reaches zero without a decision, the round is recorded as a timeout and treated as a skip.

**Order size.** Quick chips for 1, 5 and 10, plus a custom entry. The last chosen size is remembered within the session so the player does not re-tap each round. Order validity is defined in section 8.

**Fair value.** Fair value is the expected sum given everything the player can see: the face-up cards, plus the expected value of each hidden card given the cards already visible and any active event. In the base game with no events and uniform draws, a hidden card has expected value 8. The engine computes fair value exactly, since it knows the remaining deck.

**Round flow.**

1. Deal cards and generate quote (and event, if enabled).
2. Show cards, quote, budget, round counter and a running countdown.
3. Player decides, or time expires.
4. Reveal all cards and the sum.
5. Show only the revealed cards and their sum. The budget display updates quietly on Easy and Standard, and stays hidden on Hard. No profit banner, no right or wrong message.
6. Short pause, then next round. No correctness feedback.

**Position reporting (advanced difficulty).** After the reveal, the player types their return for the round. In the hardest mode the budget display is hidden during play and the player must track it mentally. Answers are recorded and checked, but the result of the check is held until the session review.

**End of session.** After the last round, the review screen appears (section 9).

## 6. Market events

When enabled, a round may carry one event that changes the card pool for that round. The event is announced clearly on screen when the round starts, and it must be reflected in the true price, the fair value, and order validity. An event applies to the cards dealt that round only.

| Event | Effect on the card pool | Hidden card EV (approx.) |
| --- | --- | --- |
| Card X is worth Y | The card in position X has a fixed value Y this round | Y for that card |
| Only cards worth 10 or more | Cards valued 10 to 14 | 12 |
| Only cards worth 7 or less | Cards valued 2 to 7 | 4.5 |
| Only even cards | Even-valued cards only (2, 4, 6, 8, 10, 12, 14) | 8 |
| Only uneven cards | Odd-valued cards only (3, 5, 7, 9, 11, 13) | 8 |
| Only red cards | Hearts and diamonds | Depends on the face-up cards |
| Only black cards | Spades and clubs | Depends on the face-up cards |

Rules:

- Hidden-card EV is always computed exactly from the remaining eligible cards, taking the face-up cards out of the pool. The table gives the unconditioned approximation.
- The event is chosen before the cards are dealt, and every card in the round is then drawn from the eligible pool, so no shown card contradicts the event.
- At most one event per round. Event frequency (for example 25 percent of rounds) is a setting.
- Events are implemented as small types conforming to one protocol (`MarketEvent`), each providing its announcement text, the eligible card pool, and any value override. Adding an event must not require changes to round or session code.
- The event announcement uses a distinct colour and wording, and does not obscure the quote.

## 7. Market maker quote engine (pluggable)

The quote engine is a replaceable component. Version 1 quotes randomly, but the game must never depend on how a quote is produced.

**Need.** The builder wants to start simple and later make quotes smarter (near fair value, biased, adaptive to player skill) without refactoring round or session logic.

**Capability.** A single abstraction, `QuoteProvider`, takes in a description of the round (the cards dealt with their visible state, the active event, the difficulty settings, and an injected random number generator) and returns a quote with a Bid and an Ask. Nothing else in the app may generate or alter quotes.

**Rules every provider must satisfy** (enforced by the game, not trusted to the provider):

- Bid is lower than Ask, both are whole numbers, and both are positive.
- The spread is at least 1.
- Quotes sit within a plausible range for the round (between the minimum and maximum possible sum, give or take a margin), so quotes are not absurd.
- If a provider returns an invalid quote, the game repairs it or asks again, and logs it for tests.

**Version 1 provider: `RandomQuoteProvider`.**

- Pick a centre point at random around the round's fair value, with the spread of the offset set by a difficulty parameter.
- Pick a spread within a configured range (for example 1 to 4).
- Round to integers and apply the rules above.

**Designed-for next providers** (not built now, but the design must allow them):

- `FairValueNoiseProvider`: centres on exact fair value with controlled noise, so skipping is often correct.
- `BiasedProvider`: deliberately skewed to the buy or sell side to test whether the player notices.
- `AdaptiveProvider`: tightens or loosens quotes based on session history.

**Wiring.** The provider is chosen in one place (a session factory) and injected into the session. A setting can later expose provider choice in the UI. Tests use a `FixedQuoteProvider` that returns scripted quotes, so round and scoring logic can be tested without randomness.

## 8. Order validation and scoring rules

**Budget.** The player starts at 500. After each round the budget changes by that round's realised profit or loss and carries into the next round.

**Valid order rules.** Order size Q must be a whole number of at least 1.

| Order | Condition to be valid | Why |
| --- | --- | --- |
| Buy Q at Ask | Q × Ask ≤ budget | The player must be able to pay for the long position |
| Sell Q at Bid | Q × (Max possible sum − Bid) ≤ budget | Budget must cover the worst-case loss of the short |
| Skip | Always valid | No position taken |

**Max possible sum** is exact, not a fixed constant. It is the sum of face-up cards plus the highest values the hidden cards could take, given the cards already visible (a card shown face up cannot also be hidden), the active event's eligible pool, and any fixed-value override. Example: three hidden cards with no event can each be an ace (four exist), so the max is 14 + 14 + 14 = 42.

**Validation UX.**

- The Buy and Sell buttons show a disabled state and a short reason when the current size is invalid (for example, "Needs 240, budget 180").
- A custom size entry caps itself at the largest valid size for the chosen direction, and a "Max" shortcut sets it.
- If the player can afford nothing, only Skip remains enabled.
- Validation uses the same logic module as settlement, so the UI can never accept an order the engine would reject.

**Settlement.**

- Buy: profit = Q × (sum − Ask). Sell: profit = Q × (Bid − sum). Skip or timeout: 0.
- Budget updates by the profit, and a budget below zero must be impossible given the validity rules.

**Metrics recorded per round** (stored silently, shown only in the session review):

- Cards, face-up and hidden state, active event, quote, true sum.
- Exact fair value at decision time.
- Decision (buy, sell, skip or timeout), size, and decision time in seconds.
- Realised profit.
- Unit edge: for a buy, fair value minus Ask; for a sell, Bid minus fair value; for a skip, 0.
- Best available unit edge: the larger of fair value minus Ask, Bid minus fair value, and 0.
- Expected value captured: unit edge × size. Expected value available: best unit edge × the largest valid size.
- Whether the decision direction was correct: buy if fair value is above the Ask, sell if below the Bid, skip if between.
- Reported return and whether it matched (advanced mode only).

## 9. Session review (end of session only)

**Principle.** Nothing in the session tells the player whether a decision was good until the final round ends. No sounds, colours, banners, streaks or hints that imply right or wrong. The pause between rounds is short and identical regardless of outcome.

**Review screen contents**, in this order:

1. **Headline.** Final budget, total profit or loss, and expected value captured against expected value available, shown as a percentage.
2. **Skill versus luck.** Realised profit next to expected profit, with one plain sentence on the gap (for example, "You were 12 above your expected result; some of this was luck").
3. **Decision quality.** Direction accuracy (correct calls out of rounds), split into missed buys, missed sells, wrong-side trades and unnecessary trades.
4. **Speed.** Average decision time, and the number of timeouts.
5. **Return reporting** (advanced mode). Accuracy of the reported returns, and the first round where the player's mental budget diverged.
6. **Round-by-round table.** One row per round: cards as played, quote, true sum, fair value, the player's action and size, the correct action, profit. Tap a row to expand a step-by-step working: fair value derivation and edge.
7. **Actions.** Play again with the same settings, change settings, or return home.

**History.** Each completed session is saved with its settings and summary figures. A History screen lists past sessions and shows simple trends: accuracy, EV captured percentage and average decision time over the last sessions.

**Abandoned sessions.** If the player quits mid-session, they are asked to confirm, the session is discarded unless they choose to see a partial review, and nothing is shown mid-play.

## 10. Settings and difficulty presets

Every difficulty lever is a setting. A lobby screen offers three presets plus a Custom option that exposes all settings.

| Setting | Range | Default |
| --- | --- | --- |
| Number of cards | 2 to 8 | 3 |
| Hidden cards | 1 to number of cards | All hidden (at least one always) |
| Time per round (seconds) | 3 to 60 | 10 |
| Number of rounds | 3 to 50 | 10 |
| Starting budget | 100 to 10,000 | 500 |
| Market events | On or off | Off |
| Event frequency | 10 to 50 percent of rounds | 25 percent |
| Report return after each round | On or off | Off |
| Show running budget | On or off | On |
| Quote spread range | Min and max | 1 to 4 |
| Random seed | Optional number | Random |

| Preset | What changes |
| --- | --- |
| Easy | 3 cards, some face up, 20 seconds, no events, budget visible |
| Standard | 3 to 4 cards, 10 seconds, events on, budget visible |
| Hard | 4 to 6 cards, 6 seconds, events on, report return each round, budget hidden |

Settings persist between launches. The last used settings are the default for the next session. The lobby shows a one-line summary of the active setup, for example "3 cards, 10 rounds, 10 s, events off".

## 11. UX and UI requirements

**Feel.** Clean, calm and fast, in the spirit of the reference screenshots: a card row on top, the quote as the focal sentence, then order size and action buttons, with a progress bar acting as the timer. Generous spacing, one accent colour, very little text.

**Screens.**

1. **Lobby.** Title, preset picker, one-line setup summary, a large Start button, links to Settings, How to Play and History.
2. **Round.** Header with round counter ("Round 3 of 10") and budget chip (hidden on Hard). Card row. Event banner when active. The quote as "Bid at Ask" in large type. Order size chips (1, 5, 10, custom). Buy, Sell and Skip buttons. Timer bar.
3. **Reveal.** Cards flip face up and the sum is shown for a short, fixed time. In reporting mode, a numeric entry for the return replaces the pause.
4. **Review.** As specified in section 9.
5. **Settings, How to Play and History.** Simple lists and forms. How to Play carries the rules from this spec in plain language, including the card value chart (2 to 10, J = 11, Q = 12, K = 13, A = 14).

**Interaction requirements.**

- Layout must not shift during a round: the quote, chips and buttons stay put when a button is disabled, an event appears or the keyboard opens.
- Buy, Sell and Skip are at least 56 points tall and reachable with one thumb.
- Haptic feedback on button taps only, never indicating whether a choice was right.
- The timer is a smooth bar that turns to a warning colour in the last 25 percent of the time. The countdown must pause if the app is backgrounded, and the round restarts with a fresh quote on return (record in DECISIONS.md).
- Custom order entry uses a numeric keypad with the Max shortcut.
- Cards flip with a short animation, with a reduced-motion alternative.

**Theming and accessibility.**

- Light and dark themes following the system setting, with a manual override.
- Buy is green and Sell is red but each also has an icon and label, so colour is never the only signal.
- Dynamic Type supported on all text except the card faces; VoiceOver labels on cards, quote and buttons (for example, "Face-down card" and "Seven of hearts").
- Minimum contrast ratio of 4.5:1 for text in both themes.

**Tone of copy.** Short and neutral. No celebratory or scolding messages during play.

## 12. Technical constraints and architecture

**Environment.**

- Developer machine: Windows with WSL2 (Ubuntu). No Mac, no Xcode project, no Simulator.
- Build and deploy: [xtool](https://github.com/xtool-org/xtool), which builds a SwiftPM package into an iOS app and installs it over USB. Free Apple ID signing, so the install expires after 7 days and must be reinstalled.
- Target: iPhone on iOS 18, with Developer Mode enabled.
- Language and UI: Swift and SwiftUI only. No third-party dependencies without approval.

**Package layout** (the pure-logic target must build and test on Linux):

```text
MarketTakingTrainer/
  Package.swift
  xtool.yml                 (xtool config, if `xtool new` generates one)
  CLAUDE.md                 (hard constraints for the agent)
  SPEC.md                   (this document)
  DECISIONS.md              (assumptions and choices)
  Sources/
    GameCore/               (pure Swift, no UI imports)
      Cards/                (Card, Suit, Deck, CardPool)
      Events/               (MarketEvent protocol and each event)
      Quotes/               (QuoteProvider protocol, RandomQuoteProvider)
      Pricing/              (FairValue, MaxSum, exact EV by enumeration)
      Orders/               (Order, validation, settlement)
      Session/              (Settings, Round, Session state machine)
      Review/               (Metrics, SessionReview)
      Storage/              (storage protocol, Codable models)
    TrainerApp/             (SwiftUI app target)
      Screens/              (Lobby, Round, Reveal, Review, Settings, History)
      Components/           (CardView, QuoteView, TimerBar, OrderControls)
      Theme/
  Tests/
    GameCoreTests/
```

**Architectural rules.**

- `GameCore` has no dependency on SwiftUI, UIKit or Foundation features missing on Linux. All randomness and time come in through injected interfaces (a seeded random generator and a clock).
- The UI observes a session object and sends it intents (select size, buy, sell, skip, submit return). The UI holds no game rules.
- Round and session phases are explicit enum states with validated transitions.
- Fair value and max possible sum are computed by exact enumeration over the remaining eligible cards. With at most 8 cards from 52 this must stay fast; cache or prune if needed, and never block the main thread.
- Persistence of settings and history sits behind a storage protocol, implemented with JSON files in the app's documents directory.
- Version the stored data so future changes can migrate it.

**Known risks for the agent to flag, not hide.**

- xtool is a community tool; some SwiftUI or entitlement features may behave differently from an Xcode build.
- No simulator means UI regressions are only visible on the phone. Keep views small and state-driven.
- WSL USB passthrough (usbipd) can drop; give a recovery checklist.

## 13. Testing and acceptance criteria

**Unit tests in `GameCore`** (run with `swift test` in WSL):

- Card pool: correct values and suits, no duplicate cards in a round, event filters produce the right pools.
- Fair value: matches hand-computed cases, such as one visible 10 with two hidden cards giving 26 with no event, and three hidden cards under "only 10 or more" giving 36.
- Max possible sum: respects face-up cards, events and fixed-value overrides.
- Order validation: boundary cases at exactly the budget, one over, size 0 and negative, and a sell where the max loss equals the budget.
- Settlement: buy, sell and skip arithmetic, and the budget never going below zero across 1,000 randomised seeded sessions.
- Quote engine: any provider output is repaired into a valid quote; `FixedQuoteProvider` scripts a session deterministically.
- State machine: illegal transitions are rejected, a timeout becomes a skip, and no review data is exposed before the final round.
- Review: metrics from a scripted session match hand-calculated values.
- Determinism: the same seed and the same inputs always produce the same session.

**Acceptance criteria for v1.**

1. A full session of default settings plays start to finish on the iPhone with no crash.
2. At no point before the review does the UI show whether a decision was right or wrong.
3. An invalid order is never accepted, and the player always sees why it is blocked.
4. Fair value shown in the review matches the independent test calculation for every round.
5. Swapping `RandomQuoteProvider` for `FixedQuoteProvider` requires changing one line of wiring and nothing in game flow code.
6. Adding a new market event requires adding one type and registering it, with no change to round or session code.
7. Light and dark themes both pass a manual contrast and layout check on the phone.
8. The README lets a fresh WSL setup build and install the app using documented xtool commands.

## 14. Phased roadmap and out of scope

Each phase ends with a gate: the agent runs tests, summarises the state, gives exact on-device instructions, and waits for approval.

1. **Phase 0: Environment proof.** Create `CLAUDE.md`, `DECISIONS.md` and a README with the xtool setup steps. Generate a hello-world app with xtool, and install it on the iPhone. *Gate: the app launches on the phone.*
2. **Phase 1: Core logic.** Cards, deck, fair value, max sum, order validation and settlement, with unit tests. No UI. *Gate: all tests pass and the maths is reviewed.*
3. **Phase 2: Quotes, events and session engine.** `QuoteProvider` with `RandomQuoteProvider` and `FixedQuoteProvider`, the `MarketEvent` protocol with all seven events, and the session state machine. *Gate: a scripted full session passes in tests.*
4. **Phase 3: Playable round on device.** Round screen, card views, quote, order controls, timer bar, reveal. Fixed default settings. *Gate: a full session plays on the iPhone.*
5. **Phase 4: Review and history.** Metrics capture, the review screen, saved history. *Gate: the review matches the independent calculation for every round.*
6. **Phase 5: Lobby, settings and presets.** All settings, three presets, return reporting and the hidden-budget mode. *Gate: each preset plays correctly.*
7. **Phase 6: Polish.** Themes, animations, haptics, accessibility, How to Play, app icon. *Gate: acceptance criteria 1 to 8 are all met.*

**Out of scope for v1.**

- Accounts, online leaderboards, multiplayer.
- App Store or TestFlight release (a paid developer account is needed).
- Additional quote strategies beyond `RandomQuoteProvider` (the design must allow them).
- Sound effects and music.
- iPad-specific layouts and landscape orientation.

**Open questions for the product owner.**

- Should the default session be 10 rounds, as drafted here, or the reference site's 4?
- On Easy and Standard, should the quietly updating budget be shown at all, given that it implies profit and loss? The current draft says yes.
- Should a timeout apply any penalty, or stay equal to a skip as drafted?
- Should quote difficulty vary with the preset, or stay the same until a smarter provider exists?
