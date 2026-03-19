# Task 10 - Drive AppPresentation with local minute updates between Daily Note refreshes

## Priority

P1

## Goal

Keep `AppPresentation` moving between the fixed 10-minute Daily Note refreshes
by updating the displayed resin-related values from elapsed local time at least
once per minute, so the menu bar and main panel do not stay visually frozen for
most of each polling interval.

## Scope

- Add a minute-driven local update path for `AppPresentation` that is separate
  from the existing 10-minute Daily Note polling loop.
- Update the `AppState` to republish presentation changes from elapsed local
  time while the app is running, so both the menu bar label and the main panel
  react without waiting for the next API response.
- Change the below-cap hero detail countdown so it is derived from the same
  local baseline as the derived resin value instead of staying fixed to the
  last fetched `resinRecoveryTimeSeconds`.
- Preserve the current ready, auth-error, request-error, and overflow panel
  behavior unless a small presentation-state adjustment is required to keep the
  locally derived values coherent.
- Add automated coverage for minute-driven presentation changes and the
  guarantee that local UI updates do not trigger extra network refreshes.

## Acceptance Criteria

- After a successful below-cap Daily Note fetch, the visible
  `AppPresentation` updates locally at least once per minute without waiting
  for another API response.
- The below-cap hero detail countdown decreases with elapsed time between
  fetches instead of remaining fixed for the whole 10-minute polling interval.
- When the elapsed time crosses an 8-minute recovery boundary, the displayed
  resin value advances locally without exceeding `maxResin`.
- The fixed 10-minute Daily Note polling cadence remains unchanged, and the
  local presentation updates do not initiate account discovery or Daily Note
  requests.
- `lastRefreshText` continues to reflect the last successful API fetch time
  rather than the local minute tick time.
- If overflow timing is known, the locally displayed overflow waste can keep
  advancing between fetches from the same baseline that drives the menu bar
  overflow state.
- If the app does not have enough baseline data to derive current resin or a
  reliable countdown, it does not fabricate minute-by-minute values.

## Out of Scope

- Changing the 10-minute polling interval or turning Daily Note fetches into a
  1-minute network schedule.
- Reworking the current AppPresentation copy, metric labels, or panel layout
  beyond what is needed for the local update behavior.
- Changing account resolution behavior or manual refresh UX.

## Implementation Notes

- Treat the 2026-03-15 clarification as authoritative: API refresh still runs
  every 10 minutes; only the other minutes should be covered by local display
  updates.
- Prefer one shared minute-tick source at the app-state or presentation layer
  so the menu bar label and main panel stay synchronized.
- Reuse the existing resin derivation baseline where possible instead of
  introducing a second countdown source just for the panel hero detail.
- Derive the below-cap countdown from `predictedFullAt` or an equivalent local
  baseline instead of formatting the raw fetched `resinRecoveryTimeSeconds`
  unchanged until the next API response.
- Keep redraw frequency intentionally low; the task only needs minute-level UI
  freshness, not per-second animation.

## Verification

- `xcodebuild test -scheme NotEnoughResins -destination 'platform=macOS' CODE_SIGNING_ALLOWED=NO CODE_SIGN_IDENTITY=-`
- Manual: keep the app open after a below-cap fetch and confirm the menu bar
  resin status and main-panel recovery detail update on later minute boundaries
  without changing the recorded last successful refresh time.
- Manual: confirm overflow waste still advances locally when the overflow
  baseline is known, and that no extra fetch is triggered before the next
  scheduled 10-minute refresh.
- `markdownlint-cli2 "doc/**/*.md" --config ~/.markdownlint-cli2.jsonc`

## References

- `doc/spec.md` FR-4
- `doc/spec.md` FR-9
- `doc/spec.md` NFR-4
- `doc/design.md` RefreshCoordinator
- `doc/design.md` ResinTracker
- `doc/design.md` API Integration Flow / Derived Display Between Fetches
- `doc/task/task_09.md`
- User request on 2026-03-15: "api refreshもするけどそっちは10分に1回だから他の9分はローカルで更新"
