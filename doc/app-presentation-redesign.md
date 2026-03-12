# AppPresentation Redesign

## Document Status

- Status: Proposed
- Last updated: 2026-03-13
- Related requirements: `doc/spec.md`
- Related baseline design: `doc/design.md`

## Background

`AppPresentation` currently exposes the main-panel body as a flat `fields`
array. That shape was sufficient for the first shipped panel, but it now forces
the view to treat primary resin status, account identity, and routine progress
as the same kind of key-value row.

Current implementation costs:

- Primary resin status and secondary routine data share the same presentation
  shape.
- `ContentView` can only render a single stacked list, so grouping depends on
  row order instead of explicit structure.
- `DailyNoteService` and `DailyNoteSnapshot` currently discard `expeditions[]`,
  so the panel cannot render per-character expedition timing even if the layout
  changes.
- Unit tests assert the presence of field IDs instead of the semantic sections
  that the panel is meant to communicate.
- Future UI changes such as cards, grouped blocks, or conditional sub-sections
  would keep leaking layout rules into the view.

## Design Goals

- Replace the generic field list with a presentation model that matches the
  panel's information hierarchy.
- Keep `AppState` and `AppPresentationBuilder` responsible for state
  interpretation while leaving SwiftUI views responsible only for rendering.
- Preserve the ability to show cached snapshot data during auth or request
  failures without flattening it into a single list.
- Make the model specific enough that tests can verify semantic structure
  rather than stringly ordered rows.
- Preserve expedition item detail from the HoYoLAB payload so the panel can
  render one row per character with remaining time or completion state.

## Proposed Presentation Model

`AppPresentation` should keep `menuBarState` for the menu bar label, but the
panel payload should move from top-level `fields` to a typed panel model:

- `statusHeader`
  - `title`
  - `message`
  - `symbolName`
- `lastRefreshText`
- `panel`
  - required `hero` when a snapshot exists
  - `summaryMetrics`
  - optional `expeditions`

To support expedition detail display, the upstream snapshot model also needs to
retain expedition items instead of only the aggregate expedition counts.

The redesign intentionally removes the top-level catch-all `PanelField` list.
Repeated rows are still allowed inside a typed section, but section membership
must carry the meaning instead of forcing the view to infer it from order.

### `StatusHeader`

`StatusHeader` continues to describe the current app status for all states:

- configuration needed
- loading or refresh in progress
- ready below cap
- ready in overflow
- authentication failure
- non-auth request failure

This keeps menu bar state and panel header copy aligned while letting the rest
of the panel stay focused on snapshot content.

The current account context should stay in the header message instead of
becoming its own visual block. The user's preferred layout keeps the account
line close to the status heading and leaves the body focused on actionable
numbers.

### `HeroSummary`

`HeroSummary` is the primary information block for the panel and should exist
whenever the app has a snapshot to show.

Recommended shape:

- `resin`
  - `title`
  - `value`
  - optional `detail`
- optional `waste`
  - `title`
  - `value`
  - optional `detail`

Mapping rules:

- `resin` is always the primary metric and should show the derived current value
  against max resin.
- `waste` appears only when overflow timing is known.
- Overflow does not replace resin. The panel should show resin as the stable
  primary metric and add waste as a warning highlight.

### `SummaryMetrics`

`SummaryMetrics` is the compact fact block that sits below the resin hero.
Instead of splitting the remaining data into multiple titled cards, the next
iteration should render a single ordered list:

- Discount Runs
- Daily Tasks
- Bonus Reward
- Home Coin

Recommended item shape:

- `id`
- `label`
- `value`

This block should stay intentionally compact and ordered. The value of the
redesign is not more headings, but a clearer split between hero status,
supporting metrics, and expedition timelines.

### `ExpeditionsSection`

`ExpeditionsSection` is a dedicated list below the summary metrics. It should
show a heading with the aggregate count and then one row per expedition
character.

Recommended section shape:

- `title`
- `currentCount`
- `maxCount`
- `items`

Recommended expedition item shape:

- `id`
- `characterIdentity`
- `statusText`
- optional `remainingTimeText`
- `isComplete`

`characterIdentity` should be derived from expedition-specific data rather than
from list ordering. The current draft payload only guarantees
`avatarSideIcon`, `status`, and `remainedTime`, so the design should prefer the
avatar-based identity and may add a fallback label only when a stable name is
not available.

## Expedition Timeline Display

The expedition area should render one item per character instead of a single
`current / max` summary row, with a header such as `Expeditions 3/5`.

Required upstream data:

- `avatarSideIcon`
- `status`
- `remainedTime`

Display rules:

- Ongoing expeditions show the character identity and remaining time.
- Finished expeditions show the character identity and a completed state instead
  of a countdown.
- The aggregated expedition count may still appear in summary copy, but it must
  not replace the per-character rows.

Implementation impact:

- Extend `DailyNotePayload` to decode `expeditions[]`.
- Extend `DailyNoteSnapshot` to persist expedition entries for cached-panel
  rendering and restore.
- Add representative fixtures for non-empty expedition arrays so presentation
  and decoding tests cover the detailed section.

## Layout Mapping

`ContentView` should render the panel in this order:

1. status header
2. last successful refresh label when available
3. hero summary card
4. summary metrics block
5. expeditions section when expedition data exists
6. Preferences and Quit footer

This ordering keeps resin or overflow status visually dominant, keeps the
supporting metrics compact, and gives expedition timelines a stable dedicated
area.

## State Behavior

- No snapshot available: omit `panel` entirely and show only the status header
  plus any refresh metadata.
- Ready with snapshot: show `hero`, the compact summary metrics block, and the
  expedition section when expedition data exists.
- Auth or request failure with cached snapshot: keep the latest successful
  `panel` content visible, but let `statusHeader` communicate the current
  failure.
- Auth or request failure without cached snapshot: omit `panel` and show only
  failure messaging.

## Testing Impact

The redesign should move tests from field-presence assertions toward semantic
coverage:

- `AppPresentationTests` should assert hero content, section kinds, and section
  row values.
- `DailyNoteServiceTests` and snapshot persistence tests should cover decoding
  and restoring non-empty expedition item arrays.
- UI tests should target semantic accessibility identifiers such as hero or
  section containers instead of `content.field.*`, including per-expedition
  rows.

## Non-Goals

- Changing the menu bar label state model.
- Adding new HoYoLAB data beyond the fields already shipped in version 1.
- Reworking Preferences or footer actions.

## Markdown Mock

The current intended shape is:

```md
## Daily Note Ready
Current account: Traveler on os_asia

_Last Successful Refresh: Mar 13, 2026 at 10:20_

### Resin
**157 / 200**

---

- Discount Runs: 2 / 3
- Daily Tasks: 3 / 4
- Bonus Reward: Pending
- Home Coin: 1800 / 2400

---

Expeditions 3/5
- Character A: 00:18 remaining
- Character B: 01:42 remaining
- Character C: Completed
```
