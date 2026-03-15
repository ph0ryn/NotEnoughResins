# Task 09 - Refine AppPresentation recovery detail and routine metric copy

## Priority

P1

## Goal

Refine the main-panel `AppPresentation` so below-cap resin states show the
remaining time until full recovery directly under the resin total, and the
compact routine metrics use the approved in-game terminology for commissions,
weekly bosses, and realm currency.

## Scope

- Extend the typed panel presentation model and panel rendering so the resin
  hero can show a secondary recovery-time line when current resin is below max
  and overflow is not being displayed.
- Update `AppPresentationBuilder` so the compact metrics block maps:
  - the existing resin-discount counter to `Weekly Bosses`
  - daily task progress to `Daily Commissions` with a `{remaining} left` value
  - home coin to `Realm Currency`
- Keep `Bonus Reward` in the compact metrics block and preserve the existing
  section order unless a small presentation-only adjustment is needed to keep
  the block coherent.
- Update presentation and UI coverage so the renamed metrics and the
  conditional recovery-detail line are asserted.

## Acceptance Criteria

- When `currentResin < maxResin` and the panel has enough data to estimate the
  refill state, the resin hero shows `{current} / {max}` with a secondary line
  directly beneath it that communicates the remaining time until full recovery.
- When overflow waste is being shown, the panel does not render the below-cap
  recovery countdown and continues to show the waste highlight instead.
- The summary metrics labels read `Weekly Bosses`, `Daily Commissions`,
  `Bonus Reward`, and `Realm Currency` in the existing compact order.
- `Daily Commissions` shows `{remaining} left`, where
  `remaining = totalTaskCount - finishedTaskCount`.
- `Weekly Bosses` and `Realm Currency` keep the current backing data and
  numeric formatting unless the implementation needs a small presentation-only
  adjustment to keep the compact block consistent.
- Automated tests cover the renamed metric labels or identifiers and the
  conditional hero detail line.

## Out of Scope

- Reordering sections beyond the existing compact metrics block.
- Changing menu bar label copy or menu bar overflow behavior.
- Reworking expedition presentation or bonus reward semantics.

## Implementation Notes

- Treat the 2026-03-15 user request as the approved copy delta that supersedes
  the older `Discount Runs`, `Daily Tasks`, and `Home Coin` labels in
  `doc/app-presentation-redesign.md` for this task's scope.
- Prefer deriving the recovery countdown from the same baseline that drives
  locally derived resin values so the hero detail stays aligned between fetches.
- If the current `AppPresentation.Hero` model cannot express an optional
  secondary detail line cleanly, extend the typed hero model instead of
  formatting that subtitle directly inside `ContentView`.
- Keep the derived daily-commission remaining count non-negative even if a
  future payload becomes inconsistent.

## Verification

- `xcodebuild test -scheme NotEnoughResins -destination 'platform=macOS' CODE_SIGNING_ALLOWED=NO CODE_SIGN_IDENTITY=-`
- Manual: verify that a below-cap panel shows the refill countdown and updated
  metric labels, and that an overflow panel hides the countdown while still
  showing waste.
- `markdownlint-cli2 "doc/**/*.md" --config ~/.markdownlint-cli2.jsonc`

## References

- `doc/spec.md` FR-9
- `doc/design.md` UI Design / Main Panel
- `doc/design.md` Data Model / Raw API Models
- `doc/app-presentation-redesign.md` SummaryMetrics
- User request on 2026-03-15: "AppPresentation表示の変更"
