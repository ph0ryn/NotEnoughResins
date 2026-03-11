# Task 04 - Persist snapshots and derive resin waste

## Priority

P1

## Goal

Restore enough state across launches to derive resin recovery and overflow
waste without inventing missing history.

## Scope

- Implement `SnapshotStore` for the latest successful Daily Note snapshot and
  tracking markers.
- Implement `ResinTracker` logic for `predictedFullAt`, `overflowStartAt`, and
  wasted resin calculation.
- Restore cached tracking state on launch and update it on each successful
  fetch.
- Provide locally derived resin or waste display values between successful
  fetches using the 8-minute recovery rule.

## Acceptance Criteria

- Below-cap snapshots update `predictedFullAt` from `resinRecoveryTime`.
- Capped snapshots show waste only when a reliable overflow baseline is known.
- Known overflow timing survives relaunch and continues from persisted tracking
  state.
- Derived display values never exceed `maxResin` and never fabricate overflow
  history when the baseline is missing.

## Out of Scope

- Menu bar copy, iconography, or layout polish.
- Push notifications or reminder behavior.

## Implementation Notes

- Prefer under-reporting over over-reporting when state is incomplete.
- Keep persisted models versionable so later schema changes remain manageable.

## Verification

- `xcodebuild test -scheme NotEnoughResins -destination 'platform=macOS'`
- Manual: seed a below-cap snapshot, cross the predicted cap time, relaunch,
  and confirm waste begins only when the persisted baseline supports it.

## References

- `doc/spec.md` FR-12
- `doc/spec.md` NFR-4
- `doc/spec.md` Acceptance Criteria / Resin waste is only shown when the
  application has enough data to support the estimate
- `doc/design.md` Core Components / SnapshotStore
- `doc/design.md` Core Components / ResinTracker
- `doc/design.md` Data Model / Local Persistence Models
- `doc/design.md` API Integration Flow / Below-Cap Baseline
- `doc/design.md` API Integration Flow / Entering or Remaining in Capped State
- `doc/design.md` API Integration Flow / Derived Display Between Fetches
