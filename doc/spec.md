# NotEnoughResins Requirements Specification

## Document Status

- Status: Draft
- Last updated: 2026-03-19
- Source draft: `temp-spec.md`

## Background

NotEnoughResins is a macOS menu bar app for monitoring Genshin Impact resin
through the HoYoLAB Daily Note API. The current repository only contains the
default SwiftUI application scaffold, so this document defines the first
delivery scope before implementation starts.

## Objective

The application shall let a user see resin status from the macOS menu bar
without opening a full application window, and it shall estimate how much resin
has been wasted after natural recovery reaches the cap.

## Scope

Version 1 includes the following:

- A macOS menu bar application for a single Genshin account.
- User configuration for the cookie required by the HoYoLAB APIs.
- Startup-time account discovery from the cookie before Daily Note polling
  begins.
- Periodic Daily Note fetches while the application is running.
- Menu bar status for normal resin state, overflow state, and invalid
  configuration or authentication.
- A main panel that shows formatted Daily Note data and exposes Preferences and
  Quit actions.
- Local persistence for configuration only.
- Daily Note snapshots and resin tracking state kept in memory for the current
  app session only.

## Non-Scope

Version 1 excludes the following:

- Multi-account support.
- Browser-based login or cookie acquisition automation.
- Editing game state or sending write operations to HoYoLAB.
- Push notifications, sounds, or reminders.
- Detailed analytics beyond the current resin waste estimate.
- Support for games other than Genshin Impact.

## Functional Requirements

### FR-1 Account Configuration

The application shall allow the user to configure the cookie value required to
call the HoYoLAB APIs.

The application shall treat the cookie as mandatory before the first fetch.

### FR-2 Secure Persistence

The application shall persist account configuration locally so the user does not
need to re-enter it on each launch.

### FR-3 Startup Account Discovery

When the application starts with a saved cookie, it shall:

1. Extract `account_id_v2` from the cookie.
2. Call the game record card endpoint once for that account.
3. Select the Genshin account entry where `game_id = 2`.
4. Use the resolved account data to prepare Daily Note requests for the current
   app session.

This discovery request shall run on startup only and shall not be part of the
periodic polling loop.

### FR-4 Fetch Schedule

After startup account discovery succeeds, the application shall fetch Daily Note
data once and then poll on a fixed 10-minute interval while the application is
running.

### FR-5 API Requests

The application shall call the HoYoLAB game record card endpoint with:

- Method: `GET`
- URL:
  `https://sg-public-api.hoyolab.com/event/game_record/card/wapi/getGameRecordCard`
- Query parameter: `uid={account_id_v2}`
- The same request header set used by the Daily Note request, including the
  user-provided cookie

The application shall call the HoYoLAB Daily Note endpoint with:

- Method: `GET`
- URL:
  `https://sg-public-api.hoyolab.com/event/game_record/app/genshin/api/dailyNote`
- Query parameters: `server`, `role_id`
- Headers required for the current integration, including the user-provided
  cookie

If the response payload includes `retcode`, `message`, and `data`, the
application shall treat `data` as the authoritative snapshot for UI and resin
tracking.

Live API investigation on 2026-03-11 confirmed the following integration
contract for version 1:

- The tested minimal shared header set for both endpoints was `Cookie`.
- The selected Genshin card entry maps `region -> server` and
  `game_role_id -> role_id`.
- Success, auth failure, and parameter failure all returned HTTP `200`, so the
  application must classify outcomes from `retcode` and `message` rather than
  from the HTTP status code alone.

### FR-6 Menu Bar Status Before Valid Configuration

Before a valid configuration exists, the menu bar shall show a clear
configuration-needed state instead of resin data.

### FR-7 Menu Bar Status During Normal Resin Recovery

When resin is below the effective cap and the latest successful snapshot is
usable, the menu bar shall show:

- Current resin.
- Maximum resin.
- A resin icon.

### FR-8 Menu Bar Status During Overflow Waste

When the application can determine that natural recovery has already been capped
for the current account, the menu bar shall show:

- A trash can icon.
- Estimated wasted resin.
- A resin icon.

### FR-9 Main Panel

Clicking the menu bar entry shall open the application's main panel. The panel
shall show a formatted view of Daily Note data from the latest successful
snapshot and shall expose:

- Individual expedition entries with per-character remaining time or completion
  state when expedition data is available.
- A Preferences action.
- A Refresh action.
- A Quit action.

After the user opens Preferences from the main panel and closes the Preferences
window, the main panel footer actions shall remain operable in the same app
session.

If a cookie is configured, the Refresh action shall remain enabled even while
the app is resolving the account or refreshing the Daily Note snapshot.

### FR-10 Preferences UI

The application shall provide a preferences UI that lets the user update stored
account configuration through a single edit-and-save flow for the stored
cookie.

The preferences UI shall not require a separate control to reload the saved
cookie into the editor.

Each successful cookie save shall immediately trigger a refresh attempt, even
when the normalized cookie string is unchanged from the previously stored
value.

After a successful save, the user shall not need to press the manual Refresh
action to load the first usable Daily Note snapshot or error state for that
saved cookie.

### FR-11 Error Handling

If the API request fails, returns invalid data, or indicates that the cookie is
expired or rejected, the application shall surface a non-normal status instead
of pretending the resin state is current.

Live API investigation on 2026-03-11 confirmed the current failure split for
version 1:

- Auth failure: `retcode = 10001`, `message = "Please login"`
- Generic request failure: `retcode = -1` with parameter-specific messages such
  as `Invalid uid` or `param role_id error: value must be greater than 0`

If startup account discovery cannot extract `account_id_v2`, cannot find a
`game_id = 2` entry, or otherwise cannot resolve the Genshin account, the
application shall not start Daily Note polling.

### FR-12 Resin Waste Tracking

The application shall compare the latest successful snapshot against in-memory
tracking data collected during the current app session to estimate when natural
recovery first reached the cap and how much resin has been wasted since that
time.

If the application does not have enough prior state to calculate a reliable
overflow start time, it shall avoid showing a fabricated waste count.

## Non-Functional Requirements

### NFR-1 Platform

The application shall run as a macOS application and align with the repository's
current Xcode project settings.

### NFR-2 Minimal Launch Experience

The application shall not require an ordinary content window to be opened on
launch in order to deliver its primary function.

### NFR-3 Local-Only State

Version 1 shall operate entirely with local configuration, local caching, and
the external HoYoLAB read API. No additional backend service is in scope.

### NFR-4 Derived Accuracy Model

Resin estimates between fetches may be derived locally from the known recovery
rule of 1 resin per 8 minutes. The application shall never present a derived
value as more authoritative than the last successful server snapshot when the
required baseline is missing.

## Constraints

- The integration depends on the HoYoLAB Daily Note endpoint remaining
  available.
- The integration depends on the HoYoLAB game record card endpoint remaining
  available.
- The application must use a user-supplied cookie rather than an embedded login
  flow.
- The natural recovery rule is fixed at 1 resin every 8 minutes for version 1.
- The cookie must include `account_id_v2` so the app can resolve the Genshin
  account on startup.

## Assumptions

- A single account is sufficient for the first release.
- A fixed 10-minute polling interval is acceptable for version 1.
- Users are willing to paste the full cookie manually.
- The Daily Note payload fields used in the draft spec remain available.

## Acceptance Criteria

- With no saved configuration, the menu bar shows a configuration-needed state.
- With a valid cookie, startup account discovery resolves the Genshin account
  automatically before Daily Note polling begins.
- With a valid configuration and a successful response below cap, the menu bar
  shows `{current resin} / {max resin}` with a resin icon.
- With an expired or invalid cookie, the menu bar shows an authentication error
  state.
- Clicking the menu bar entry opens a panel that exposes formatted Daily Note
  data plus Preferences and Quit actions.
- When expedition data is available, the main panel shows each expedition
  separately instead of only an aggregate expedition count.
- Resin waste is only shown when the application has enough data to support the
  estimate.
- Configuration survives application relaunch.
- Resin tracking restarts from fresh app-session data after relaunch.

## Unresolved Items

- The exact set and ordering of Daily Note fields shown in the main panel still
  needs a UI-level decision.
- The precise wording and iconography for configuration and authentication error
  states still need product copy review.
