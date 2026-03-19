# Task 07 - Refresh SDD artifacts for the shipped v1 baseline

## Priority

P2

## Goal

Bring the requirements and design artifacts back into sync with the implemented
version 1 app so future work starts from an accurate brownfield baseline.

## Scope

- Update `doc/spec.md` document status and background text so it no longer
  describes the repository as an unimplemented SwiftUI scaffold.
- Update `doc/design.md` document status and current-baseline section so it
  summarizes the shipped menu bar, networking, persistence, and tracking shape
  instead of the original placeholder app template.
- Replace outdated unresolved-item wording in `doc/spec.md` with the current
  implemented UI decisions, or narrow the list to any follow-up that is still
  genuinely open.
- Preserve traceability by updating any affected validation or change-control
  notes that depend on the refreshed requirements or design wording.

## Acceptance Criteria

- `doc/spec.md` no longer claims that the repository only contains the default
  SwiftUI scaffold.
- `doc/spec.md` no longer treats already-shipped main-panel field choices or
  configuration and authentication status wording as unresolved.
- `doc/design.md` no longer describes the codebase as a pre-implementation
  `WindowGroup` template and instead captures the current brownfield baseline.
- The updated requirements and design artifacts clearly communicate whether
  version 1 is implemented, validated locally, and what follow-up remains.

## Out of Scope

- Changing runtime behavior or UI copy in the app code.
- Adding new version 1 features or expanding scope beyond documentation
  alignment.

## Implementation Notes

- Preserve the original version 1 intent; this task is about artifact accuracy,
  not redesigning the shipped behavior.
- Prefer explicit brownfield wording where historical context matters, rather
  than silently deleting implementation-era assumptions.
- Keep remaining follow-up explicit and narrow so future tasks are based on
  real gaps instead of stale draft language.

## Verification

- Manual: read `doc/spec.md` and `doc/design.md` after the update and confirm
  that each pre-implementation statement is either removed, reframed as
  historical context, or replaced with the current shipped baseline.
- `markdownlint-cli2 "doc/**/*.md" --config ~/.markdownlint-cli2.jsonc`

## References

- `doc/spec.md` Document Status
- `doc/spec.md` Background
- `doc/spec.md` Unresolved Items
- `doc/design.md` Document Status
- `doc/design.md` Current Baseline
- `doc/validation.md` 2026-03-12 - Requirements and implementation consistency
  review
- `doc/change-log.md` Post-Implementation Artifact Review
