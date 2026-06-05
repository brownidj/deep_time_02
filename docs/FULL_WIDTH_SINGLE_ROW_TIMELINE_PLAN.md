# Full-Width Single-Row Timeline Plan

## Goal
Implement a full-width geological timeline layout that follows the reference image structure, but for this phase:
- Ignore representational life rows.
- Use one continuous horizontal row (no wrapped second strip).
- Treat `Carboniferous > Mississippian` and `Carboniferous > Pennsylvanian` as directly adjacent in the same row.

## Scope For This Iteration
- Replace the current two-panel list/detail UI with a timeline-first screen.
- Render a single continuous time row across the available screen width.
- Keep hierarchy visible through block styling/labels (period + epoch context), but do not add image tiles or life illustrations.
- Preserve existing data source (`time_divisions.yaml` via SQLite seeding/repositories).

## Data Strategy
1. Load all divisions from `TimelineService`.
2. Filter to relevant ranks:
- `period` as primary row segments.
- `epoch` as optional child labels/overlays inside each period segment.
3. Build a chronological continuous sequence by `startMa` descending (older -> younger from left to right).
4. For Carboniferous, use its epoch children as contiguous subsegments so `Mississippian` is directly followed by `Pennsylvanian` in the same horizontal strip.

## Layout Strategy (Full Width)
1. Use `LayoutBuilder` to get viewport width.
2. Compute timeline domain:
- `maxStartMa` = oldest division shown.
- `minEndMa` = youngest end boundary shown.
- `totalDuration = maxStartMa - minEndMa`.
3. Convert each segment to pixel geometry:
- `segmentWidth = (duration / totalDuration) * availableWidth`.
- Place segments sequentially without line wraps.
4. If labels become unreadable at narrow widths, apply fallback:
- Hide secondary labels first (epoch text).
- Keep primary period labels visible.
- Add tooltip on hover/tap for hidden text.

## UI Composition
1. `TimelineScreen` becomes single-purpose timeline page.
2. Add widgets:
- `TimelineCanvas` (overall width math + row orchestration).
- `TimelineRow` (continuous segment row).
- `TimelineSegment` (single block with label + styling).
3. Remove/disable current `DivisionList` + `PaleontologyPanel` for this layout pass.

## Interaction (Minimal, Phase 1)
- Tap/click segment to mark selection.
- Show a compact details strip above or below row:
- name, rank, `startMa-endMa`, duration.

## Implementation Steps
1. Create a timeline layout helper to:
- sort divisions,
- derive contiguous segment list,
- map time values to pixel widths.
2. Implement new timeline widgets and integrate into `TimelineScreen`.
3. Add Carboniferous continuity rule using epoch children (`Mississippian` then `Pennsylvanian`) in the same row.
4. Apply responsive label fallback for narrow windows.
5. Keep existing selection state wiring, but bind it to timeline segment taps.
6. Remove unused split-view imports/usages.

## Acceptance Criteria
- Timeline occupies full available content width.
- No second wrapped band is used for continuation.
- `Mississippian` and `Pennsylvanian` appear as adjacent segments in one continuous row.
- Representational life rows are not rendered.
- App runs with no analyzer errors.

## Validation Checklist
1. Run `flutter analyze`.
2. Run `flutter test`.
3. Manual visual check at:
- desktop wide window,
- medium width window,
- narrow width (label fallback behavior).
