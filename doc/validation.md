# NotEnoughResins Validation

## Document Status

- Status: Executed with residual gaps
- Last updated: 2026-03-12
- Related requirements: `doc/spec.md`
- Related design: `doc/design.md`

## Validation Targets

- Account configuration and persistence.
- Startup account discovery.
- Scheduled fetch behavior.
- Menu bar state transitions.
- Resin overflow and waste calculation.
- Main panel access and actions.

## Planned Checks

### Live API Investigation

- Before implementation, execute live requests against both HoYoLAB endpoints
  using the cookie from `.env`.
- Confirm that `account_id_v2` can be extracted from the cookie.
- Confirm the response shape of `getGameRecordCard`.
- Confirm which fields in the `game_id = 2` entry map to Daily Note `server`
  and `role_id`.
- Capture representative failure responses and `retcode` values with secrets
  redacted.

## Executed Checks

### 2026-03-12 - Task 01 live API investigation

- Input source: `HOYOLAB_COOKIE` from the local environment
- Method: read-only requests against the approved HoYoLAB endpoints with
  redacted evidence recorded in `doc/task/task_01_evidence.md`
- Result: passed

Observed outcomes:

- `account_id_v2` was extractable from the cookie and usable as the
  `getGameRecordCard` `uid` query parameter.
- The selected `game_id == 2` entry still mapped `region -> server` and
  `game_role_id -> role_id`.
- Both endpoints returned HTTP `200` for success, auth failure, and
  parameter failure, so app logic must classify failures from `retcode` and
  `message`.
- The observed auth failure signature remained `retcode = 10001` and
  `message = "Please login"`.
- The observed generic failure signatures remained `retcode = -1` with
  parameter-specific messages including `Invalid uid` and
  `param role_id error: value must be greater than 0`.

### 2026-03-12 - Documentation consistency check

- Compared the live investigation results with `doc/spec.md` and
  `doc/design.md`
- Result: passed
- No requirement or design deltas were needed before downstream implementation
  started.

### 2026-03-12 - Task 02 configuration and preferences verification

- Command:
  `xcodebuild test -scheme NotEnoughResins -destination 'platform=macOS' CODE_SIGNING_ALLOWED=NO CODE_SIGN_IDENTITY=-`
- Result: passed

Executed coverage:

- Unit tests covered stored-cookie restore, empty-cookie rejection, successful
  save normalization, and load failure fallback for `PreferencesStore`.
- UI tests exercised opening Preferences, saving a cookie, and relaunching the
  app with an isolated Keychain service suffix to confirm the saved cookie was
  still available after restart.
- Code inspection confirmed the task-02 implementation writes the cookie only
  through `KeychainStore` and does not persist it in `UserDefaults`.

### 2026-03-12 - Task 03 discovery and refresh verification

- Command:
  `xcodebuild test -scheme NotEnoughResins -destination 'platform=macOS' CODE_SIGNING_ALLOWED=NO CODE_SIGN_IDENTITY=-`
- Result: passed

Executed coverage:

- `AccountResolverTests` covered `account_id_v2` extraction, request
  construction, `game_id == 2` selection, auth failure, and generic request
  failure classification.
- `DailyNoteServiceTests` covered Daily Note request construction, snapshot
  decoding, auth failure, and generic request failure classification.
- `RefreshCoordinatorTests` covered startup discovery occurring once before the
  initial Daily Note fetch, immediate first refresh, repeated Daily Note polling
  without repeating the game record card request, and auth failure stopping the
  polling loop.
- The current app shell now reflects discovery, refresh, ready, auth-error, and
  request-error phases from the shared state layer for local verification.

### 2026-03-12 - Task 04 snapshot persistence and resin tracking verification

- Command:
  `xcodebuild test -scheme NotEnoughResins -destination 'platform=macOS' CODE_SIGNING_ALLOWED=NO CODE_SIGN_IDENTITY=-`
- Result: passed

Executed coverage:

- `SnapshotStoreTests` covered persisting and restoring the latest successful
  Daily Note snapshot plus resin tracking markers, and rejecting corrupt cached
  data.
- `ResinTrackerTests` covered below-cap `predictedFullAt` updates, capped-state
  overflow baseline derivation, refusing to invent waste without a reliable
  baseline, derived resin capping, and continued waste growth from persisted
  overflow timing after relaunch.
- `RefreshCoordinatorTests` covered restoring a cached snapshot and tracking
  state before the first refresh when the saved cookie matches the cached
  account, ignoring cached state for a different account, and persisting each
  successful refresh back to the snapshot store.
- The current shell now renders derived resin and estimated waste from the
  shared tracking state instead of showing only the last raw server snapshot.

### 2026-03-12 - Task 05 menu bar and main panel verification

- Command:
  `xcodebuild test -scheme NotEnoughResins -destination 'platform=macOS' CODE_SIGNING_ALLOWED=NO CODE_SIGN_IDENTITY=-`
- Result: passed

Executed coverage:

- `AppPresentationTests` covered setup-needed, normal, overflow, auth-error,
  and request-error presentation mapping from shared app state, including the
  expected Daily Note summary fields for ready and failure presentations.
- `NotEnoughResinsUITests` exercised deterministic setup-needed, normal,
  overflow, auth-error, and request-error UI scenarios through a debug host
  window that renders the same menu bar label view and main panel content used
  by the `MenuBarExtra`.
- `NotEnoughResinsUITests` also exercised the real macOS menu bar status item
  itself, confirming that clicking the setup-needed and overflow states opens
  the expected panel content and keeps the Preferences and Quit footer actions
  hittable.
- The state-driven UI checks verified compact menu bar label rendering, the
  top-level panel state titles for each scenario, and the setup-needed panel's
  Preferences and Quit actions without requiring a standard launch window.
- The existing preferences relaunch UI test still passed with isolated Keychain
  and `UserDefaults` suffixes by clicking the panel's Preferences action, so
  the task05 menu bar work did not regress the stored-cookie flow.

### 2026-03-12 - Task 06 release validation sweep

- Command:
  `xcodebuild test -scheme NotEnoughResins -destination 'platform=macOS' CODE_SIGNING_ALLOWED=NO CODE_SIGN_IDENTITY=-`
- Result: passed

Executed coverage:

- Re-ran the full unit and UI suite on the integrated branch and confirmed the
  cumulative task02-task05 coverage still passes together.
- Verified automated coverage exists for cookie parsing, game-card account
  selection, Daily Note decoding, scheduled refresh behavior, resin tracking,
  snapshot persistence restore, and menu bar or panel presentation states.
- Confirmed the persistence restore path still passes through the relaunch UI
  test and the restore-before-refresh coordinator test in the same suite run.

### 2026-03-12 - Task 06 documentation verification

- Command:
  `markdownlint-cli2 "doc/**/*.md" --config ~/.markdownlint-cli2.jsonc`
- Result: passed

Executed coverage:

- Confirmed the spec, design, task, validation, and change-log documents pass
  the repository-standard Markdown lint configuration.
- Recorded the task06 validation closure after confirming no additional
  product-code changes were required to satisfy the planned coverage.

### 2026-03-12 - Requirements and implementation consistency review

- Compared the current version 1 implementation and automated coverage with
  `doc/spec.md` and `doc/design.md`
- Result: follow-up required

Observed artifact drift:

- `doc/spec.md` still marks the requirements artifact as draft and still says
  the repository only contains the default SwiftUI scaffold, even though the
  menu bar app, networking, persistence, tracking, and tests now exist.
- `doc/design.md` still marks the design artifact as draft and still describes
  the project as the pre-implementation window-first template, so its baseline
  no longer matches the brownfield codebase.
- `doc/spec.md` still lists the main-panel field set and the configuration or
  authentication copy and iconography as unresolved, even though version 1 now
  ships concrete choices and automated presentation coverage for them.
- Added `doc/task/task_07.md` to refresh the SDD artifacts so the
  requirements-design-validation chain reflects the implemented version 1
  baseline and any real remaining follow-up.

## Requirement Coverage

- FR-1, FR-2, FR-10: preferences and persistence checks.
- FR-3, FR-4, FR-5, FR-11: startup discovery, scheduled fetch, and error state
  checks.
- FR-6, FR-7, FR-8, FR-9: menu bar and main panel checks.
- FR-12: resin tracking and snapshot persistence restore checks.

## Residual Gaps

- A separate manual walkthrough for the task04 relaunch boundary scenario was
  not executed after the automated coverage landed.
- A separate manual visual walkthrough of the live macOS menu bar extra after
  the footer layout adjustment was not recorded yet; automated coverage now
  clicks the real status item and inspects the panel through the system UI
  accessibility tree, but it does not replace a human visual pass.
- No CI status was checked because the repository does not yet expose remote CI
  to this workflow.
