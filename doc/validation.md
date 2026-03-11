# NotEnoughResins Validation Plan

## Document Status

- Status: Partially Executed
- Last updated: 2026-03-11
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

### 2026-03-11 Task 01 Live API Investigation

- Executed read-only live requests against the two approved HoYoLAB URLs using
  `HOYOLAB_COOKIE` from `.env`, with all secrets redacted from repository
  artifacts.
- Confirmed that `account_id_v2` can be extracted from the cookie and passed as
  the game record card `uid` query parameter.
- Confirmed that the Genshin entry is selected with `game_id == 2` and maps
  `region -> server` and `game_role_id -> role_id` for the Daily Note request.
- Confirmed that both endpoints succeeded with the tested minimal shared header
  set `Cookie`.
- Confirmed that both endpoints returned the same top-level response envelope:
  `retcode`, `message`, and `data`.
- Confirmed that success, auth failure, and parameter failure all returned HTTP
  `200`, so status classification must use `retcode` and `message`.
- Confirmed the auth failure signature `retcode = 10001`,
  `message = "Please login"` on both endpoints.
- Confirmed the generic request failure signature `retcode = -1` with
  parameter-specific messages on both endpoints.
- Recorded sanitized payload examples and contract notes in
  `doc/task/task_01_evidence.md`.

### 2026-03-11 Task 02 Preferences and Persistence

- Executed `xcodebuild clean -scheme NotEnoughResins`.
- Executed
  `xcodebuild test -scheme NotEnoughResins -destination 'platform=macOS' -only-testing:NotEnoughResinsTests CODE_SIGNING_ALLOWED=NO CODE_SIGN_IDENTITY=-`.
- Confirmed `PreferencesStore` coverage for:
  - loading an existing stored cookie on initialization
  - rejecting an empty cookie draft
  - trimming and persisting a non-empty cookie
- Confirmed the app now exposes a dedicated Settings scene backed by a
  Keychain store and a configuration state split between
  `needsConfiguration` and `configurationReady`.
- Attempted the repository-standard full scheme command with ad-hoc signing
  overrides. The build completed, but the UI test runner did not finish in the
  current CLI session, so automated UI coverage remains pending.

### 2026-03-11 Task 03 Startup Discovery and Refresh

- Executed
  `xcodebuild test -scheme NotEnoughResins -destination 'platform=macOS' -only-testing:NotEnoughResinsTests CODE_SIGNING_ALLOWED=NO CODE_SIGN_IDENTITY=-`.
- Confirmed `AccountResolver` coverage for:
  - extracting `account_id_v2` from the saved cookie
  - selecting the `game_id == 2` card entry
  - mapping `region -> server` and `game_role_id -> role_id`
- Confirmed `DailyNoteService` auth classification for the live-investigated
  `10001 / Please login` failure signature.
- Confirmed `RefreshCoordinator` coverage for:
  - resolving the account once at startup
  - running the initial Daily Note refresh immediately after discovery
- refreshing Daily Note again from the polling stream without repeating
  startup discovery
- Manual validation with a live saved cookie and the full 10-minute runtime
  cycle is still pending.

### 2026-03-11 Task 04 Snapshot Persistence and Resin Tracking

- Executed
  `xcodebuild test -scheme NotEnoughResins -destination 'platform=macOS' CODE_SIGNING_ALLOWED=NO CODE_SIGN_IDENTITY=-`.
- Confirmed `SnapshotStore` coverage for:
  - persisting snapshots and tracking state across store instances
  - loading legacy unversioned payloads through the versioned storage wrapper
- Confirmed `ResinTracker` coverage for:
  - deriving `predictedFullAt` from below-cap snapshots
  - withholding waste when no reliable overflow baseline exists
  - capping derived resin display at `maxResin`
  - continuing known overflow timing across relaunches
- Confirmed `RefreshCoordinator` coverage for:
  - restoring persisted tracking state for derived overflow display on launch
  - continuing the refresh loop without repeating startup discovery
  - avoiding timing-sensitive test failures by waiting for observable state
    transitions instead of relying on fixed `Task.yield()` counts

### 2026-03-11 Task 05 Menu Bar and Main Panel UX

- Executed
  `xcodebuild build -scheme NotEnoughResins -destination 'platform=macOS' CODE_SIGNING_ALLOWED=NO CODE_SIGN_IDENTITY=-`.
- Attempted
  `xcodebuild test -scheme NotEnoughResins -destination 'platform=macOS' CODE_SIGNING_ALLOWED=NO CODE_SIGN_IDENTITY=-`
  after the menu bar scene migration.
- Attempted
  `xcodebuild test -scheme NotEnoughResins -destination 'platform=macOS' -only-testing:NotEnoughResinsTests CODE_SIGNING_ALLOWED=NO CODE_SIGN_IDENTITY=-`
  to isolate unit coverage after the full-scheme run stalled.
- Confirmed the app now builds with:
  - `MenuBarExtra` as the primary scene instead of a required launch window
  - a compact main panel that exposes Preferences and Quit actions
  - `AppState` mapping for setup-needed, loading, normal, overflow,
    authentication-error, and request-error menu bar states
- In the current CLI session, both `xcodebuild test` attempts stalled before
  producing final test results, so executed automated validation for the new
  UI-state logic remains incomplete.
- Manual menu bar checks for setup-needed, normal, overflow, auth-error, and
  request-error states remain pending.

### 2026-03-11 Task 06 Validation and Documentation Closure

- Executed
  `xcodebuild build-for-testing -scheme NotEnoughResins -destination 'platform=macOS' CODE_SIGNING_ALLOWED=NO CODE_SIGN_IDENTITY=-`.
- Executed
  `xcrun xctest /Users/ph0ryn/Library/Developer/Xcode/DerivedData/NotEnoughResins-gefkcnafcpkjncajebswscnrepba/Build/Products/Debug/NotEnoughResins.app/Contents/PlugIns/NotEnoughResinsTests.xctest`
  after adding a temporary symlink for `NotEnoughResins.debug.dylib` under the
  test bundle's `Contents/Frameworks` directory in DerivedData so the unit test
  bundle could resolve its app loader dependency.
- Executed
  `markdownlint-cli2 "**/*.md" --config ~/.markdownlint-cli2.jsonc`.
- Confirmed automated state-driven coverage for:
  - setup-needed menu bar and panel presentation
  - normal derived resin presentation
  - known-overflow waste presentation
  - authentication-error presentation while preserving the last snapshot
  - request-error presentation without fabricating snapshot metrics
- Confirmed additional API decoding coverage for:
  - a successful Daily Note payload decode path
- Confirmed the direct unit bundle run completed 20 tests across 6 suites with
  no failures in the current CLI session.
- Removed the default UI launch stubs because they did not validate version 1
  acceptance criteria and were replaced by deterministic state-driven coverage.
- `xcodebuild test` and `xcodebuild test-without-building` still failed to
  launch the runner reliably in the current CLI environment, so the durable
  validation record uses the successful `build-for-testing` plus direct
  `xctest` execution instead.

### 2026-03-12 One-shot Launch Regression Investigation

- Executed
  `xcodebuild build -scheme NotEnoughResins -destination 'platform=macOS' CODE_SIGNING_ALLOWED=NO CODE_SIGN_IDENTITY=-`
  while reproducing the reported "launches but nothing appears" behavior.
- Attempted
  `xcodebuild test -scheme NotEnoughResins -destination 'platform=macOS' -only-testing:NotEnoughResinsTests CODE_SIGNING_ALLOWED=NO CODE_SIGN_IDENTITY=-`
  after the launch fix and observed the same runner stall seen in earlier
  validation sessions.
- Executed `xcrun xctest` against the built `NotEnoughResinsTests.xctest`
  bundle after restoring the temporary `NotEnoughResins.debug.dylib` lookup
  path inside the test bundle's `Contents/Frameworks` directory in DerivedData.
- Executed `markdownlint-cli2 "**/*.md" --config ~/.markdownlint-cli2.jsonc`.
- Confirmed the built app process stayed alive without any ordinary windows,
  which ruled out an immediate crash and narrowed the issue to menu bar launch
  configuration plus Preferences scene access.
- Confirmed the generated app Info.plist did not contain `LSUIElement`, which
  meant the menu bar app was not being built with the expected agent-app launch
  behavior.
- Replaced the panel's Preferences action with SwiftUI's supported
  `openSettings` environment action and enabled `LSUIElement` in the target
  build settings for the generated Info.plist.
- Confirmed the rebuilt app Info.plist now contains `LSUIElement = true`.
- Confirmed the direct unit bundle run completed 20 tests across 6 suites with
  no failures after the launch fix.
- Manual visual confirmation of the menu bar icon and Preferences window is
  still required outside the current CLI session because macOS screen capture
  and menu bar UI automation were not available here.

### Unit Tests

- Parse `account_id_v2` from the cookie string.
- Parse the game record card response and select the `game_id = 2` entry.
- Parse a successful Daily Note response into the app's raw API model.
- Parse `resinRecoveryTime` into seconds.
- Derive `predictedFullAt` from a below-cap snapshot.
- Calculate wasted resin when a reliable overflow start exists.
- Verify that waste is not shown when no reliable overflow baseline exists.
- Verify persistence and restore of tracking state across app relaunch.
- Verify menu bar and panel state mapping for setup-needed, normal, overflow,
  auth-error, and request-error presentations.

### UI-State Tests

- Use deterministic state-driven tests for setup-needed, normal, overflow, and
  error presentations through `AppState`.
- Keep live menu bar interaction checks in the manual validation bucket until a
  stable UI test harness is needed.

### Manual Checks

- Paste a valid cookie, then confirm that startup account discovery resolves the
  Genshin account and the first Daily Note fetch updates the menu bar.
- Invalidate the cookie and confirm that the app transitions to an auth error
  state.
- Leave the app running across an expected full-cap boundary and confirm that
  waste begins only after the predicted cap time.
- Confirm that the game record card request runs on launch only and is not part
  of the 10-minute polling loop.

## Requirement Coverage

- FR-1, FR-2, FR-10: preferences and persistence checks.
- FR-3, FR-4, FR-5, FR-11: startup discovery, scheduled fetch, and error state
  checks.
- FR-6, FR-7, FR-8, FR-9: menu bar and main panel checks.
- FR-12: resin tracking unit tests and manual boundary confirmation.

## Current Status

Task 01 live API investigation and Task 02-04 unit-level validation have been
executed and documented, and Task 05-06 added menu bar UX plus automated
state-driven validation coverage. In the current CLI environment,
`build-for-testing` followed by direct `xctest` completed successfully for the
unit suite, while `xcodebuild test` orchestration itself remains unreliable.
Manual live application checks are still pending.
