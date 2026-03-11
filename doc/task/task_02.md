# Task 02 - Add secure configuration and preferences editing

## Priority

P0

## Goal

Let the user save the HoYoLAB cookie securely and manage it from a dedicated
preferences surface.

## Scope

- Implement `PreferencesStore` with Keychain-backed cookie storage and
  configuration completeness publishing.
- Persist only non-sensitive metadata outside Keychain when needed.
- Add a preferences scene or window for editing the cookie.
- Validate cookie presence before save or refresh actions can proceed.
- Load the saved configuration on launch so the app can decide whether it is
  ready for discovery or still needs setup.

## Acceptance Criteria

- The user can open Preferences, save a non-empty cookie, and relaunch without
  re-entering it.
- Empty cookie input cannot be saved as a valid configuration.
- Cookie values are not written to `UserDefaults` or application logs in plain
  text.
- App state can distinguish `needsConfiguration` from `configurationReady`.

## Out of Scope

- Live account discovery or Daily Note polling.
- Menu bar resin status presentation.

## Implementation Notes

- Keep the preferences API narrow so later tasks can change UI details without
  rewriting storage behavior.
- Favor testable wrappers around Keychain calls instead of embedding Security
  framework calls directly in views.

## Verification

- `xcodebuild test -scheme NotEnoughResins -destination 'platform=macOS'`
- Manual: launch the app, save a cookie in Preferences, relaunch, and confirm
  the stored value is still available for a follow-up fetch.

## References

- `doc/spec.md` FR-1
- `doc/spec.md` FR-2
- `doc/spec.md` FR-10
- `doc/spec.md` NFR-3
- `doc/design.md` App Scene Structure
- `doc/design.md` Core Components / PreferencesStore
- `doc/design.md` UI Design / Preferences
- `doc/design.md` Security Considerations
