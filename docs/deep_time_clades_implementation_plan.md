# Deep Time: Clades Implementation Plan

This document outlines a staged approach for adding clades to the `Deep Time 2` desktop app without overwhelming the user. The main idea is to treat clades as a separate biological layer plotted onto the geological timescale, rather than embedding clades directly into periods, epochs, or stages.

For the newer plan to use the full right-side `Clades` column as a constrained cladistic branching canvas, see `docs/cladistics_column_implementation_plan.md`. That document supersedes the older "horizontal range bar" assumption for the vertical timeline column while keeping the data-first and progressive-disclosure principles from this plan.

## 1. Core design principle

The geological timescale should remain the structural framework of the app. Clades should be a biological overlay.

```text
Geological time divisions = the timeline framework
Clades = biological ranges plotted onto that framework
Events = point or boundary markers plotted onto that framework
```

This distinction matters because a clade may cross many geological boundaries. For example, ammonoids range from the Devonian to the end-Cretaceous, mammals begin in the Mesozoic and continue to the present, and flowering plants appear in the Cretaceous but become increasingly important later.

Do not bake clades into periods, epochs, or stages directly. Instead, store their own start and end dates in millions of years ago.

## 2. Recommended new data file

The app already has data files such as:

```text
data/time_divisions.yaml
data/timeline_markers.yaml
```

Add a new file:

```text
data/clades.yaml
```

Then add it to `pubspec.yaml` under Flutter assets:

```yaml
flutter:
  assets:
    - data/time_divisions.yaml
    - data/timeline_markers.yaml
    - data/clades.yaml
```

## 3. First clade data model

Start with a simple, practical schema. Avoid building a full tree-of-life system immediately.

Example:

```yaml
- id: trilobita
  label: Trilobites
  scientific_rank: class
  parent_id: arthropoda
  start_ma: 521
  end_ma: 252
  range_note: Cambrian to end-Permian
  confidence: approximate
  display_groups:
    - marine_invertebrates
    - paleozoic_life
  display_priority: 15
  min_zoom_level: period
  short_description: Marine arthropods that were especially abundant during the Paleozoic.
  representative_taxa:
    - Olenellus
    - Elrathia
    - Phacops
  tags:
    - marine
    - arthropod
    - Paleozoic
    - index fossils
```

Another example:

```yaml
- id: ammonoidea
  label: Ammonoids
  scientific_rank: subclass
  parent_id: cephalopoda
  start_ma: 409
  end_ma: 66
  range_note: Devonian to K-Pg boundary
  confidence: approximate
  display_groups:
    - marine_invertebrates
    - mesozoic_life
  display_priority: 20
  min_zoom_level: period
  short_description: Externally shelled cephalopods, especially important as Mesozoic index fossils.
  representative_taxa:
    - Goniatites
    - Ceratites
    - Ammonites
  extinction_note: Extinct at the K-Pg boundary.
  tags:
    - marine
    - cephalopod
    - index fossils
    - extinction
```

For living clades, use `end_ma: 0` rather than `null`, because it makes timeline rendering easier.

Example:

```yaml
- id: mammalia
  label: Mammals
  scientific_rank: class
  parent_id: synapsida
  start_ma: 225
  end_ma: 0
  range_note: Late Triassic to present
  confidence: approximate
  display_groups:
    - mammals_birds
    - cenozoic_life
  display_priority: 10
  min_zoom_level: era
  short_description: Endothermic vertebrates characterised by hair, mammary glands, and specialised teeth.
  tags:
    - vertebrate
    - mammal
    - living clade
```

## 4. Distinguish scientific hierarchy from display grouping

The scientific hierarchy and the user-facing display grouping should not be treated as the same thing.

For example, whales are mammals scientifically, but in a user interface they may also belong to **Marine life** and **Cenozoic life**.

Use `parent_id` for scientific relationship:

```yaml
parent_id: mammalia
```

Use `display_groups` for app presentation:

```yaml
display_groups:
  - mammals_birds
  - marine_life
  - cenozoic_life
```

This makes the app flexible. One clade can appear in several contexts without duplicating the data.

## 5. Suggested display groups

Use a small number of user-facing groups. These are not formal taxonomic ranks; they are navigation categories for ordinary users.

Recommendation (scalability): **do not hard-code display groups**. Store them in a data file so the UI can load, localise, and extend them without code changes.

Suggested new file:

```text
data/clade_display_groups.yaml
```

Implementation note: add app wiring for this file in `AppDependencies` via a `YamlCladeDisplayGroupRepository`, so UI features can fetch display groups without hard-coded lists.

| Display group | Purpose |
|---|---|
| `early_life` | Microbes, eukaryotes, Ediacaran life |
| `marine_invertebrates` | Trilobites, brachiopods, ammonoids, crinoids |
| `fish_early_vertebrates` | Jawless fish, placoderms, sharks, lobe-finned fish |
| `plants` | Land plants, ferns, seed plants, conifers, flowering plants, grasses |
| `terrestrial_vertebrates` | Amphibians, synapsids, reptiles, tetrapods |
| `dinosaurs_mesozoic_reptiles` | Dinosaurs, pterosaurs, marine reptiles |
| `mammals_birds` | Mammals, birds, whales, horses, primates |
| `human_evolution_ice_age` | Hominins, Homo sapiens, megafauna |

User-facing labels can be friendlier:

| Internal key | UI label |
|---|---|
| `early_life` | Early life |
| `marine_invertebrates` | Marine invertebrates |
| `fish_early_vertebrates` | Fish & early vertebrates |
| `plants` | Plants |
| `terrestrial_vertebrates` | Terrestrial vertebrates |
| `dinosaurs_mesozoic_reptiles` | Dinosaurs & Mesozoic reptiles |
| `mammals_birds` | Mammals & birds |
| `human_evolution_ice_age` | Human evolution & Ice Age life |

## 6. Do not overwhelm the user

There are far too many clades to show as one giant catalogue. The app should use progressive disclosure.

Use four levels of visibility:

1. Default representative clades.
2. Category filters.
3. Zoom-dependent detail.
4. Search and spotlight mode.

Note for first-degree university students: default to a small, representative set with clear, friendly labels and short descriptions. Avoid dense taxonomic lists until the user explicitly opts in.

## 7. Default view: representative clades

The default view should show only a curated set of important clades. This is the palaeontology equivalent of showing major landmarks.

Suggested default label:

```text
Life through time
```

or:

```text
Representative clades
```

A good compromise is:

```text
Representative clades
```

with help text:

```text
A clade is a group of organisms descended from a common ancestor.

Implementation (data-first): store the default set in a separate file so it can be curated without code changes.

```text
data/clade_representative_ids.yaml
```

This file should contain a simple list of clade IDs (e.g., `trilobita`, `ammonoidea`, `mammalia`) that are shown by default when the clade layer is enabled.
```

Example default clades across the whole timeline:

| Broad interval | Default clades shown |
|---|---|
| Precambrian | Cyanobacteria, Eukaryotes, Ediacaran biota |
| Cambrian-Ordovician | Trilobites, Brachiopods, Graptolites, Nautiloids |
| Silurian-Devonian | Eurypterids, Jawed fish, First land plants, Tetrapods |
| Carboniferous-Permian | Coal-swamp plants, Amphibians, Synapsids, Early reptiles |
| Triassic-Cretaceous | Dinosaurs, Pterosaurs, Marine reptiles, Ammonites, Mammals, Birds, Flowering plants |
| Cenozoic | Mammals, Whales, Primates, Hominins, Quaternary megafauna |

## 8. Category filters

Add a filter control, probably in the side panel or top toolbar.

Suggested UI:

```text
All | Marine life | Plants | Invertebrates | Vertebrates | Dinosaurs & reptiles | Mammals | Human evolution
```

A more structured version:

```text
Life through time: On / Off

View:
  Representative only
  By category
  Search / spotlight

Category:
  All
  Early life
  Marine invertebrates
  Fish & early vertebrates
  Plants
  Terrestrial vertebrates
  Dinosaurs & Mesozoic reptiles
  Mammals & birds
  Human evolution & Ice Age life
```

Default settings:

```text
Life through time: On
View: Representative only
Category: All
```

This gives the first user experience a calm, curated feel.

## 9. Zoom-dependent detail

The app should show more clades only when the user zooms into a smaller geological interval.

| Zoom level | Clade detail shown |
|---|---|
| Whole Earth history | Only very broad clades and iconic groups |
| Phanerozoic | More major animal and plant clades |
| Era | Major groups relevant to that era |
| Period | More specific groups |
| Epoch / local view | Specialist clades and representative taxa |

Example data fields:

```yaml
- id: dinosauria
  label: Dinosaurs
  display_priority: 10
  min_zoom_level: era

- id: ceratopsia
  label: Ceratopsians
  display_priority: 40
  min_zoom_level: period

- id: triceratops
  label: Triceratops
  display_priority: 80
  min_zoom_level: epoch
```

Broad clades appear early. Detailed subclades appear only when the user is zoomed into the relevant interval.

## 10. Search and spotlight mode

Instead of expecting users to browse hundreds of clades, let them search for a clade and then spotlight it.

Examples:

```text
trilobite
ammonite
mammal
flowering plants
hominin
```

When a user selects a clade, the app should highlight the selected clade bar and optionally dim the others.

Example detail text:

```text
Ammonoids: c. 409-66 Ma
Devonian to end-Cretaceous
Extinct at the K-Pg boundary
```

This gives users access to many clades without forcing all clades onto the screen at once.

## 11. Visual representation

Clades should be rendered as horizontal range bars.

```text
Cambrian       Ordovician      Silurian       Devonian       Carboniferous
|--------------|---------------|--------------|--------------|-------------|

Trilobites     ███████████████████████████████████████████████████
Nautiloids             █████████████████████████████████████████████████████
Eurypterids                         █████████████████████
First forests                                      █████
```

Recommended visual treatment:

| Item type | Visual form |
|---|---|
| Geological divisions | Blocks or bands |
| Mass extinctions | Vertical boundary markers |
| Key events | Point markers or short labels |
| Long events | Horizontal interval bars |
| Clades | Horizontal range bars |

## 12. Layout rule for clade display

The timeline should not try to display every clade at once. It should decide what fits.

Suggested algorithm:

```text
Load all clades
  ↓
Filter by visible time range
  ↓
Filter by selected display group
  ↓
Filter by current zoom level
  ↓
Sort by display_priority
  ↓
Take only the top N that fit comfortably
  ↓
Draw as horizontal bars
```

This allows the data set to grow without destroying the interface.

## 13. Suggested first clade set

Start with 30-40 curated clades, not hundreds.

```text
Cyanobacteria
Eukaryotes
Animals
Ediacaran biota
Trilobites
Brachiopods
Graptolites
Nautiloids
Eurypterids
Ammonoids
Crinoids
Jawless fish
Placoderms
Sharks
Lobe-finned fish
Tetrapods
Vascular plants
Seed plants
Conifers
Ferns
Synapsids
Amphibians
Reptiles
Dinosaurs
Pterosaurs
Marine reptiles
Birds
Mammals
Flowering plants
Whales
Primates
Hominins
Homo sapiens
Quaternary megafauna
```

This set is enough to test data loading, range rendering, filtering, and detail panels.

## 14. Suggested architecture

Keep the architecture layered.

```text
data/clades.yaml
        ↓
domain/clade.dart
domain/clade_range.dart
domain/clade_repository.dart or parser
        ↓
ui/screens/timeline/clade_lane.dart
ui/screens/timeline/clade_bar.dart
        ↓
detail panel / selection state
```

The domain layer should know about clade data:

```dart
class Clade {
  final String id;
  final String label;
  final String scientificRank;
  final String? parentId;
  final double startMa;
  final double endMa;
  final List<String> displayGroups;
  final int displayPriority;
  final String minZoomLevel;
  final String shortDescription;

  const Clade({
    required this.id,
    required this.label,
    required this.scientificRank,
    required this.parentId,
    required this.startMa,
    required this.endMa,
    required this.displayGroups,
    required this.displayPriority,
    required this.minZoomLevel,
    required this.shortDescription,
  });
}
```

The UI layer should decide how to draw the clade. The clade model should not know about Flutter widgets, colours, pixels, screen width, timeline lane height, or selection state.

## 15. Timeline scaling resolver

Create or reuse a resolver that maps geological age to screen position.

Conceptually:

```text
Ma range → x-position range
```

This resolver should be reusable for geological divisions, mass extinction markers, timeline markers, and clade bars. This avoids each UI component inventing its own scaling logic.

## 16. Detail panel

When the user clicks a clade bar, show a detail panel.

Suggested fields:

```text
Label
Scientific rank
Parent clade
Age range
Range note
Short description
Representative taxa
Related extinction event, if any
Tags
```

Example:

```text
Ammonoids
Scientific rank: subclass
Parent clade: Cephalopoda
Range: c. 409-66 Ma
Range note: Devonian to K-Pg boundary
Description: Externally shelled cephalopods, especially important as Mesozoic index fossils.
Representative taxa: Goniatites, Ceratites, Ammonites
Extinction note: Extinct at the K-Pg boundary.
```

The main timeline should answer:

```text
What kinds of life were important at this time?
```

The detail panel can answer:

```text
Where does this clade sit in the tree of life?
```

## 17. Do not start with a full expandable tree

A full taxonomic or cladistic tree is scientifically attractive, but it is a poor first interface for a timeline app.

```text
Eukaryota
  Opisthokonta
    Metazoa
      Bilateria
        Deuterostomia
          Chordata
            Vertebrata
              Gnathostomata
                Osteichthyes
                  Sarcopterygii
                    Tetrapoda
                      Amniota
                        Synapsida
                          Mammalia
```

This belongs in a details panel or later specialist mode, not in the main timeline.

## 18. Staged implementation plan

### Phase 1: Data only

Create `data/clades.yaml` with 30-40 curated clades.

Add `data/clades.yaml` to `pubspec.yaml`.

Add basic validation rules:

```text
Every clade has a unique id
Every clade has a label
start_ma >= end_ma
start_ma and end_ma are non-negative
Living clades use end_ma: 0
Each display group is known
Each min_zoom_level is known
```

### Phase 2: Domain parser

Create a pure Dart parser that loads YAML into `Clade` objects.

Add tests for:

```text
Clades load successfully
Important clades are present
Date ranges are valid
Display groups are valid
Living clades end at 0
Invalid YAML fails clearly
```

### Phase 3: Timeline clade lane

Add an optional clade lane below the geological rows. Render clades as horizontal bars from `start_ma` to `end_ma`.

Do not add filters yet. First prove that clades render correctly.

### Phase 4: Representative-only filter

Render only clades whose priority is high enough for the current zoom level.

Add `display_priority` sorting and a maximum visible count.

Example rule:

```text
Show the top 12 clades that overlap the visible time range.
```

### Phase 5: Display group filter

Add category filtering.

Initial filters:

```text
All
Early life
Marine invertebrates
Fish & early vertebrates
Plants
Terrestrial vertebrates
Dinosaurs & Mesozoic reptiles
Mammals & birds
Human evolution & Ice Age life
```

### Phase 6: Detail interaction

Clicking or selecting a clade bar opens the detail panel. The clade bar should be highlightable. The selected clade can remain highlighted while the user scrolls or zooms.

### Phase 7: Search and spotlight

Add text search over:

```text
label
id
tags
representative_taxa
short_description
```

When a result is selected, highlight that clade and dim unrelated bars.

### Phase 8: Clade hierarchy

Only after the basic timeline works, add parent-child hierarchy.

```text
Vertebrata
  └── Tetrapoda
       └── Amniota
            ├── Synapsida
            └── Sauropsida
```

Keep this out of the main timeline at first. Put it in the detail panel or a later specialist view.

## 19. User experience recommendation

The user should never be forced to understand the entire biological tree at once.

Recommended default:

```text
Representative clades: On
Mode: Representative only
Category: All
```

Then allow the user to move toward complexity:

```text
Representative only → By category → Search / spotlight → Detail panel → Hierarchy
```

This gives scientific depth without overwhelming the user.

## 20. Summary recommendation

Use this hierarchy in the app:

```text
Default timeline:
  Representative clades only

User filter:
  Display groups

Zoom behaviour:
  Reveal more detailed clades

Search:
  Spotlight any clade

Details panel:
  Scientific parent/child hierarchy
```

This approach scales well. The app can begin with 30 curated clades and later expand to hundreds without redesigning the interface.
