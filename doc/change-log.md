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
