# NotEnoughResins Change Log

## 2026-03-12

- Fixed the launch configuration for the menu bar app by enabling
  `LSUIElement` in the generated app Info.plist so the built app registers as a
  menu bar agent instead of a window-first app with no visible launch surface.
- Replaced the legacy `showSettingsWindow:` selector path with SwiftUI's
  supported `openSettings` action so Preferences opens through the Settings
  scene from the menu bar panel.

## 2026-03-11

- Created the initial SDD document set from `temp-spec.md`.
- Split mixed draft content into requirements, design, and validation artifacts.
- Replaced manual `server` and `role_id` input with startup account discovery
  from `account_id_v2` via the game record card endpoint.
- Recorded that the game record card request runs on startup only, while the
  10-minute loop applies to Daily Note polling only.
- Recorded unresolved items instead of leaving them implicit.
- Added the initial numbered implementation task set under `doc/task/`.
- Confirmed by live API investigation that the current HoYoLAB contract works
  with the tested minimal shared header set `Cookie`.
- Confirmed that the startup discovery mapping is `region -> server` and
  `game_role_id -> role_id` for the selected `game_id == 2` entry.
- Confirmed that both endpoints return HTTP `200` for success, auth failure,
  and parameter failure, so implementation must classify by `retcode` and
  `message`.
- Recorded sanitized Task 01 contract evidence for later implementation and
  validation work.
- Added a Keychain-backed `PreferencesStore` for the HoYoLAB cookie and
  surfaced `needsConfiguration` versus `configurationReady` state to the app UI.
- Added a dedicated Preferences surface through the macOS Settings scene and a
  minimal app view that can open it.
- Added unit tests for preferences loading, empty-cookie rejection, and trimmed
  cookie persistence.
- Added `AccountResolver`, `DailyNoteService`, and `RefreshCoordinator` to run
  startup discovery once and poll Daily Note after the first successful
  resolution.
- Wired the main app window to surface refresh progress, resolved account
  details, latest Daily Note data, and current request errors for development
  validation.
- Added unit tests for cookie parsing, game-card selection, auth-error
  classification, and the no-repeat startup discovery flow.
- Added `SnapshotStore` and `ResinTracker` to persist the latest Daily Note
  snapshot, restore overflow timing across launches, and derive resin or waste
  locally between successful fetches.
- Wrapped cached snapshot persistence in a versioned storage envelope with
  legacy decode fallback so future schema changes remain manageable.
- Expanded resin tracking validation coverage for derived max-resin clamping,
  relaunch-based overflow continuation, and deterministic refresh-loop tests.
- Replaced the window-first shell with a `MenuBarExtra` entry point and a
  compact main panel that keeps Preferences and Quit actions inside the menu
  bar experience.
- Added `AppState` so configuration, refresh, snapshot, and resin-tracking
  signals map to dedicated menu bar states for setup-needed, loading, normal,
  overflow, authentication failure, and request failure.
- Recorded that the new menu bar UX currently builds cleanly, while automated
  `xcodebuild test` execution is still stalling in the current CLI session and
  remains an explicit follow-up for Task 06 validation closure.
- Added state-driven `AppState` tests for setup-needed, normal, overflow, and
  error presentations, plus a successful Daily Note decode test.
- Removed the default UI launch stubs because they did not cover version 1
  acceptance criteria and replaced them with deterministic validation around
  the actual menu bar state mapping.
- Recorded the current local validation path as `build-for-testing` plus direct
  `xctest` execution for the unit bundle when `xcodebuild test` orchestration
  does not launch the runner reliably in the CLI environment.
