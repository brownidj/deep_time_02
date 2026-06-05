# Cladistics Column Implementation Plan

## Purpose

The `Clades` column should use the horizontal space from the right-hand edge of `Events` to the rightmost usable extent of the screen. This space is not large enough for a comprehensive tree of life, so the goal is to show a curated, educational cladistic view that follows geological time from earliest to latest and reveals branching at appropriate dates.

The app should treat this as a readable biological map over geological time, not as a full taxonomic database.

## Design Goals

- Use geological time as the vertical axis, matching the rest of the timeline.
- Draw cladistic branching from earliest to latest: older divergences higher, younger branches lower.
- Show only the level of biological detail that fits the available screen space.
- Preserve the current timeline as the main structural context.
- Prefer curated, high-value clades over comprehensive coverage.
- Make local detail available through zoom, focus, and spotlight interactions.
- Keep the data model extensible enough to support richer cladistics later.

## Non-Goals

- Do not attempt a complete tree of life.
- Do not render every named clade in `data/clades.yaml` simultaneously.
- Do not require users to understand formal rank hierarchy before the view is useful.
- Do not replace the existing representative clade filtering/search system.
- Do not encode contentious phylogenetic uncertainty as if it were precise.

## Existing State

The current vertical clade renderer uses packed vertical range bars in `lib/ui/screens/timeline/timeline_vertical_columns_clades.dart`. That works for "which clades existed when", but it does not communicate cladistic branching.

Existing supporting data already includes:

- `data/clades.yaml`
- `data/clade_display_groups.yaml`
- `data/clade_representative_ids.yaml`
- `Clade`
- `CladeVisibilityResolver`
- search/spotlight behavior
- representative/category modes

The next step should build on these rather than replacing them.

## Proposed Visual Model

The `Clades` column becomes a constrained cladogram canvas:

```text
Events | Clades canvas
       |
       |  ancestral line
       |      |
       |      +-- branch A
       |      |
       |      +------ branch B
       |             |
       |             +-- branch C
       |
       v time: older at top, younger at bottom
```

Time remains vertical:

- top = oldest visible time
- bottom = youngest visible time
- branch split Y = estimated divergence/origination date
- clade range continues downward from its origin to extinction or present

Horizontal placement is semantic, not chronological:

- left side of the clade canvas carries older/root lineages
- rightward movement expresses branching/detail
- sibling branches receive separate lanes
- denser local areas can expand with local zoom

## Display Scope

At default whole-timeline scale, show only a representative backbone:

- early life / cellular life
- eukaryotes
- animals
- plants
- arthropods
- vertebrates
- tetrapods
- amniotes
- synapsids / mammals
- sauropsids / reptiles / dinosaurs / birds
- angiosperms
- primates / hominins where relevant

At narrower time windows, reveal more detail:

| View scale | Cladistic detail |
|---|---|
| Whole timeline | High-level backbone only |
| Phanerozoic | Major animal, plant, and vertebrate branches |
| Era | Key branches relevant to that era |
| Period | More specific subclades and iconic lineages |
| Local focus | Selected branch neighborhood and representative taxa |

## Data Model Extensions

The existing `Clade` model has enough information for range bars, but a branching view needs explicit parent/child and divergence metadata.

Recommended additions to `data/clades.yaml`:

```yaml
- id: tetrapoda
  label: Tetrapods
  parent_id: sarcopterygii
  start_ma: 390
  end_ma: 0
  divergence_ma: 390
  branch_priority: 20
  cladistic_role: backbone
  uncertainty: approximate
```

Fields:

| Field | Purpose |
|---|---|
| `parent_id` | Scientific parent used for tree edges |
| `divergence_ma` | Y position of the split from parent |
| `branch_priority` | Layout/filter priority independent of display priority |
| `cladistic_role` | `backbone`, `major_branch`, `detail`, `representative_taxon` |
| `uncertainty` | `high`, `moderate`, `approximate`, `debated` |

Use `start_ma` as a fallback for `divergence_ma` when no better value exists.

## Layout Algorithm

Build a dedicated layout service rather than embedding tree logic in widgets.

Suggested service:

```text
CladisticLayoutService
  input:
    clades
    visibleStartMa
    visibleEndMa
    canvasWidth
    canvasHeight
    zoomLevel
    selectedCladeId
    displayGroupId

  output:
    nodes
    branchSegments
    labels
    hitTargets
```

Core steps:

1. Filter clades to visible time range.
2. Apply representative/category/search mode.
3. Build parent-child relationships.
4. Keep required ancestors for visible descendants.
5. Rank by `branch_priority`, `display_priority`, and local relevance.
6. Allocate horizontal lanes from root to leaves.
7. Map `divergence_ma` to Y using the existing timeline mapper.
8. Draw parent vertical stems and child horizontal branch connectors.
9. Place labels only where they fit; otherwise use hover/selection detail.

## Branch Rendering Rules

Use three primitive shapes:

- vertical lineage segment: clade persists through time
- horizontal branch segment: split from parent to child lane
- label chip or rotated label: clade name, only when space permits

Rules:

- Branches should never imply more precision than the data supports.
- Approximate or debated dates should use softer/dashed branch junctions.
- Extinct clades end at `end_ma`.
- Living clades continue to `0 Ma`.
- Selected clade path should highlight ancestors and direct descendants.
- Non-selected branches can dim during spotlight mode.

## Smart Use of Space

The clade canvas must be adaptive because width varies with window size.

Use these strategies:

- **Backbone compression:** always reserve lanes for a small number of trunk lineages.
- **Branch bundling:** collapse closely related detail into one labelled group until zoomed.
- **Local zoom:** when a branch is selected, expand its neighborhood horizontally while compressing unrelated branches.
- **Focus path:** highlight the selected clade's ancestry from root to selected node.
- **Progressive labels:** show labels based on available height/width; move detail into tooltips/panels when crowded.
- **Priority culling:** if labels or branches collide, drop lower-priority detail first.
- **Micro-branch ticks:** for dense areas, show small split ticks without full labels until zoom/focus.

## Local Zoom Design

Local zoom should not require changing the whole timeline scale.

Suggested behavior:

- Click/spotlight a clade to expand its subtree within the clade canvas.
- Keep the main time axis unchanged.
- Allocate more horizontal width to selected clade descendants.
- Keep ancestors visible as a highlighted path.
- Collapse unrelated sibling branches into compact summary lanes.

Example:

```text
Before focus:
Amniota
  +-- Synapsida
  +-- Sauropsida

After focusing Sauropsida:
Amniota
  +-- Synapsida (collapsed)
  +-- Sauropsida
        +-- Lepidosauria
        +-- Archosauria
              +-- Crocodylomorpha
              +-- Dinosauria
                    +-- Aves
```

## Initial Curated Backbone

Start with a limited set rather than attempting coverage.

Suggested first implementation set:

```text
Life
  Bacteria / Cyanobacteria
  Eukaryota
    Plants
      Vascular plants
      Seed plants
      Angiosperms
    Animals
      Arthropods
        Trilobites
      Chordates
        Vertebrates
          Jawed vertebrates
          Lobe-finned fish
          Tetrapods
            Amphibians
            Amniotes
              Synapsids
                Mammals
                  Primates
                    Hominins
              Sauropsids
                Dinosaurs
                  Birds
```

This is intentionally incomplete. It is a display backbone for teaching and navigation.

## Interaction

Recommended interactions:

- hover: show date/range summary
- click: spotlight clade and highlight ancestry path
- long press / secondary click: detail panel
- search result: focus selected clade
- category filter: reduce visible branches
- local zoom control: expand selected subtree

Detail panel should include:

- label
- rank
- age range
- divergence date
- parent clade
- immediate children
- representative taxa
- short description
- uncertainty note

## Implementation Phases

### Phase 1: Data Audit

- Audit `data/clades.yaml` for reliable `parent_id` coverage.
- Add `divergence_ma` where start date is not sufficient.
- Add `branch_priority` and `cladistic_role`.
- Add validation tests for parent IDs and date consistency.

### Phase 2: Layout Model

Create pure Dart layout types:

```text
CladisticNodeLayout
CladisticBranchLayout
CladisticLabelLayout
CladisticLayoutSnapshot
```

Keep this testable without Flutter widgets.

### Phase 3: Layout Service

Implement `CladisticLayoutService`:

- filter visible clades
- retain ancestors
- assign lanes
- generate branch segments
- avoid collisions
- return a render-ready snapshot

### Phase 4: First Renderer

Replace the packed range-bar view inside the `Clades` column with:

- branch lines
- selected path highlighting
- minimal labels
- empty/loading states

Keep existing search and representative/category modes wired.

### Phase 5: Local Zoom

Add selected-subtree expansion:

- focus selected clade
- expand descendants
- dim/collapse unrelated branches
- preserve current geological scroll position

### Phase 6: Label Policy

Add deterministic label rules:

- always label selected clade
- label major backbone clades if space permits
- hide lower-priority labels before hiding branch geometry
- use tooltip/detail panel for hidden labels

### Phase 7: Tests

Add tests for:

- parent-child graph construction
- missing/invalid parent IDs
- date validity (`parent.divergence_ma >= child.divergence_ma` where applicable)
- visible range filtering
- ancestor retention
- lane assignment stability
- local zoom expansion
- selected path highlighting
- label collision policy

## Technical Notes

- Use existing `TimelineRangeMapper` or a shared vertical Ma mapper for Y coordinates.
- Do not put tree layout state in widget build methods.
- Keep layout deterministic so tests can assert lane positions.
- Continue to use `CladeVisibilityResolver`, but split range visibility from cladistic layout decisions if needed.
- Avoid global panning inside the clade column at first; use existing vertical scroll.

## Open Questions

- Should the root line begin at earliest known life or at the oldest visible clade?
- Should uncertain branches use dashed lines, translucency, or both?
- Should local zoom be triggered by clade click or by a separate focus button?
- How many simultaneous branches should the default view allow on common laptop widths?
- Should the `Land masses`/`RLife` columns influence clade color choices, or should cladistics use its own palette?

## Recommended First Milestone

Implement a static backbone cladogram for representative clades only:

- no local zoom
- no full collision solver
- no hundreds of clades
- no exhaustive tree

Deliverable:

```text
Events | Clades
       | rooted backbone branches
       | major labels only
       | click highlights ancestry path
```

Once this is stable, add local zoom and richer branch detail.
