# Task 05 - Deliver the menu bar and main panel UX

## Priority

P0

## Goal

Replace the default window-first shell with a menu bar experience that
communicates setup, normal, overflow, and failure states.

## Scope

- Replace the `WindowGroup`-first entry flow with `MenuBarExtra` and wire
  Preferences and Quit actions into the menu bar surface.
- Implement `AppState` mapping from configuration, refresh state, snapshot, and
  tracker outputs to UI-ready states.
- Build menu bar label and icon rendering for `needsConfiguration`, `loading`,
  `normal`, `overflow`, `authError`, and `requestError`.
- Build the main panel summary with last successful refresh time and selected
  Daily Note fields.

## Acceptance Criteria

- The app launches without requiring a normal content window.
- With no saved cookie, the menu bar shows a configuration-needed state.
- With a valid snapshot below cap, the menu bar shows `{current} / {max}` plus
  a resin icon.
- With known overflow, the menu bar shows a trash icon, wasted resin, and a
  resin icon.
- The main panel exposes formatted Daily Note data plus Preferences and Quit
  actions.
- On request or auth failure, the menu bar shows a non-normal status instead of
  implying fresh data.

## Out of Scope

- Multi-account support.
- Additional notification or reminder surfaces.

## Implementation Notes

- Keep the panel compact; version 1 does not need a second major window.
- The main panel may continue showing the last successful snapshot, but the
  menu bar must reflect the current fetch status.

## Verification

- `xcodebuild test -scheme NotEnoughResins -destination 'platform=macOS'`
- Manual: exercise setup-needed, normal, overflow, auth-error, and
  request-error states from the menu bar and confirm the main panel exposes
  Preferences and Quit.

## References

- `doc/spec.md` FR-6
- `doc/spec.md` FR-7
- `doc/spec.md` FR-8
- `doc/spec.md` FR-9
- `doc/spec.md` NFR-1
- `doc/spec.md` NFR-2
- `doc/spec.md` Acceptance Criteria / Clicking the menu bar entry opens a panel
  that exposes formatted Daily Note data plus Preferences and Quit actions
- `doc/design.md` App Scene Structure
- `doc/design.md` Core Components / AppState
- `doc/design.md` UI Design / Menu Bar States
- `doc/design.md` UI Design / Main Panel
- `doc/design.md` Error Handling Policy
