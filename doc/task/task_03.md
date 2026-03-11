# Task 03 - Implement startup discovery and Daily Note refresh

## Priority

P0

## Goal

Resolve the configured account once at startup and maintain a current Daily
Note snapshot with the required polling behavior.

## Scope

- Implement `AccountResolver` cookie parsing and game card selection for
  `game_id == 2`.
- Implement `DailyNoteService` request building, decoding, and typed
  application errors.
- Implement `RefreshCoordinator` to run discovery once, fetch immediately after
  success, then poll Daily Note every 10 minutes.
- Record fetch timestamps and expose the latest successful snapshot plus current
  request state to the state layer.
- Prevent the polling loop from starting when discovery fails or configuration
  is incomplete.

## Acceptance Criteria

- Startup extracts `account_id_v2` from the saved cookie and resolves the
  Genshin account before Daily Note polling begins.
- The first Daily Note refresh runs immediately after successful discovery,
  followed by a fixed 10-minute interval.
- The game record card request is not repeated in the steady-state polling
  loop.
- Auth failures surface separately from transport or decode failures.

## Out of Scope

- Overflow waste derivation and cross-launch tracking.
- Final menu bar and main panel presentation details.

## Implementation Notes

- Reuse the confirmed header set from Task 01 for both endpoints.
- Keep the network layer injectable so parsing and scheduling can be tested
  without live traffic.

## Verification

- `xcodebuild test -scheme NotEnoughResins -destination 'platform=macOS'`
- Manual: run with a valid saved cookie and confirm discovery happens once
  before the initial Daily Note fetch, then confirm no additional card requests
  occur during a 10-minute refresh cycle.

## References

- `doc/spec.md` FR-3
- `doc/spec.md` FR-4
- `doc/spec.md` FR-5
- `doc/spec.md` FR-11
- `doc/design.md` Core Components / AccountResolver
- `doc/design.md` Core Components / DailyNoteService
- `doc/design.md` Core Components / RefreshCoordinator
- `doc/design.md` API Integration Flow / Startup Discovery
- `doc/design.md` Error Handling Policy
- `doc/validation.md` Validation Targets / Startup account discovery
- `doc/validation.md` Validation Targets / Scheduled fetch behavior
