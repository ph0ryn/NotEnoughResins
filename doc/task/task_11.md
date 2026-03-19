# Task 11 - Restore footer actions after saving Preferences and remove redundant cookie reload

## Priority

P1

## Goal

Restore reliable footer interaction after a Preferences save and close cycle,
stabilize post-save refresh behavior, and simplify Preferences so the cookie
workflow is save-only.

## Scope

- Investigate and fix the footer-action regression in the menu bar panel after
  the user saves a cookie in Preferences and closes the Settings window.
- Ensure every successful cookie save immediately triggers a refresh attempt,
  including saves whose normalized cookie matches the existing stored value.
- Remove `Reload Saved Cookie` from Preferences and any directly related code,
  copy, and automated coverage.
- Use a standard single-line Preferences cookie field that keeps the active
  insertion point visible while editing long cookie values.
- Keep the current Keychain persistence, save path, and startup read behavior
  unchanged.

## Acceptance Criteria

- After the user opens Preferences from the main panel, saves a cookie, and
  closes the Settings window, the main panel footer actions remain operable in
  the same app session.
- If a cookie is configured, the `Refresh` footer action remains enabled.
- Saving a cookie from a no-cookie state reaches a usable Daily Note result or
  error state without requiring the manual `Refresh` action.
- Saving the same normalized cookie value again still triggers an immediate
  refresh attempt.
- Preferences no longer shows a `Reload Saved Cookie` control.
- The Preferences cookie editor behaves as a normal single-line text field and
  keeps the active insertion point visible while editing long cookie values.
- The Preferences cookie editor continues to accept repeated click-to-place
  caret moves and deletions without trapping focus or losing normal cursor
  placement behavior mid-edit.
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
- Investigation on 2026-03-19 found that `AppState` only reacted to
  `PreferencesStore.$storedCookie`, while `PreferencesStore.saveCookie(_:)`
  publishes the cookie before it updates `configurationState`. The fix should
  make `AppState` react to configuration-state changes directly instead of
  depending on the publish order of a different property.
- Follow-up investigation on 2026-03-19 found that same-cookie saves were also
  dropped by `PreferencesStore.$storedCookie.removeDuplicates()`, so
  post-save refresh cannot be modeled as a stored-cookie diff.
- Treat refresh availability as a configured-cookie concern. Once a cookie is
  present, the footer `Refresh` control should stay enabled even if a refresh
  loop is already in flight.
- Keep startup refresh and post-save refresh distinct. Startup may continue to
  use the discovery-first path, but successful in-session saves should trigger
  the same coordinator entrypoint as the manual footer refresh so the refresh
  behavior is symmetric.
- Treat the Preferences editor contents as the only in-window editable source
  of truth. If the stored cookie changes, the editor may still reflect the
  published value through the existing store binding.
- The cookie remains plain text, but task11 no longer requires a custom
  multiline editor. A standard single-line field is preferred because it keeps
  normal caret visibility for long values.
- Follow-up investigation on 2026-03-19 found that the direct SwiftUI
  `TextField` replacement did not preserve reliable caret placement for long
  cookie editing in the Settings form. The task contract remains single-line,
  but an AppKit-backed single-line field is acceptable if needed to preserve
  ordinary macOS text-field behavior.
- Preserve current save validation and feedback messaging unless a small copy
  adjustment is required to keep the simplified Preferences flow coherent.

## Verification

- `xcodebuild test -scheme NotEnoughResins -destination 'platform=macOS' CODE_SIGNING_ALLOWED=NO CODE_SIGN_IDENTITY=-`
- `markdownlint-cli2 "doc/**/*.md" --config ~/.markdownlint-cli2.jsonc`
- Manual: open Preferences from the menu bar panel, save a cookie, close
  Preferences, and confirm `Preferences`, `Refresh`, and `Quit` remain
  clickable.
- Manual: launch without a saved cookie, save a cookie, and confirm the app
  reaches a usable Daily Note state or explicit error state without pressing
  the footer `Refresh` button.
- Manual: save the same cookie again and confirm an immediate refresh runs
  again.
- Manual: confirm Preferences no longer shows `Reload Saved Cookie`.
- Manual: confirm the cookie editor behaves as a normal single-line field and
  keeps the active insertion point visible while editing a long cookie.
- Manual: confirm repeated caret repositioning and deletions continue to work
  while editing the same long cookie value.

## References

- `doc/spec.md` FR-9
- `doc/spec.md` FR-10
- `doc/design.md` Main Panel
- `doc/design.md` Preferences
- User-confirmed task scope on 2026-03-19
