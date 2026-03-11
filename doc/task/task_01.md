# Task 01 - Confirm HoYoLAB contract and test fixtures

## Priority

P0

## Goal

Confirm the live HoYoLAB request and response details that the app needs before
the resolver and Daily Note client are implemented.

## Scope

- Execute redacted live requests against the game record card and Daily Note
  endpoints with the cookie from `.env`.
- Capture the exact shared header set, required query parameters, and the
  `game_id == 2` field mapping to Daily Note `server` and `role_id`.
- Record representative success, auth failure, and non-auth failure payload
  behavior for later typed error handling.
- Produce sanitized fixtures or structured notes that later tests can use
  without storing secrets.

## Acceptance Criteria

- Repository docs record the confirmed header set used by both endpoints.
- Repository docs record the exact card response fields that derive `server` and
  `role_id`.
- Representative `retcode` handling rules distinguish auth failure from generic
  request failure.
- Sanitized fixtures or equivalent structured evidence exist for follow-up model
  and test work.

## Out of Scope

- Shipping the Swift networking layer.
- Shipping menu bar or preferences UI behavior.

## Implementation Notes

- Keep cookies, account IDs, and role IDs out of version control.
- If the live API contradicts `doc/spec.md` or `doc/design.md`, update those
  artifacts before downstream implementation starts.

## Verification

- Manual: run live requests with the `.env` cookie and confirm the recorded
  mappings and failure classifications against the responses.
- `markdownlint-cli2 "doc/**/*.md" --config ~/.markdownlint-cli2.jsonc`

## References

- `doc/spec.md` FR-3, FR-5, FR-11, Unresolved Items
- `doc/design.md` Core Components / AccountResolver
- `doc/design.md` Core Components / DailyNoteService
- `doc/design.md` API Integration Flow / Live API Investigation Gate
- `doc/design.md` Error Handling Policy
- `doc/validation.md` Planned Checks / Live API Investigation
