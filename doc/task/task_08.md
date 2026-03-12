# Task 08 - Redesign AppPresentation around semantic sections and expedition timelines

## Priority

P1

## Goal

Replace the flat `AppPresentation.fields` list with a semantic panel
presentation model that exposes primary resin status, optional overflow waste,
header-level account context, a compact metrics block, and per-character
expedition remaining time.

## Scope

- Replace `AppPresentation.PanelField` and the top-level `fields` array with
  the typed panel structure defined in `doc/app-presentation-redesign.md`.
- Extend the Daily Note decoding and cached snapshot model so expedition items
  are preserved as character-specific presentation data instead of collapsing
  them to counts only.
- Update `AppPresentationBuilder` to map ready, loading, auth-error, and
  request-error states into `statusHeader`, `hero`, a compact ordered metrics
  block, and a per-character expedition section.
- Refactor `ContentView` to render a hero summary and grouped section blocks
  instead of one generic key-value loop, keeping account context in the header
  and showing expedition rows with remaining time or completion state.
- Update unit and UI tests so they assert semantic structure and the new
  accessibility identifiers rather than `content.field.*`.

## Acceptance Criteria

- `AppPresentation` no longer exposes a top-level generic `fields` list.
- When a snapshot exists, the main panel shows a resin hero summary and keeps
  estimated waste as a separate overflow highlight instead of flattening both
  into one list.
- The main panel keeps account context in the header message and renders the
  supporting Daily Note values as one compact metrics block in the approved
  order: Discount Runs, Daily Tasks, Bonus Reward, Home Coin.
- When expedition data is available, the panel shows one expedition entry per
  character with remaining time or completion state instead of only an
  aggregate expedition count, under an `Expeditions n/n` heading.
- Auth and request failures keep rendering the last successful grouped panel
  content when cached data exists, while the header communicates the active
  failure state.
- Automated tests cover the new presentation structure and semantic
  accessibility hooks, including decoded and restored expedition detail data.

## Out of Scope

- Changing menu bar label states or menu bar text.
- Adding new Daily Note payload fields beyond the currently shipped set.
- Reworking Preferences, Quit actions, or app-level navigation.

## Implementation Notes

- Keep the top-level panel model strongly typed; lightweight row arrays are
  acceptable only inside a typed section.
- Preserve the current snapshot-derived values unless the redesign explicitly
  changes their grouping or visual emphasis.
- Prefer stable section ordering from the design note instead of deriving order
  from API field insertion order.
- The current sanitized live evidence only shows an empty `expeditions` array,
  so add or refresh redacted fixtures with non-empty expedition data before
  calling the task verified.

## Verification

- `xcodebuild test -scheme NotEnoughResins -destination 'platform=macOS' CODE_SIGNING_ALLOWED=NO CODE_SIGN_IDENTITY=-`
- Manual: exercise ready, overflow, and auth-error or request-error states and
  confirm the panel shows the hero summary, compact metrics block, and
  per-character expedition timing instead of a flat field list.
- `markdownlint-cli2 "doc/**/*.md" --config ~/.markdownlint-cli2.jsonc`

## References

- `doc/spec.md` FR-9
- `doc/spec.md` Acceptance Criteria / Clicking the menu bar entry opens a panel
  that exposes formatted Daily Note data plus Preferences and Quit actions
- `doc/design.md` UI Design / Main Panel
- `doc/design.md` Error Handling Policy
- `doc/spec.md` Acceptance Criteria / When expedition data is available, the
  main panel shows each expedition separately instead of only an aggregate
  expedition count
- `doc/app-presentation-redesign.md`
