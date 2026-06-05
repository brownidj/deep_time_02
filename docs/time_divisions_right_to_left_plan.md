# Right-to-Left Time Division Layout Implementation Plan

## Goal
Implement a right-to-left layout algorithm for time-division columns (Age → Epoch → Period → Era → Eon), while keeping all non-time-division columns in their current relative positions. The algorithm must traverse the tree in chronological order (oldest → youngest) at each rank, build blocks with correct heights, and insert empty lower-rank blocks when a parent has no children.

## Scope
- Time-division columns only: Age (Stage), Epoch, Period, Era, Eon.
- Non-time-division columns (Ma, Representative Life, Events, Extinctions, Clades) keep their positions and sizing logic.

## Definitions
- **Chronological order**: oldest → youngest (descending start Ma).
- **Age height**: uniform minimum height required to fit any Age label (based on current text style rules).
- **Empty lower-rank block**: a gap block occupying the same vertical span as the parent block when the parent has no children at the next lower rank.

## Current Code Touchpoints
- Layout snapshot creation: `TimelineLayoutBuilder`.
- Slot-driven segment creation: `TimelineSlotBuilder`, `TimelineRowBuilder`.
- Min-height logic: `timeline_min_height_helpers.dart`.
- Vertical columns rendering: `timeline_vertical_columns.dart`.

## Proposed Approach
Replace the slot-driven segment construction for time-division columns with a right-to-left tree-driven pass that constructs aligned segments and explicit gaps.

### 1. Build a Tree View (chronological order)
- Source: `data/time_divisions.yaml` already loaded into the DB.
- Build a hierarchy from `GeologicDivision` using `parentId`.
- Ensure children per node are sorted by `startMa DESC` (oldest → youngest).

### 2. Compute Uniform Age Height
- Use the existing label measurement logic (the same as `minHeightForStageLabel`), but compute a single max height across all Age labels.
- That max becomes `ageHeight` and is used for every Age block.

### 3. Build Age Column (Rightmost)
- Traverse all Ages in chronological order (oldest → youngest).
- Create `TimelineRowSegment` for each Age with `height = ageHeight`.
- Stack them vertically; record `(startY, endY)` for each Age by cumulative sum.

### 4. Build Epoch Column (to the left of Age)
- Traverse Epochs in chronological order.
- For each Epoch:
  - If it has Ages: height = sum of child Age heights.
  - If it has no Ages: height = min label height for the Epoch; create a single empty Age block of the same height.
  - Align Epoch block to the vertical span of its Age children (or its own height if empty).

### 5. Build Period Column
- Traverse Periods in chronological order.
- For each Period:
  - If it has Epochs: height = sum of child Epoch heights.
  - If no Epochs: height = min Period label height.
    - Insert empty Epoch block of that height.
    - Insert empty Age block of that height.

### 6. Build Era Column
- Traverse Eras in chronological order.
- For each Era:
  - If it has Periods: height = sum of child Period heights.
  - If no Periods: height = min Era label height.
    - Insert empty Period, Epoch, Age blocks of that height.

### 7. Build Eon Column
- Traverse Eons in chronological order.
- For each Eon:
  - If it has Eras: height = sum of child Era heights.
  - If no Eras (e.g., Hadean): height = min Eon label height.
    - Insert empty Era, Period, Epoch, Age blocks of that height.

### 8. Produce Segment Lists
- Replace the current slot-based `buildBandRow/buildRankRow/buildStageRow` for time divisions.
- Instead build `TimelineLayoutSnapshot` time-division segment lists directly from the tree-driven layout pass.
- Each segment should retain `startMa/endMa` for display, but vertical layout should be driven by the computed heights, not by start/end ratios.

### 9. Rendering Alignment
- Use the computed vertical positions to draw boundaries so that columns align on the same horizontal lines across all ranks.
- Preserve the non-time-division columns’ positions; only adjust their vertical extent to match the total time-division column height.

## Testing & Verification
- Add a debug output that prints the right-to-left tree with heights (reuse the existing `scripts/print_time_divisions_tree.py` logic, updated if needed).
- Validate against `docs/time_divisions_tree.md` (structural match).
- Visual check: Archean must show its Era blocks aligned; Hadean must show empty Era/Period/Epoch/Age blocks of the same height as Hadean.

## Notes / Open Questions
- Confirm how to derive min label height for Epoch/Period/Era/Eon (use the existing vertical label measurement functions for vertical ranks, horizontal label for others).
- Confirm whether empty blocks should be tappable (if not, mark `isGap = true`).

