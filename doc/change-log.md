# NotEnoughResins Change Log

## 2026-03-12

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
