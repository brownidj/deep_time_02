# Non-Avian Dinosauria Clades-Only Zoom Plan

## Purpose

This document defines a clades-only implementation plan for a zoomable phylogenetic view, starting with **non-avian Dinosauria** as the first practical scope.

The intent is:

1. Keep the existing broad clade overview as the entry point.
2. Allow the user to click a major clade such as `Dinosauria` and replace the broad view with a zoomed subtree view.
3. Allow repeated zoom-in through lower clades and subclades.
4. Use time-linked clade dates only in the initial broad overview where they add structure.
5. Drop strict time alignment after the user enters a focused subtree view.

This is intentionally **clades only**. It does not include taxonomy mode or hybrid mode.

## Why This Makes Sense

The main problem is screen width.

At whole-tree scale, a broad clade overview is useful, but deep branching detail for Dinosauria cannot fit cleanly in the same canvas. If the app tries to show all detail at once, the result becomes unreadable.

The solution is:

- broad overview first
- subtree replacement on click
- repeated zoom into narrower clade scopes

This allows the app to stay readable while still supporting much richer cladistic detail.

## Scope

### In scope

- Clades-only view
- Zoomable clade subtree view
- Non-avian Dinosauria as the first deep pilot
- Reuse of existing `data/clades.yaml` and current clade UI infrastructure where possible
- Initial overview may use `start_ma` or similar dates to provide broad structure
- Focused subtree views may ignore time alignment and behave as pure cladograms

### Out of scope

- Taxonomy mode
- Hybrid mode
- Mermaid or external tree renderers
- Full tree of life deep zoom in the first pass
- User-added clades in the first implementation
- Automatic OpenTree expansion in the first implementation

## Product Model

Treat the clades experience as two related display modes inside the same biological feature.

### 1. Overview mode

This is the existing large-scale clade view.

Behavior:

- shows major clades across the wider tree
- may use `start_ma` to give the broad cladogram extra structure
- should remain compressed and readable
- should expose obvious zoom-entry clades such as `Dinosauria`
- keeps the current contextual columns intact for now

### 2. Focused subtree mode

This is the zoomed-in clade view after the user clicks a clade.

Behavior:

- replaces the broad overview with a subtree rooted at the selected clade
- can reclaim additional horizontal space from lower-priority left-side columns
- does not need to stay time-aligned
- should prioritize phylogenetic readability over timeline placement
- should support repeated zoom to lower clades

### 3. Focused subtree mode with retained Earth context

The clade view should not become a biologically rich but geologically empty screen.

One of the app's core design intentions is that users should still get at least a rough sense of:

- land
- seas
- palaeo-ecology
- the broad Earth context during the existence of the clade

That means focused subtree mode should not simply remove everything to the left of the clade canvas.

Instead, it should:

- expand the clade canvas aggressively
- compress or collapse lower-priority timeline columns
- preserve a minimal Earth-context strip

This gives the clade tree more room while still keeping the view recognizably part of a Deep Time app.

## First Target: Non-Avian Dinosauria

The first deep subtree should be **non-avian Dinosauria**.

Reason:

- high user interest
- good test for dense branching
- enough existing and curatable clade data
- large enough to prove the zoom model
- bounded enough to avoid trying to solve the full tree of life at once

Important rule:

- first focused dinosaur view should prefer **non-avian dinosauria**
- birds should not dominate the first dinosaur subtree view

That does not require denying the biological relationship. It only means the first curated subtree should optimize for the user expectation of “show me dinosaurs”.

## Proposed Interaction Model

### Entry

In the broad clade overview:

- `Dinosauria` appears as a zoomable clade
- clicking the clade label or a dedicated zoom affordance enters focused subtree mode

### Inside a focused subtree

When the user is inside `Dinosauria`:

- the view is rooted at `Dinosauria`
- only descendants and the necessary internal clade structure are shown
- lower clades can be clicked to zoom further

Example path:

```text
All clades
  -> Dinosauria
  -> Theropoda
  -> Coelurosauria
  -> Tyrannosauroidea
```

### Exit / navigation

The focused view should support:

- back one level
- return to all clades
- visible breadcrumb or root path

Recommended breadcrumb model:

```text
All clades > Dinosauria > Theropoda > Coelurosauria
```

## Data Strategy

## Overview data

The overview can continue to use `data/clades.yaml` as the primary clade backbone.

For the overview:

- retain curated high-value clades
- use `parent_id`
- use `start_ma` as broad structural guidance where available
- do not try to show every descendant

## Focused dinosaur subtree data

The focused dinosaur view needs more depth than the broad overview.

There are two realistic implementation paths:

### Option A: curated expansion in `clades.yaml`

Add deeper dinosaur descendant clades directly into `data/clades.yaml`.

Pros:

- simple
- uses existing load path
- easy to reason about initially

Cons:

- `clades.yaml` will grow quickly
- harder to maintain once many deep subtrees exist

### Option B: curated backbone in YAML plus deep descendant store later

Keep the broad backbone in `clades.yaml`, and later move deeper focused subtrees into SQLite or another detail source.

Pros:

- scales better
- supports future user-added clades better
- cleaner long-term design

Cons:

- more architecture work

Recommendation:

- for the first non-avian dinosaur pilot, use **Option A**
- design the code so the data source can later be swapped to a detail repository

## Time Usage Rules

This is the key design rule.

### In overview mode

Use clade dates where available to add broad structure.

Acceptable uses:

- approximate vertical placement of major origins
- ordering broad clades by `start_ma`
- making older roots visually distinct from younger branches

### In focused subtree mode

Do **not** require strict time-linked layout.

Instead:

- lay out the subtree for readability
- preserve ancestry and branching order
- allow optional small date badges or notes
- do not force all descendant nodes into timeline-aligned positions

Reason:

- deep local cladograms need horizontal and vertical freedom
- users exploring a focused dinosaur subtree are usually asking “how do these groups relate?” more than “exactly where on the geological axis does each node sit?”

This also leaves the time-rich problem for the future **hybrid** mode.

## Width Reallocation and Earth Context

Focused clade mode should be allowed to use more screen width than the broad overview.

However, width reallocation should follow a priority model rather than an all-or-nothing hide/show rule.

### Overview mode

Keep the normal multi-column structure:

- timeline context remains broad
- clades share space with the existing left-side contextual tracks

### Focused subtree mode

The clade canvas should expand by reclaiming width from the left-side tracks.

Recommended behavior:

1. keep the essential geological time framework visible
2. retain a compressed Earth-context strip
3. collapse or hide lower-value contextual columns
4. allocate the recovered width to the cladogram

Current first implementation rule:

- in the initial clades overview, keep all current columns
- in zoomed-in clade views, remove `Representative life` first
- in zoomed-in clade views, remove `Events` next
- defer further column-removal decisions until the interaction can be tested visually

### Recommended Earth-context strip

In focused subtree mode, merge or compress the environmental context into one thin contextual band or column.

That strip should aim to preserve only high-level signals, for example:

- broad land/sea state
- rough palaeo-ecological setting
- major environmental transitions relevant to the focused clade interval

It should not try to preserve the full richness of all original contextual columns.

### What should remain visible in focused subtree mode

- breadcrumb / clade navigation
- clade subtree canvas
- minimal geological context
- compressed Earth-context strip

### What may be compressed or hidden

- low-priority contextual columns that compete for width
- duplicate or weakly informative tracks during subtree exploration

Current first candidates for removal in zoomed-in views:

- `Representative life`
- `Events`

### Design rule

The focused subtree view should feel like:

- a clade-first screen
- still grounded in Deep Time

not:

- a full-width standalone cladogram with no Earth context

## Visual Model

### Overview mode

Use a compressed, broad cladogram:

- major roots visible
- broad branch timing loosely structured by `start_ma`
- large clades act as zoom portals

### Focused subtree mode

Use a true cladogram canvas:

- selected root remains in the current top-down clade view model
- descendants branch within the existing vertical-time canvas
- breadth allocated according to subtree density
- overview-style top-down orientation is preserved
- strict geological vertical mapping can be relaxed inside the focused subtree if needed
- adjacent compressed Earth-context strip remains visible if feasible
- additional horizontal space should be used to reveal a higher number of clades and subclades

Preferred orientation for the focused subtree:

- keep the same top-down vertical orientation as the current clades view

Reason:

- it matches the existing user experience
- it avoids making focused mode feel like a different visualization system
- it lets the user understand focused mode as an expansion of the current view rather than a mode switch
- it reduces orientation-related implementation risk in the first pass

## State Model

Add dedicated clade zoom state.

Recommended model:

```dart
List<String> cladeFocusPath;
```

Semantics:

- empty list = overview mode
- non-empty list = focused subtree mode
- last item = current subtree root

Example:

```dart
[]
['dinosauria']
['dinosauria', 'theropoda']
['dinosauria', 'theropoda', 'coelurosauria']
```

Benefits:

- supports nested zoom naturally
- makes breadcrumb generation trivial
- avoids special-case root state

Derived state:

- `currentCladeRootId = cladeFocusPath.isEmpty ? null : cladeFocusPath.last`

## Layout Model

Use two different layout engines conceptually, even if some code is shared.

### Overview layout engine

Input:

- visible broad clades
- current timeline/time scale
- `start_ma`
- representative priority

Output:

- broad structured clade overview

### Focused subtree layout engine

Input:

- current subtree root
- all descendants of that root
- branch ordering metadata
- optional date annotations

Output:

- readable cladogram layout
- node positions
- branch segments
- labels
- hit targets

The focused engine should not depend on the geological scale mapper.

It may still consume summarized Earth-context data for the compressed context strip.

## Data Model Extensions

To support clean zoom behavior, the clade data should gain a few explicit fields.

Recommended additions:

```yaml
- id: dinosauria
  zoomable: true
  focus_priority: 100
  subtree_layout_hint: cladogram
```

Suggested fields:

| Field | Purpose |
|---|---|
| `zoomable` | whether this clade can become a focused subtree root |
| `focus_priority` | order for preserving important descendants in dense subtree layouts |
| `subtree_layout_hint` | optional mode such as `cladogram`, `ladderized`, `balanced` |
| `preferred_child_order` | optional explicit descendant order for readability |

For the first pass, only `zoomable` is required.

## Rendering Rules

### Overview mode

- show only clades that fit the broad educational overview
- highlight zoomable clades with an affordance
- preserve current selection behavior where reasonable

### Focused subtree mode

- always show the current root clearly
- always show direct descendants if present
- keep ancestor breadcrumb visible
- collapse or defer low-priority descendants if subtree density is too high
- prioritize named internal clades over a flood of terminal tips
- use additional reclaimed width to increase visible cladistic detail where possible

## Initial Non-Avian Dinosauria Curation Plan

The first dinosaur subtree should be curated, not automatic.

Start with a manageable internal structure, for example:

- Dinosauria
- Saurischia
- Ornithischia
- Sauropodomorpha
- Theropoda
- Herrerasauria if retained in current curation
- Neotheropoda
- Coelurosauria
- Tyrannosauroidea
- Maniraptora
- Ornithopoda
- Thyreophora
- Marginocephalia
- Ceratopsia
- Ankylosauria
- Stegosauria
- Sauropoda
- Diplodocoidea
- Macronaria
- Titanosauria

This is enough to prove:

- subtree zoom
- nested drill-down
- deep cladogram rendering
- balance between overview and focused detail

## User-Added Clades

This should not be in the first implementation, but the design should anticipate it.

Long-term user-added clades imply:

- custom node insertion
- evidence capture
- custom parent assignment
- local review/approval state

That is another reason to avoid baking the long-term solution entirely into a single YAML file.

For now:

- keep the focused dinosaur subtree curated
- design the state and rendering model so custom descendants can later attach to a parent clade

## Implementation Phases

## Phase 1: focused clade zoom infrastructure

- add `cladeFocusPath` state
- add breadcrumb/back behavior
- add `zoomable` support in clade data
- scope visible clades by current subtree root
- define which left-side columns remain, collapse, or merge in focused mode
- for the first pass, keep all columns in overview mode
- for the first pass, drop `Representative life` and `Events` in focused mode

Success criteria:

- clicking `Dinosauria` replaces the broad view with a dinosaur-only subtree view
- focused mode clearly allocates more width to clades than overview mode
- some Earth context remains visible in compressed form
- the extra width in focused mode results in visibly more clades and subclades being shown

## Phase 1 File-by-File Checklist

The current code already has a first-generation root-focus mechanism built around `activeCladeRootId`.

For Phase 1, the safest implementation path is:

1. keep using `activeCladeRootId` as the operational root-selection state
2. add the focused-mode layout and column-width behavior around it
3. defer a full `cladeFocusPath` migration until nested zoom is implemented

That means Phase 1 should be implemented as an incremental extension of the current vertical clades pipeline, not a rewrite.

### 1. Screen state and wiring

Files:

- [timeline_screen_state.dart](/Users/david/AndroidStudioProjects/flutter/Deep_Time_2/lib/ui/screens/timeline_screen_state.dart)
- [timeline_screen_clade_detail.dart](/Users/david/AndroidStudioProjects/flutter/Deep_Time_2/lib/ui/screens/timeline_screen_clade_detail.dart)

Tasks:

- keep `String? _activeCladeRootId` as the Phase 1 focus state
- define focused mode as `_activeCladeRootId != null`
- ensure click handling for `Dinosauria` continues to drive root focus through the existing callback path
- add explicit helper getters in state if useful, for example:
  - `bool get _isFocusedCladeMode`
  - `String? get _focusedCladeRootId`
- do not add nested path state yet

Success criteria:

- the screen has one clear source of truth for clade focus
- focused mode can be queried cleanly by downstream widgets

### 2. Header / navigation affordance

Files:

- [timeline_header.dart](/Users/david/AndroidStudioProjects/flutter/Deep_Time_2/lib/ui/screens/timeline/timeline_header.dart)
- [timeline_screen_state.dart](/Users/david/AndroidStudioProjects/flutter/Deep_Time_2/lib/ui/screens/timeline_screen_state.dart)

Tasks:

- add a compact focused-clade indicator when `_activeCladeRootId != null`
- add a `Back to all clades` or equivalent affordance in the header area
- keep this simple for Phase 1; breadcrumb/path UI can stay minimal

Success criteria:

- the user can always tell when they are in focused clade mode
- the user can return to the overview without using an implicit click target

### 3. Column-header labeling

Files:

- [timeline_body_content.dart](/Users/david/AndroidStudioProjects/flutter/Deep_Time_2/lib/ui/screens/timeline/timeline_body_content.dart)
- [timeline_column_headers.dart](/Users/david/AndroidStudioProjects/flutter/Deep_Time_2/lib/ui/screens/timeline/timeline_column_headers.dart)

Tasks:

- when in cladistic overview mode:
  - keep current `Clades` header behavior
- when `_activeCladeRootId != null`:
  - show `Clades: Dinosauria` or the active clade label
- do not change taxonomy header behavior

Success criteria:

- the current biological root of the visible subtree is obvious from the header

### 4. Focus scoping and subtree filtering

Files:

- [timeline_vertical_columns_clades_scope.dart](/Users/david/AndroidStudioProjects/flutter/Deep_Time_2/lib/ui/screens/timeline/timeline_vertical_columns_clades_scope.dart)
- [timeline_vertical_columns_clades_viewport.dart](/Users/david/AndroidStudioProjects/flutter/Deep_Time_2/lib/ui/screens/timeline/timeline_vertical_columns_clades_viewport.dart)
- [timeline_vertical_columns_clades_helpers.dart](/Users/david/AndroidStudioProjects/flutter/Deep_Time_2/lib/ui/screens/timeline/timeline_vertical_columns_clades_helpers.dart)

Tasks:

- keep current subtree scoping via `activeCladeRootId`
- ensure focused mode includes:
  - the root clade
  - descendants of the root
  - only the minimum supporting structure needed for readable labels/connectors
- keep the current “include all zoom levels” behavior in focused mode unless it clearly overloads the view
- tune visible-count heuristics upward when focused mode has more width available

Success criteria:

- clicking `Dinosauria` clearly changes the displayed clade set to a dinosaur-focused subset
- more descendant clades become visible than in overview mode

### 5. Focused-mode width reallocation

Files:

- [timeline_track_widths.dart](/Users/david/AndroidStudioProjects/flutter/Deep_Time_2/lib/ui/screens/timeline/timeline_track_widths.dart)
- [timeline_body_metrics.dart](/Users/david/AndroidStudioProjects/flutter/Deep_Time_2/lib/ui/screens/timeline/timeline_body_metrics.dart)
- [timeline_vertical_columns_tracks.dart](/Users/david/AndroidStudioProjects/flutter/Deep_Time_2/lib/ui/screens/timeline/timeline_vertical_columns_tracks.dart)

Tasks:

- introduce a Phase 1 focused-mode width policy:
  - overview mode: keep all current tracks
  - focused mode: drop `Representative life`
  - focused mode: drop `Events`
- reallocate that width to the `Clades` track
- keep the remaining context tracks intact in this first pass

Success criteria:

- entering focused clade mode visibly expands the `Clades` column
- `Representative life` and `Events` are not rendered in focused mode

### 6. Focused-mode track visibility

Files:

- [timeline_vertical_columns_tracks.dart](/Users/david/AndroidStudioProjects/flutter/Deep_Time_2/lib/ui/screens/timeline/timeline_vertical_columns_tracks.dart)
- [timeline_body.dart](/Users/david/AndroidStudioProjects/flutter/Deep_Time_2/lib/ui/screens/timeline/timeline_body.dart)
- [timeline_body_content.dart](/Users/david/AndroidStudioProjects/flutter/Deep_Time_2/lib/ui/screens/timeline/timeline_body_content.dart)

Tasks:

- add focused-mode-aware track filtering
- preserve:
  - geology/time framework
  - land/sea/context tracks
  - paleo-ecology
  - clades
- hide for Phase 1:
  - `Representative life`
  - `Events`

Success criteria:

- focused mode still feels like Deep Time
- but the clade canvas has materially more horizontal space

### 7. Clade label affordance and click behavior

Files:

- [timeline_vertical_columns_clades_labels.dart](/Users/david/AndroidStudioProjects/flutter/Deep_Time_2/lib/ui/screens/timeline/timeline_vertical_columns_clades_labels.dart)
- [timeline_vertical_columns_clades_widgets.dart](/Users/david/AndroidStudioProjects/flutter/Deep_Time_2/lib/ui/screens/timeline/timeline_vertical_columns_clades_widgets.dart)
- [timeline_vertical_columns_clades_viewport.dart](/Users/david/AndroidStudioProjects/flutter/Deep_Time_2/lib/ui/screens/timeline/timeline_vertical_columns_clades_viewport.dart)

Tasks:

- keep the current top-down visual model
- preserve the existing `+` / `-` root-toggle behavior for Phase 1
- ensure `Dinosauria` is an obvious zoomable clade in overview mode
- ensure active root labeling remains legible when more descendants are shown

Success criteria:

- the user can discover focused clade mode from the clade labels themselves
- the same interaction also supports returning from the focused root

### 8. Focused-mode detail density

Files:

- [timeline_vertical_columns_clades_viewport.dart](/Users/david/AndroidStudioProjects/flutter/Deep_Time_2/lib/ui/screens/timeline/timeline_vertical_columns_clades_viewport.dart)
- [timeline_vertical_columns_clades_layout_helpers.dart](/Users/david/AndroidStudioProjects/flutter/Deep_Time_2/lib/ui/screens/timeline/timeline_vertical_columns_clades_layout_helpers.dart)
- [timeline_vertical_columns_clades_visibility.dart](/Users/david/AndroidStudioProjects/flutter/Deep_Time_2/lib/ui/screens/timeline/timeline_vertical_columns_clades_visibility.dart)

Tasks:

- increase the number of visible clades/subclades when focused mode has more width
- keep collision and overflow rules conservative
- prefer named internal clades and major descendants over a flood of minor tips

Success criteria:

- focused mode shows visibly richer dinosaur detail than overview mode
- the view remains readable rather than merely denser

### 9. Dinosauria data curation for Phase 1

Files:

- [clades.yaml](/Users/david/AndroidStudioProjects/flutter/Deep_Time_2/data/clades.yaml)

Tasks:

- mark `Dinosauria` as a valid focus root if not already implicit
- audit its current descendant coverage
- add the minimum curated non-avian descendant set needed to prove the interaction
- do not try to solve the full dinosaur tree in this phase

Success criteria:

- focused `Dinosauria` view has enough depth to prove subtree exploration is useful

### 10. Tests

Files:

- [timeline_biology_mode_test.dart](/Users/david/AndroidStudioProjects/flutter/Deep_Time_2/test/timeline_biology_mode_test.dart)
- [timeline_row_alignment_test.dart](/Users/david/AndroidStudioProjects/flutter/Deep_Time_2/test/timeline_row_alignment_test.dart)
- new focused-clade test file if needed

Tasks:

- add a test that clicking `Dinosauria` enters focused mode
- add a test that focused mode hides `Representative life` and `Events`
- add a test that focused mode expands the clade track width allocation
- add a test that `Clades: Dinosauria` or equivalent header text appears
- add a test that exiting focused mode restores overview tracks

Success criteria:

- Phase 1 interaction is covered by focused-mode UI tests, not just manual inspection

## Phase 2: non-avian dinosauria curated subtree

- expand dinosaur descendant coverage in `clades.yaml`
- define child order and curation rules
- ensure birds do not dominate the first dinosaur-focused experience

Success criteria:

- Dinosauria view is recognizably richer than overview mode and still readable

## Phase 3: focused cladogram layout engine

- implement subtree-specific layout not tied to geological axis
- add descendant branch rendering
- add label collision control

Success criteria:

- deep dinosaur branches are readable without time-axis compression

## Phase 4: nested zoom

- allow clicking descendant clades to refocus the subtree
- keep breadcrumb and back navigation stable

Success criteria:

- user can move from Dinosauria to narrower subclades repeatedly

## Phase 5: polish and curation controls

- improve focus transitions
- add expand/collapse behavior if necessary
- tune child ordering and label density

Success criteria:

- subtree exploration feels deliberate rather than overloaded

## Key Technical Decisions

1. Use the current broad clade overview as the entry layer.
2. Treat focused subtree mode as a different layout problem from overview mode.
3. Use time-linked clade dates only in the overview.
4. Keep the current top-down clade orientation inside focused subtrees.
5. Preserve a compressed Earth-context strip in focused mode rather than removing all contextual tracks.
6. Start with curated non-avian dinosauria before trying to generalize to all major clades.
7. Keep the data source simple at first, but avoid architecture that assumes YAML is the permanent deep-detail store.

## Risks

### Risk: dinosaur subtree still becomes too dense

Mitigation:

- curate the first subtree aggressively
- defer minor descendants
- use nested zoom instead of showing every tip

### Risk: users expect time alignment inside the focused dinosaur view

Mitigation:

- visually distinguish overview mode from focused subtree mode
- treat focused mode as a cladogram, not a timeline

### Risk: removing left-side columns makes the app lose its Deep Time identity

Mitigation:

- preserve a compressed Earth-context strip
- keep minimal geological context visible
- define explicit focused-mode column-priority rules instead of hiding everything by default

### Risk: clade data becomes too large for YAML

Mitigation:

- accept YAML for the first curated pilot
- keep a later migration path to SQLite/detail repositories

## Recommendation

Proceed with a **non-avian dinosauria clades-only zoom pilot**.

This is the cleanest next step because it:

- uses existing clade work
- matches user expectations
- proves whether subtree replacement is the right interaction model
- avoids prematurely mixing taxonomy and hybrid logic
- keeps the time-aware problem limited to the broad overview where it is useful

If this pilot works, the same mechanism can later support:

- other major clade zoom roots
- user-added clades
- hybrid date overlays
- alternative data backends for deep subtrees
