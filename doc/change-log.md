# NotEnoughResins Change Log

## 2026-03-15

### Task 10 - Drive AppPresentation with local minute updates

- Added a minute-driven presentation refresh path in `AppState` so the menu
  bar and main panel keep deriving resin state locally between the existing
  10-minute Daily Note refreshes instead of staying visually frozen.
- Rebased the below-cap hero countdown on the shared local recovery baseline
  from `predictedFullAt`, while keeping `lastRefreshText` tied to the last
  successful API fetch time rather than the minute tick.
- Updated debug UI scenarios and automated coverage so minute ticks advance the
  displayed countdown and resin value without triggering extra network refresh,
  and fixed the saved-cookie startup path so the initial `storedCookie` replay
  no longer starts a duplicate refresh loop.

### Planning - AppPresentation local minute updates

- Added `doc/task/task_10.md` to scope a follow-up task that keeps
  `AppPresentation` updating from local elapsed time between the existing
  10-minute Daily Note refreshes.
- Captured the clarified constraint that API refresh remains on the current
  10-minute cadence, while the menu bar and main-panel resin display should
  keep moving during the other minutes from local state.

### Task 09 - Refine AppPresentation recovery detail and routine metric copy

- Updated the resin hero so below-cap states show the remaining full-recovery
  countdown from `resin_recovery_time` directly under the current `resin / max`
  value, while overflow states continue to show waste instead of the countdown.
- Renamed the compact summary metrics to `Weekly Bosses`,
  `Daily Commissions`, `Bonus Reward`, and `Realm Currency`, and changed daily
  commissions to show `{remaining} left`.
- Extended unit and UI coverage so the new hero detail line, renamed metrics,
  and overflow-only countdown suppression all stay verified together.

### Planning - AppPresentation copy and refill countdown

- Added `doc/task/task_09.md` to scope a follow-up AppPresentation task that
  shows time until full resin recovery below the resin total when the account
  is below cap.
- Captured the approved terminology changes for the compact metrics block so
  `Discount Runs`, `Daily Tasks`, and `Home Coin` are replaced by
  `Weekly Bosses`, `Daily Commissions`, and `Realm Currency`.

## 2026-03-13

### One-shot - Keep Daily Note state in memory only

- Removed snapshot save and restore behavior from `RefreshCoordinator` so Daily
  Note snapshots and resin tracking state are no longer persisted across app
  launches.
- Kept configuration persistence unchanged, and updated startup behavior so
  each app session derives overflow state only from data observed while the app
  is running.

### One-shot - Remove debug overflow-start override

- Removed the temporary DEBUG-only overflow-start override from
  `ResinTracker`.
- Local and automated runs now follow the same prediction-based overflow
  baseline derivation path, so development behavior matches the documented
  tracking rules again.

### One-shot - Add footer refresh button

- Added an icon-only refresh button to the main-panel footer between
  Preferences and Quit.
- Routed the footer action through `AppState` and `RefreshCoordinator` so a
  manual refresh triggers an immediate Daily Note fetch without waiting for the
  next scheduled poll when the current account is already resolved.
- Extended automated coverage for the new footer control and the immediate
  refresh path, including safe cancellation of the test clock's pending sleep.

### Task 08 - Redesign AppPresentation and panel sections

- Replaced the flat `AppPresentation.fields` list with a semantic panel model
  built around a resin hero, an ordered summary-metrics block, and an optional
  expedition section.
- Extended Daily Note decoding and cached snapshot storage so expedition items
  preserve per-character status and remaining time instead of collapsing to
  counts only.
- Rebuilt `ContentView` around the approved compact layout, keeping account
  context in the header, overflow waste as a separate highlight, and
  expedition rows visible as `Expeditions n/n`.
- Updated presentation and UI coverage so the redesigned panel, expedition
  detail rendering, and real menu bar panel opening continue to pass together.

### Planning - AppPresentation redesign

- Added `doc/app-presentation-redesign.md` to define the follow-up redesign of
  `AppPresentation` away from a flat field list and toward a semantic panel
  model with hero, account, and grouped section content.
- Added `doc/task/task_08.md` to scope the implementation work for the new
  presentation model, view updates, and semantic test coverage.
- Refined the redesign plan so expedition data is preserved per character and
  the panel can show one expedition row per character with remaining time or a
  completed state.
- Further refined the panel layout toward a compact markdown-like structure:
  header account context, resin hero, one ordered metrics block, and an
  `Expeditions n/n` list.

## 2026-03-12

### One-shot - Pin debug overflow start to yesterday

- Added a DEBUG-only overflow-start override in `ResinTracker` so local app
  launches treat capped resin as if overflow started at `15:00` yesterday,
  making overflow and waste UI easier to inspect during development.
- Kept the shipped prediction-based overflow-start logic unchanged for tests
  and non-DEBUG builds so automated coverage and release behavior still follow
  the documented tracking rules.

### Task 01 - Confirm HoYoLAB contract and test fixtures

- Updated `doc/task/task_01_evidence.md` with the latest live verification
  date.
- Recorded executed Task 01 validation evidence in `doc/validation.md`.
- Confirmed that the current live HoYoLAB contract still matches
  `doc/spec.md` and `doc/design.md`, so no upstream artifact deltas were
  required before implementation.

### Task 02 - Add secure configuration and preferences editing

- Added a Keychain-backed `PreferencesStore` and `KeychainStore` wrapper for
  secure HoYoLAB cookie persistence.
- Added a dedicated Preferences UI plus launch-time configuration status
  wiring in the app shell.
- Added unit and UI coverage for empty-cookie rejection, save/restore
  behavior, and relaunch persistence, then recorded the executed verification
  in `doc/validation.md`.

### Task 03 - Implement startup discovery and Daily Note refresh

- Added `AccountResolver`, `DailyNoteService`, HoYoLAB models, and
  `RefreshCoordinator` to resolve the configured account once and poll Daily
  Note on the required schedule.
- Added `AppState` so the current shell reflects configuration, discovery,
  refresh, ready, auth-error, and request-error phases.
- Added automated coverage for cookie parsing, account-card selection, Daily
  Note decoding, error classification, and the one-time discovery plus
  steady-state polling behavior, then recorded the executed verification in
  `doc/validation.md`.

### Task 04 - Persist snapshots and derive resin waste

- Added a `SnapshotStore` backed by `UserDefaults` plus account-aware restore
  logic so the latest successful Daily Note snapshot and tracking markers
  survive relaunch without leaking across account changes.
- Added `ResinTracker` to derive `predictedFullAt`, known overflow timing, and
  estimated wasted resin while refusing to fabricate missing overflow history.
- Wired tracking state into `RefreshCoordinator`, `AppState`, and the current
  shell so restored or freshly fetched snapshots now expose derived resin and
  waste values.
- Added automated coverage for snapshot persistence, relaunch restore, derived
  resin progression, and overflow waste calculation, then recorded the executed
  verification in `doc/validation.md`.

### Task 05 - Deliver the menu bar and main panel UX

- Replaced the default window-first app entry with a `MenuBarExtra` shell and
  added compact menu bar label rendering for setup-needed, loading, normal,
  overflow, auth-error, and request-error states.
- Added `AppPresentation` mapping so the menu bar label and main panel derive
  their user-facing copy, symbols, and Daily Note summary fields from shared
  application state instead of embedding UI logic directly in the views.
- Rebuilt the main panel as a compact Daily Note summary with last successful
  refresh time plus Preferences and Quit actions, and added a debug UI-test
  host for deterministic state-driven verification.
- Extended automated coverage for menu bar and panel presentation states,
  including real menu bar status-item click smoke tests, then recorded the
  executed verification in `doc/validation.md`.
- Followed up on the shipped panel layout so the footer actions stay visible in
  the live menu bar panel, and strengthened the real menu bar smoke tests to
  assert that Preferences and Quit remain hittable after opening the panel.

### Task 06 - Close validation and documentation gaps

- Re-ran the full `xcodebuild test` suite on the integrated branch and
  confirmed the existing automated coverage already closes the planned task06
  gaps for parsing, account selection, decoding, restore, tracking, and UI
  presentation states.
- Ran repository-standard Markdown lint across `doc/**/*.md` and confirmed the
  current SDD artifacts remain consistent and lint-clean.
- Updated `doc/validation.md` to record the executed task06 verification sweep,
  the documentation check, and the remaining manual-only residual gaps.

### Post-Implementation Artifact Review

- Re-checked the implemented version 1 app against `doc/spec.md` and
  `doc/design.md` after the full task02-task06 delivery had landed.
- Recorded the resulting documentation drift in `doc/validation.md`, including
  stale pre-implementation baseline language and outdated unresolved-item text.
- Added `doc/task/task_07.md` to refresh the requirements and design artifacts
  so future work starts from the shipped brownfield baseline instead of the
  original scaffold-era descriptions.
