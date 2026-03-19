# NotEnoughResins Design

## Document Status

- Status: Draft
- Last updated: 2026-03-19
- Related requirements: `doc/spec.md`

## Current Baseline

The repository currently contains the default SwiftUI macOS app template:

- `NotEnoughResinsApp.swift` starts with a `WindowGroup`.
- `ContentView.swift` is placeholder UI.
- No networking, persistence, menu bar integration, or tracking logic exists.

The design below defines the first implementation shape for version 1.

## Design Goals

- Deliver the primary workflow from the menu bar instead of a normal document
  window.
- Separate API access, secure configuration persistence, and derived resin
  tracking so the logic is unit-testable.
- Keep Daily Note snapshots and overflow tracking in memory only so relaunches
  never present stale server-derived state as current.
- Keep version 1 limited to a single configured account.

## Requirement Mapping

- FR-1, FR-2, FR-10: `PreferencesStore`, Keychain persistence, preferences UI.
- FR-3, FR-4, FR-5, FR-11: account resolver, `DailyNoteService`, and scheduled
  refresh coordinator.
- FR-6, FR-7, FR-8, FR-9: menu bar scene and main panel view model.
- FR-12: `ResinTracker` within the current app session.

## Architecture

### App Scene Structure

Replace the default window-first app structure with:

- A `MenuBarExtra` scene for the primary interaction point.
- A dedicated preferences scene or window for editing configuration.
- An optional hidden or utility window only if needed for SwiftUI scene support.

The main panel opened from the menu bar should present the latest account state,
refresh status, Preferences, and Quit actions.

Opening Preferences from the panel and then closing the Settings scene must not
leave the footer actions in a non-interactive state. The footer controls should
remain hittable without requiring the panel to be recreated.

### Core Components

#### `PreferencesStore`

Responsibilities:

- Coordinate secure storage for the cookie value.
- Publish whether configuration is complete enough to fetch.
- Publish a save-success event for each successful cookie save, even when the
  normalized cookie value is unchanged.

Storage choice:

- Cookie in Keychain.
- Derived or cached non-sensitive account metadata in `UserDefaults`.

#### `AccountResolver`

Responsibilities:

- Extract `account_id_v2` from the saved cookie.
- Call the game record card endpoint on startup with the same header set used
  for Daily Note.
- Select the entry where `game_id == 2`.
- Produce the `server` and `roleId` values required by the Daily Note request.

Implementation note:

- Live API investigation on 2026-03-11 confirmed the resolver mapping for the
  current contract:
  - `uid` query parameter comes from cookie `account_id_v2`
  - select `data.list[]` where `game_id == 2`
  - map `region -> server`
  - map `game_role_id -> roleId`

#### `DailyNoteService`

Responsibilities:

- Build the HoYoLAB request.
- Attach required headers and cookie.
- Decode `DailyNoteResponse`.
- Convert network or payload failures into typed application errors.

#### `RefreshCoordinator`

Responsibilities:

- Run account discovery once on launch when configuration is complete.
- Trigger the first Daily Note refresh after account discovery succeeds.
- Trigger a refresh every 10 minutes while the app is running.
- Record the fetch timestamp used by the tracking pipeline.

Polling rule:

- The periodic loop refreshes Daily Note only.
- The game record card request is not repeated during the normal polling loop.

#### `ResinTracker`

Responsibilities:

- Derive `fullAt` from a below-cap snapshot.
- Determine whether overflow timing is known.
- Calculate wasted resin from the first known capped moment.
- Provide locally derived display values between fetches.

#### `AppState`

Responsibilities:

- Hold the current load state for the UI.
- Combine preferences, network state, the latest in-memory snapshot, and
  derived resin state.
- Expose view-friendly status for the menu bar and main panel.
- Start startup discovery from the saved cookie on launch, and trigger
  post-save refresh from explicit save events instead of from cookie-value
  diffs.

## Data Model

### Raw API Models

Use typed models for the subset of the draft response that is needed in version
1:

- `currentResin`
- `maxResin`
- `resinRecoveryTime`
- Expedition summary fields
- Home coin fields
- Daily task fields
- Any additional fields selected for the main panel

### Local Persistence Models

Suggested persisted structures:

- `AccountConfiguration`
  - no user-editable fields beyond the stored cookie reference

## API Integration Flow

### Startup Discovery

On application launch:

1. Read the cookie from secure storage.
2. Parse `account_id_v2` from the cookie string.
3. Call
   `https://sg-public-api.hoyolab.com/event/game_record/card/wapi/getGameRecordCard?uid={account_id_v2}`.
4. Reuse the same request headers planned for the Daily Note request.
5. Inspect the returned list and select the entry where `game_id == 2`.
6. Extract the fields required to build the Daily Note request.
7. Cache the resolved account metadata for the current app session.

If any of these steps fail, the app should stop before entering the periodic
Daily Note polling loop.

### Live API Investigation Gate

Live API investigation was executed on 2026-03-11 against both approved
HoYoLAB endpoints using the cookie from `.env`. The confirmed results for the
current contract are:

- The tested minimal shared header set for both endpoints was `Cookie`.
- Additional headers such as `Accept`, `x-rpc-client_type`,
  `x-rpc-app_version`, `x-rpc-language`, and `User-Agent` were tolerated but
  not required in the tested calls.
- The game record card endpoint returned a top-level envelope of `retcode`,
  `message`, and `data.list[]`.
- The selected `game_id == 2` entry mapped `region -> server` and
  `game_role_id -> role_id` for the Daily Note request.
- The Daily Note endpoint returned a top-level envelope of `retcode`,
  `message`, and `data`, with the version 1 fields needed for resin, expeditions,
  home coin, daily tasks, and transformer status.
- Success, auth failure, and parameter failure all returned HTTP `200`, so the
  implementation must classify outcomes from the HoYoLAB payload instead of the
  HTTP status code alone.
- The observed auth failure signature was `retcode = 10001` and
  `message = "Please login"`.
- The observed generic request failure signature was `retcode = -1` with
  parameter-specific messages such as `Invalid uid` and
  `param role_id error: value must be greater than 0`.

### Below-Cap Baseline

On each successful fetch where `currentResin < maxResin`:

1. Parse `resinRecoveryTime` into seconds.
2. Compute `predictedFullAt = fetchedAt + resinRecoveryTime`.
3. Clear any stale overflow-only display state.
4. Keep the new snapshot and tracking markers in memory for the current app
   session.

### Entering or Remaining in Capped State

On each successful fetch where `currentResin >= maxResin`:

1. If a prior `predictedFullAt` exists and is earlier than or equal to
   `fetchedAt`, use that timestamp as `overflowStartAt`.
2. If no reliable `predictedFullAt` exists, mark overflow timing as unknown and
   do not fabricate historical waste.
3. If `overflowStartAt` is known, compute:
   `wastedResin = floor((now - overflowStartAt) / 480 seconds)`.

This rule intentionally prefers under-reporting over showing an invented waste
count.

### Derived Display Between Fetches

Between successful fetches, local display values may advance using wall-clock
time:

- If below cap, increase displayed resin by `floor(elapsed / 480)` without
  exceeding `maxResin`.
- If capped and `overflowStartAt` is known, increase displayed wasted resin by
  `floor(elapsed / 480)` from the last confirmed baseline.

The UI should indicate the last successful update time so users can distinguish
derived display state from fresh server data.

## UI Design

### Menu Bar States

Recommended state model:

- `needsConfiguration`
- `loading`
- `normal(current, max)`
- `overflow(wasted)`
- `authError`
- `requestError`

Display rules:

- `needsConfiguration`: short setup-needed label.
- `loading`: minimal loading indicator or placeholder text.
- `normal`: `{current} / {max}` plus resin icon.
- `overflow`: trash icon, wasted resin value, resin icon.
- `authError`: short invalid-cookie label.
- `requestError`: short stale or failed label, preferably without implying auth
  failure.

### Main Panel

The main panel should show:

- Current menu bar status in expanded form.
- Last successful refresh time.
- Core Daily Note values relevant to routine play.
- Preferences action.
- Refresh action.
- Quit action.

Version 1 does not need a complex dashboard layout. A compact summary layout is
enough as long as the information is clearly grouped.

If the user returns from Preferences to the menu bar panel, the same panel
session should continue to accept footer button clicks.

If secure cookie configuration is present, the Refresh footer control should
remain enabled instead of becoming disabled during in-flight refresh work. A
manual refresh may restart the current refresh loop from the configured cookie.

### Preferences

The preferences UI should allow editing:

- Cookie.

The cookie editor is the single source of truth for the currently edited value.
The Preferences flow is edit and save only; it does not expose a separate
"reload saved cookie" control.

The UI should validate presence before enabling save.
The cookie editor should behave like an ordinary single-line text field. When
the cookie is longer than the visible width, the field should keep the active
insertion point visible using standard field behavior instead of a custom
multiline editor.
If the direct SwiftUI control does not preserve reliable caret placement for
long cookie values, the implementation may use an AppKit-backed single-line
field as long as the user-facing behavior still matches a normal macOS text
field.

A successful save should trigger the same immediate refresh entrypoint used by
the manual Refresh footer action. This post-save refresh is driven by an
explicit save-success event rather than by detecting whether the stored cookie
string changed.

Startup behavior stays separate: launch-time restore still starts the initial
discovery flow through the startup refresh path, while in-session saves use the
manual-refresh path.

## Error Handling Policy

- Network transport failures produce `requestError`.
- Response decode failures produce `requestError`.
- HoYoLAB responses with `retcode = 10001` and `message = "Please login"`
  produce `authError`.
- Non-success HoYoLAB responses that do not match the auth signature produce
  `requestError`.
- HTTP `200` alone is not sufficient to classify a request as successful,
  because auth and parameter failures also returned HTTP `200` in the live
  investigation.
- On failure, the app may continue to show the last successful snapshot in the
  main panel, but the menu bar state must not imply that a fresh fetch succeeded.

## Security Considerations

- Store the cookie in Keychain rather than plain text user defaults.
- Avoid logging full cookie values.
- Treat resolved account metadata as non-sensitive session data.

## Performance and Operational Considerations

- A 10-minute polling interval keeps network usage low for version 1.
- Local derivation reduces the need for frequent fetches while keeping the menu
  bar useful.
- The tracking logic resets on relaunch and shall avoid inventing overflow
  history until the current app session has enough baseline data.

## Alternatives Considered

### Alternative 1: Fetch Every Minute

Rejected because it increases network dependency and still does not solve
historical overflow estimation by itself.

### Alternative 2: Show Only Last Fetched Resin

Rejected because a stale fixed number is too weak for a menu bar utility whose
primary value is glanceable status.

### Alternative 3: Derive Waste Even Without a Baseline

Rejected because the app would need to invent an overflow start time and could
overstate wasted resin.

## Impact Analysis

Implementation based on this design will replace the current placeholder app
entry flow and add:

- Networking.
- Persistence.
- Menu bar scene management.
- Unit tests for parsing and tracking.
- UI tests or manual checks for primary menu bar states.
