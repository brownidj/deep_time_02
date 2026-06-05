# Vertical Timeline Orientation Plan

## Goal
Reorient the timeline UI from horizontal-time rows to vertical-time columns.

Target result:
- The static rank labels (`Eon`, `Era`, `Period`, `Epoch`, `Stage`, `RLife`, `Events`, `Extinctions`, `Clades`) run across the top as a header row.
- What are currently horizontal rows become vertical columns.
- Time progresses vertically (older at top, younger at bottom).

## Status
Completed through Phase 7 (vertical-first architecture):
- The temporary horizontal timeline rendering path has been removed from `TimelineBodyContent`.
- `TimelineBody` now always builds the vertical timeline canvas.
- Overlay geometry and tests are now vertical-first.

## Scope
- UI orientation and interaction changes only.
- Keep existing data sources, repositories, and layout segment generation.
- Preserve current feature set:
  - band selection,
  - event markers and long-press explanations,
  - extinction markers and long-press explanations,
  - clade lane behavior,
  - clade spotlight/search behavior.

Out of scope for this pass:
- Changing geological/clade data schemas.
- Visual redesign beyond what is required for orientation change.
- Adding new timeline concepts.

## Current Architecture Impact
Primary files impacted:
- `lib/ui/screens/timeline/timeline_body.dart`
- `lib/ui/screens/timeline/timeline_body_content.dart`
- `lib/ui/screens/timeline/timeline_column_headers.dart`
- `lib/ui/screens/timeline/timeline_vertical_columns.dart`
- `lib/ui/screens/timeline/timeline_body_metrics.dart`
- `lib/ui/screens/timeline/timeline_body_metrics_overlay.dart`
- `lib/ui/screens/timeline/timeline_vertical_overlays.dart`

Secondary files:
- Tests under `test/` that assert geometry, labels, marker alignment, and interactions.

## Design Decisions
1. Axis mapping
- Horizontal axis: rank columns.
- Vertical axis: time.

2. Time direction
- Top to bottom: old to young.
- Keep this consistent across bands, rows, markers, and clades.

3. Scroll model
- Main timeline scroll becomes vertical.
- Top rank header is fixed (non-scrolling in Y).
- Column widths are fixed by metrics; no horizontal scroll in normal desktop layouts.

4. Interaction model
- Tap behavior remains the same (select segment/marker/clade).
- Long press remains the trigger for explanation dialogs.

## Implementation Strategy
Use phased migration with a temporary feature flag to prevent a high-risk big-bang cutover.

### Phase 1: Add Orientation Abstraction
1. Introduce a small orientation config model in UI layer (for example `TimelineOrientation.horizontal` and `TimelineOrientation.vertical`).
2. Add geometry helpers in metrics to map:
- unit span -> height (vertical mode),
- cross-axis slot -> x position and width.
3. Keep current horizontal path untouched as default.

Acceptance:
- App behavior unchanged with default horizontal mode.

### Phase 2: Top Header (Replace Left Label Column)
1. Replace `TimelineRowLabels` (left column) with a top header widget (`TimelineColumnHeaders`).
2. Render headers in order:
- Eon, Era, Period, Epoch, Stage, RLife, Events, Extinctions, Clades.
3. Define column widths in `TimelineBodyMetrics` for each rank/track.

Acceptance:
- Header row renders across top, aligned with content columns.

### Phase 3: Rotate Core Content Layout
1. Refactor `TimelineBodyContent` from:
- outer `Row` + inner horizontal scroll + stacked `Column`
to:
- outer `Column` + inner vertical scroll + stacked `Row`.
2. Convert segment rendering widgets to vertical-time geometry:
- `TimelineBandRow` and `ContinuousTimelineRow` become column-oriented renderers (or add parallel vertical widgets first, then remove old names later).
3. Update label orientation rules:
- keep horizontal text where readable,
- allow rotated labels only when necessary.

Acceptance:
- Period/Epoch/Stage and Eon/Era render as vertical-time columns with correct proportional heights.

### Phase 4: Overlay System Conversion
1. Convert overlay math from X-boundaries to Y-boundaries in `TimelineVerticalOverlays`.
2. Replace:
- `periodBoundaryXs`, `eraBoundaryXs`, `eonBoundaryXs`
with
- `periodBoundaryYs`, `eraBoundaryYs`, `eonBoundaryYs`.
3. Update overlay span calculations in `timeline_body_metrics_overlay.dart` to use Y positions.

Acceptance:
- Boundary overlays align with vertical segment boundaries.

### Phase 5: Event and Extinction Marker Conversion
1. Convert `EventPointMarkers` from horizontal-time placement to vertical-time placement:
- line direction, marker anchor position, hit targets.
2. Convert `ExtinctionMarkers` similarly.
3. Preserve long-press explanation behavior and hit target usability.

Acceptance:
- Existing marker interaction tests pass after orientation-aware updates.

### Phase 6: Clade Column Conversion
1. Convert clade lane from horizontal time bars to vertical time bars within the `Clades` column.
2. Keep existing filtering/spotlight logic and only change geometry mapping.
3. Preserve overlap handling and label visibility behavior.

Acceptance:
- Clade bars align with same vertical time scale used by other columns.

### Phase 7: Remove Temporary Horizontal Compatibility Layer
1. Remove dead code paths introduced for transitional dual-orientation support.
2. Rename temporary vertical widget names back to canonical names if needed.
3. Update docs and comments to reflect vertical-first architecture.

Acceptance:
- No unused orientation branches remain.

## Metrics and Geometry Updates
`TimelineBodyMetrics` should become the single source of truth for:
- `headerHeight`,
- per-column widths,
- `scrollHeight` (time axis length),
- per-track top offsets in X (column positions),
- boundary lists in Y.

Recommended additions:
- `timeToY(double unitPosition)`,
- `spanToHeight(double unitSpan)`,
- `columnRectForTrack(TimelineTrack track)`.

## Testing Plan
1. Update existing widget tests to orientation-aware assertions:
- replace left/right boundary assumptions with top/bottom where applicable.
2. Add targeted tests:
- header labels aligned to columns,
- vertical proportional sizing of segments,
- event marker and extinction marker long-press dialog behavior,
- clade bar placement and spotlight behavior.
3. Keep integration smoke test for app flow.

Run gates:
- `flutter analyze`
- `flutter test`

## Risks and Mitigations
1. Risk: Geometry regressions across many widgets.
- Mitigation: centralize all coordinate transforms in `TimelineBodyMetrics`.

2. Risk: Hit target regressions after axis flip.
- Mitigation: add dedicated marker/clade gesture tests and minimum hit-target sizes.

3. Risk: Overlay alignment drift.
- Mitigation: derive overlays from the same computed boundaries as content widgets.

4. Risk: Readability degradation in narrow widths.
- Mitigation: define label fallback rules (truncate/hide secondary labels, keep tooltips/dialog access).

## Completion Criteria
- Top header row replaces left label column.
- Time is vertical and all major tracks render as columns.
- Selection, long-press explanations, clade spotlight/filtering all work.
- Analyzer clean and tests green.
