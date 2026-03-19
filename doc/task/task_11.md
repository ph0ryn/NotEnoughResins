# Task 11 - Restore footer actions after saving Preferences and remove redundant cookie reload

## Priority

P1

## Goal

Restore reliable footer interaction after a Preferences save and close cycle,
and simplify Preferences so the cookie workflow is save-only.

## Scope

- Investigate and fix the footer-action regression in the menu bar panel after
  the user saves a cookie in Preferences and closes the Settings window.
- Remove `Reload Saved Cookie` from Preferences and any directly related code,
  copy, and automated coverage.
- Keep the current Keychain persistence, save path, and startup read behavior
  unchanged.

## Acceptance Criteria

- After the user opens Preferences from the main panel, saves a cookie, and
  closes the Settings window, the main panel footer actions remain operable in
  the same app session.
- Preferences no longer shows a `Reload Saved Cookie` control.
- Saving a non-empty cookie still writes the normalized value to Keychain and
  leaves Preferences in a configuration-ready state.
- Existing startup cookie loading behavior remains unchanged.

## Out of Scope

- Automatic cleanup or recovery of stale Keychain items.
- Changes to Keychain service naming, cookie storage format, or ACL handling.
- Broader Preferences redesign beyond removing the redundant reload control.

## Implementation Notes

- Keep the task outcome-driven: fix the footer interaction regression without
  expanding scope into unrelated menu bar or Keychain work.
- Treat the Preferences editor contents as the only in-window editable source
  of truth. If the stored cookie changes, the editor may still reflect the
  published value through the existing store binding.
- Preserve current save validation and feedback messaging unless a small copy
  adjustment is required to keep the simplified Preferences flow coherent.

## Verification

- `xcodebuild test -scheme NotEnoughResins -destination 'platform=macOS' CODE_SIGNING_ALLOWED=NO CODE_SIGN_IDENTITY=-`
- `markdownlint-cli2 "doc/**/*.md" --config ~/.markdownlint-cli2.jsonc`
- Manual: open Preferences from the menu bar panel, save a cookie, close
  Preferences, and confirm `Preferences`, `Refresh`, and `Quit` remain
  clickable.
- Manual: confirm Preferences no longer shows `Reload Saved Cookie`.

## References

- `doc/spec.md` FR-9
- `doc/spec.md` FR-10
- `doc/design.md` Main Panel
- `doc/design.md` Preferences
- User-confirmed task scope on 2026-03-19
