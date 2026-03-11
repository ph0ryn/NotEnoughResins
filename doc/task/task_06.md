# Task 06 - Close validation and documentation gaps

## Priority

P2

## Goal

Convert the planned validation coverage into executed checks and leave durable
evidence for the first delivery.

## Scope

- Add unit tests for cookie parsing, card-response selection, Daily Note
  decoding, resin tracking, and persistence restore.
- Add UI or state-driven tests for setup-needed, normal, overflow, and error
  presentations.
- Update `doc/validation.md` with executed commands, outcomes, and remaining
  gaps.
- Update `doc/change-log.md` and any required task-completion notes when the
  implementation tasks land.

## Acceptance Criteria

- Automated coverage exists for the core parsing, scheduling, tracking, and
  UI-state logic defined in the validation plan.
- `doc/validation.md` records what was actually run and any deferred checks.
- Documentation reflects the resolved API assumptions and completed
  implementation coverage.

## Out of Scope

- New user-facing features beyond version 1.
- CI infrastructure changes unless they are directly needed to run the required
  checks locally.

## Implementation Notes

- Use redacted fixtures from Task 01 to keep tests deterministic and secret
  free.
- Treat validation artifacts as incomplete until executed results replace
  planned-only wording.

## Verification

- `xcodebuild test -scheme NotEnoughResins -destination 'platform=macOS'`
- `markdownlint-cli2 "doc/**/*.md" --config ~/.markdownlint-cli2.jsonc`

## References

- `doc/spec.md` Acceptance Criteria
- `doc/design.md` Requirement Mapping
- `doc/design.md` Error Handling Policy
- `doc/validation.md` Validation Targets
- `doc/validation.md` Planned Checks
- `doc/validation.md` Requirement Coverage
