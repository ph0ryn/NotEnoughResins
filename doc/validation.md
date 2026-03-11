# NotEnoughResins Validation

## Document Status

- Status: Partially Executed
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

## Requirement Coverage

- FR-1, FR-2, FR-10: preferences and persistence checks.
- FR-3, FR-4, FR-5, FR-11: startup discovery, scheduled fetch, and error state
  checks.
- FR-6, FR-7, FR-8, FR-9: menu bar and main panel checks.
- FR-12: resin tracking unit tests and manual boundary confirmation.

## Residual Gaps

- Polling, resin tracking, and final menu bar UI checks are still pending
  execution in Tasks 03 through 06.
- No CI status was checked because the repository does not yet expose remote CI
  to this workflow.
