# Market Taking Trainer: agent notes

The product spec is `SPEC.md`. Assumptions and choices are in `DECISIONS.md`; add to it whenever you decide something the spec doesn't.

## Hard constraints

- **No Mac.** The developer works on Windows + WSL2 (Ubuntu). The app is a SwiftPM package built and installed with [xtool](https://github.com/xtool-org/xtool) onto a physical iPhone (iOS 18) with a free Apple ID. There is no Xcode project, no Simulator, no SwiftUI previews, no debugger.
- **All rules live in `GameCore`.** It is pure Swift with no SwiftUI/UIKit imports, and must build and pass `swift test` on Linux. `TrainerApp` is a thin SwiftUI layer that observes state and sends intents; it holds no game rules.
- **`TrainerApp` sources are wrapped in `#if canImport(SwiftUI)`** so `swift test` on Linux can build the whole package.
- **No third-party dependencies** without the developer's approval.
- **Quotes come only from a `QuoteProvider`**, and the game validates/repairs whatever it returns. No strategy logic in round or session code.
- **No per-round feedback.** Nothing during a session may signal whether a decision was right or wrong: no colours, sounds, banners, streaks or hints. Review happens only after the final round.
- **Randomness and time are injected.** Use `SeededGenerator` / `RandomDraws`; never call global `random` or read the wall clock inside `GameCore`.
- Clean, simple UI with light and dark themes.

## Working style

- Work in the phases of SPEC.md section 14. At each gate: run the tests, summarise, give exact xtool steps, and stop for feedback.
- Write tests alongside logic; every rule in SPEC sections 5–8 maps to at least one test.
- Small files named by responsibility.
- Say plainly whether something was verified (tests ran, build succeeded) or is only expected to work on the device.

## Commands

```bash
swift test                # GameCore tests (Linux)
scripts/check.sh          # same
scripts/check.sh --dev    # tests, then xtool dev (build + install on phone)
```

Swift Testing quirk: inside `#expect`, compare a `Rational` against `Rational(...)`, not a compound literal like `10 + 16` (the macro types it as `Int`).
