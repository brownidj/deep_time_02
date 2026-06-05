# Using Open Tree of Life as a Reference for `clades.yaml`

Open Tree of Life could be useful, but it should not be used as a live, full replacement for `clades.yaml` in the app. It is better used as a **reference/build-time source** to generate or validate a curated, simplified `clades.yaml`.

The central issue is:

```text
OpenTree gives taxonomic/phylogenetic relationships.
Deep Time needs a small, readable, time-calibrated educational display.
```

Those are related, but not the same thing.

## What the OpenTree API Can Provide

The OpenTree API can help with:

```text
name → OTT id
OTT id → taxon information
OTT id → lineage
multiple OTT ids → induced subtree
OTT id → synthetic tree node information
OTT id → subtree
```

A likely workflow would be:

```text
1. Start with a curated list of clade names.
2. Use TNRS to resolve each name to an OTT id.
3. Use taxon_info/include_lineage to get parents/lineage.
4. Use induced_subtree to get the relationship among selected clades.
5. Convert the result into simplified YAML.
6. Add start_ma, end_ma, display groups, priorities, explanations, and zoom rules manually.
```

## Major Limitation

OpenTree is not primarily a geological-time database.

It can help answer questions like:

```text
Is Homo inside Hominini?
Is Hominini inside Homininae?
Is Homininae inside Hominidae?
Where does Aves sit relative to Dinosauria?
```

But it will not reliably provide fossil-first-appearance dates such as:

```yaml
start_ma: 231.0
end_ma: 66.0
range_note: Late Triassic to end-Cretaceous
```

Those dates still need to come from curated fossil, palaeontological, or educational sources.

So OpenTree should be used for **relationship validation**, not as the sole source of the clade timeline.

## Recommended Architecture

Use a two-layer model.

### Layer 1: Curated Display File

Keep:

```text
data/clades.yaml
```

This remains the file the app actually loads. It should stay small, stable, offline, and UI-oriented.

Example:

```yaml
- id: hominidae
  label: Hominidae (great apes)
  scientific_rank: family
  parent_id: primates
  ott_id: null
  start_ma: 18.0
  end_ma: 0.0
  display_priority: 22
  min_zoom_level: epoch
  cladistic_role: detail
```

This file should include only the clades users should actually see.

### Layer 2: Build / Reference Script

Add a script such as:

```text
scripts/update_clades_from_opentree.py
```

That script would:

```text
read data/clades.yaml
resolve missing ott_id values using OpenTree TNRS
fetch lineage/taxonomic parent information
compare OpenTree relationships with parent_id values
warn about mismatches
optionally write data/clades_opentree_cache.yaml
```

The app itself should not call OpenTree at runtime.

## Why Not Use OpenTree Live in the App?

Avoid live API calls because they introduce internet dependency, slow startup or loading, offline failure, excessive taxonomic detail, changing results as OpenTree updates, no direct first-appearance dates, and no display-priority logic.

For Deep Time, the better user experience is:

```text
prebuilt curated clade data
optional developer script to refresh or validate taxonomy
no runtime dependency on OpenTree
```

## Handling Limited Screen Space

Use zoom levels and display priorities.

### Tier 1: Broad Zoom

Visible at broad scale:

```text
Life
Bacteria
Archaea
Eukaryotes
Plants
Animals
Arthropods
Chordates
Vertebrates
Tetrapods
Amniotes
Mammals
Dinosaurs
Birds
Flowering plants
Homo sapiens
```

### Tier 2: Period / Epoch Zoom

Visible at closer zoom:

```text
Bilateria
Protostomes
Deuterostomes
Molluscs
Echinoderms
Jawed vertebrates
Bony vertebrates
Synapsids
Therapsids
Sauropsids
Archosaurs
Pterosaurs
Non-avian dinosaurs
Primates
Hominidae
Homininae
Hominini
Homo
Land plants
Vascular plants
Seed plants
Conifers
Angiosperms
Grasses
```

### Tier 3: Details Pane Only

Visible only after clicking or at very close zoom:

```text
Homo habilis
Homo erectus
Homo neanderthalensis
Homo sapiens
Australopithecus
Paranthropus
Ornithischia
Saurischia
Theropoda
Sauropodomorpha
Crocodylomorpha
```

## Suggested YAML Fields

```yaml
- id: hominidae
  label: Hominidae (great apes)
  scientific_rank: family
  parent_id: primates
  ott_id: null
  opentree_name: Hominidae
  start_ma: 18.0
  end_ma: 0.0
  range_note: Early Miocene to present
  confidence: approximate
  display_groups:
    - mammals_birds
    - terrestrial_vertebrates
  display_priority: 22
  min_zoom_level: epoch
  branch_priority: 32
  cladistic_role: detail
  include_in_main_tree: true
  collapsed_by_default: true
  short_description: Great apes, including orangutans, gorillas, chimpanzees, humans, and their extinct relatives.
  representative_taxa:
    - Orangutans
    - Gorillas
    - Chimpanzees
    - Humans
  tags:
    - mammal
    - primate
    - ape
    - hominid
    - living clade
```

OpenTree-specific data should be separated:

```yaml
opentree:
  ott_id: null
  matched_name: null
  unique_name: null
  rank: null
  flags: []
  lineage_ids: []
  checked_at: null
```

This prevents the app’s display model from depending too tightly on OpenTree’s response format.

## Suggested Script Behaviour

The script should work in phases.

### Phase 1: Resolve Names

For each row:

```yaml
opentree_name: Hominidae
```

Call TNRS and cache:

```yaml
opentree:
  ott_id: 123456
  matched_name: Hominidae
  rank: family
```

### Phase 2: Validate Parentage

Compare your simplified `parent_id` chain with the OpenTree lineage.

Example warning:

```text
WARNING: aves parent_id=dinosauria, OpenTree lineage places Aves within Theropoda/Saurischia/Dinosauria.
OK: this is acceptable because intermediate clades are intentionally omitted.
```

This matters because a simplified tree deliberately skips many intermediate clades. A mismatch is not always an error.

### Phase 3: Generate an Induced Subtree

For selected visible clades, call an induced subtree using their OTT ids. This can check whether the chosen set forms a sensible simplified tree.

### Phase 4: Write a Report

Generate:

```text
docs/clades_opentree_report.md
data/clades_opentree_cache.yaml
```

Do not automatically rewrite `data/clades.yaml` unless explicitly requested.

## UI Consequences

Using OpenTree as a reference source improves taxonomic defensibility, but also adds complexity.

Benefits include better scientific hierarchy, fewer parent-child mistakes, easier expansion later, stable OTT ids, and validated names/synonyms.

Costs include more complexity, many more possible nodes than the screen can show, possible mismatch between taxonomy and simplified educational clades, no direct first-appearance dates, need to cache results, and careful handling of extinct/problematic taxa.

The UI solution is:

```text
Use OpenTree behind the scenes.
Render only the curated simplified graph.
```

## Display Strategy

Use:

```yaml
display_priority: 1
min_zoom_level: period
collapsed_by_default: true
```

Example:

```yaml
- id: vertebrata
  display_priority: 8
  min_zoom_level: era

- id: gnathostomata
  display_priority: 16
  min_zoom_level: period

- id: hominidae
  display_priority: 22
  min_zoom_level: epoch

- id: homo
  display_priority: 25
  min_zoom_level: epoch

- id: homo_sapiens
  display_priority: 26
  min_zoom_level: stage
```

At broad zoom:

```text
Mammals
Primates
Homo
Homo sapiens
```

At closer zoom:

```text
Mammals
  Primates
    Hominidae
      Homininae
        Hominini
          Homo
            Homo sapiens
```

## Additional Sources for Curating a Simplified Clade List

There is no single ideal source that provides a small, curated, simplified, time-aware clade list for a Deep Time UI. The best approach is to combine sources, each for a different purpose.

### OneZoom

OneZoom is useful as a conceptual and design reference because it is a public-facing, zoomable Tree of Life. It is especially relevant to Deep Time because it faces the same core problem: the biological tree is far too large to show all at once, so the interface has to reveal detail gradually through zooming, grouping, collapsing, and prioritisation.

Use OneZoom for:

```text
public-facing simplification
recognisable broad branches
common-name friendly grouping
zoom and collapse behaviour
ideas for how to reveal detail progressively
examples of which clades ordinary users may recognise
```

OneZoom should be treated as a **UI and curation reference**, not as the direct source of the Deep Time clade dataset. Its full tree is far too detailed for the main Deep Time display, but it is very useful for deciding which parts of the Tree of Life should remain visible at broad zoom and which should be hidden until the user zooms or opens a details pane.

A good way to use OneZoom is to inspect how it presents major recognisable groups, then translate those into a much smaller Deep Time hierarchy. For example:

```text
OneZoom broad public tree
   ↓
identify recognisable branches
   ↓
select a small number of educationally useful clades
   ↓
add dates, display priority, and zoom rules in clades.yaml
```

For Deep Time, OneZoom can help answer questions such as:

```text
Which clade names are likely to be recognisable?
Which branches should be collapsed by default?
Which groups need common-name labels rather than scientific labels?
Which groups are too detailed for the main timeline but useful in a details pane?
```

Examples of useful public-facing labels inspired by the kind of grouping OneZoom supports include:

```text
Animals
Plants
Fungi
Vertebrates
Mammals
Birds
Reptiles
Amphibians
Fish
Arthropods
Insects
Flowering plants
Great apes
Humans
```

In `clades.yaml`, this suggests separating scientific identity from display wording:

```yaml
- id: hominidae
  label: Great apes
  scientific_label: Hominidae
  opentree_name: Hominidae
  parent_id: primates
  start_ma: 18.0
  end_ma: 0.0
  display_priority: 22
  min_zoom_level: epoch
  collapsed_by_default: true
```

The consequence is that OneZoom can help make the clade tree more user-friendly, while OpenTree can help make it taxonomically defensible. A practical split is:

```text
OneZoom    → display choices, recognisable grouping, zoom/collapse ideas
OpenTree   → accepted names, OTT ids, lineage and parent-child validation
Deep Time  → curated dates, priorities, explanations, and final visible tree
```

Do not copy OneZoom's full structure. It is far too detailed for the main Deep Time display. Instead, use it to sanity-check whether the simplified clade list feels understandable to a general audience.

### Open Tree of Life

Open Tree of Life is best used for relationship validation rather than display selection. It can help check accepted names, OTT ids, lineages, and whether simplified parent-child relationships are defensible.

Use OpenTree for:

```text
accepted names
OTT ids
lineage checks
parent-child validation
induced subtrees for selected clades
```

Do not use it as the runtime source of the app's visible tree.

### NCBI Taxonomy / Common Tree

NCBI Taxonomy can be useful as a secondary taxonomy check. It is helpful for quick lineage comparisons and major taxonomic ranks, but it should not be treated as the final authority for all classification questions.

Use NCBI for:

```text
quick lineage checks
major taxonomic ranks
comparison with OpenTree
```

### Berkeley Understanding Evolution

Berkeley's Understanding Evolution material is useful for explanatory wording. It is especially helpful for explaining what a clade is and why a clade must include an ancestor and all descendants.

Use it for:

```text
help-screen wording
simple explanations of clades
checking the educational clarity of tree diagrams
```

## How to Decide Which Clades to Include

Selection should be driven by educational value and screen utility, not taxonomic completeness.

### Include Major Evolutionary Transitions

Prioritise clades that explain important transitions in Deep Time:

```text
Eukaryotes          complex cells
Animals            animal body plans
Bilateria          most familiar animal body plans
Vertebrates        backboned animals
Jawed vertebrates  major fish and vertebrate radiation
Tetrapods          vertebrates onto land
Amniotes           fully terrestrial vertebrate reproduction
Mammals            mammal lineage
Archosaurs         crocodiles, pterosaurs, dinosaurs, and birds
Dinosauria         dinosaurs, including birds
Angiosperms        flowering plants
Hominini           human lineage
```

### Include Recognisable Groups

A scientifically precise clade list is not useful if users cannot interpret it. Prefer labels that users can recognise quickly:

```text
Animals
Arthropods
Trilobites
Molluscs
Vertebrates
Tetrapods
Mammals
Dinosaurs
Birds
Flowering plants
Primates
Great apes
Humans
```

Scientific labels can still be stored in the YAML while friendlier labels are used in the UI.

Example:

```yaml
id: hominidae
label: Great apes
scientific_label: Hominidae
```

### Avoid Human-Lineage Bias

The human lineage is important, but the tree should not imply that all evolution leads to humans. Balance the display with plants, arthropods, molluscs, major marine groups, and extinct iconic groups.

A balanced simplified clade set should include:

```text
microbial life
plants
major animal branches
vertebrates
mammals, birds, and humans
selected extinct iconic groups
```

### Separate Main Timeline Clades from Detail Clades

The main timeline should only show clades that earn screen space. More detailed groups can appear in a detail pane or at very close zoom.

Use this general test before adding a clade to the main display:

```text
Does it mark a major branch point?
Does it have a long or visually useful time range?
Will a general user recognise it or understand it quickly?
Does it explain a major ecological or evolutionary change?
Does it relate clearly to another visible clade?
```

If not, keep it in the details pane rather than the main timeline.

### Use Omitted Intermediate Clades Deliberately

The simplified tree does not need every intermediate clade. For example, a readable human-lineage display might be:

```text
Vertebrates
  Tetrapods
    Amniotes
      Mammals
        Primates
          Hominidae
            Homininae
              Hominini
                Homo
                  Homo sapiens
```

This skips many valid intermediate groups, but the relationship remains understandable. Add a field if useful:

```yaml
lineage_simplified: true
```

or:

```yaml
omits_intermediate_clades: true
```

### Keep Dates Curated Separately

OpenTree can help with names and relationships, but it should not decide `start_ma` or `end_ma`. Those dates need to remain curated palaeontological and educational estimates.

## Recommended First Curated Clade List

A practical first version could contain about 35-40 entries:

```text
Life
Bacteria
Archaea
Eukaryotes

Plants / Archaeplastida
Land plants
Vascular plants
Seed plants
Conifers
Flowering plants / Angiosperms
Grasses

Animals / Metazoa
Bilateria
Protostomes
Arthropods
Trilobites
Molluscs
Deuterostomes
Echinoderms
Chordates
Vertebrates
Jawed vertebrates
Bony vertebrates
Tetrapods
Amniotes

Synapsids
Therapsids
Mammals
Primates
Hominidae
Homininae
Hominini
Homo
Homo sapiens

Sauropsids
Diapsids
Archosaurs
Pterosaurs
Dinosauria
Non-avian dinosaurs
Birds / Aves
```

This is close to the upper safe limit for a first-pass visible clade dataset. Anything more detailed should usually be hidden behind zoom levels or shown only in the details pane.

## Practical Curated-Clade Workflow

A useful workflow is:

```text
1. Hand-curate a small clade list.
2. Add opentree_name for each clade.
3. Use OpenTree to resolve OTT ids and validate relationships.
4. Use OneZoom as a sanity check for public-facing recognisability.
5. Keep dates and display priorities in clades.yaml.
6. Render by zoom level and display_priority.
```

The final app-facing data should still be `data/clades.yaml`. OpenTree and other sources should support curation, not replace it.

## Recommendation

Use OpenTree as a developer/reference pipeline, not as the runtime source of truth.

Best architecture:

```text
OpenTree API
   ↓
scripts/update_clades_from_opentree.py
   ↓
data/clades_opentree_cache.yaml
   ↓
manual/curated review
   ↓
data/clades.yaml
   ↓
Deep Time app renderer
```

`clades.yaml` should remain the final authority for:

```text
which clades are shown
dates
display priority
zoom rules
range bars
educational labels
short descriptions
```

OpenTree should help with:

```text
OTT ids
accepted names
lineages
parent-child validation
taxonomic consistency
```


This gives the benefits of OpenTree without letting a huge taxonomic tree overwhelm a deliberately simplified educational display.

## Future User-Added Species and Clades

A useful long-term direction is to allow users to add cladistic details about species or clades they are personally interested in. This should be implemented as a separate user-curated layer rather than by allowing users to directly modify the core `clades.yaml` file.

The broad model should be:

```text
core curated clades
        +
user-added species/clades
        +
optional OpenTree validation/cache
        ↓
displayed clade range tree
```

### Keep `clades.yaml` as the Protected Core

The shipped `data/clades.yaml` file should remain the curated app reference. It should contain broad, stable clades such as:

```text
Life
Eukaryotes
Animals
Vertebrates
Tetrapods
Mammals
Primates
Hominidae
Homininae
Hominini
Homo
Homo sapiens
Birds
Dinosauria
Flowering plants
```

Users should not edit this file directly. It should remain the reliable backbone for the app's clade range tree.

### Store User Additions Separately

User-entered species and favourite clades should be stored in a separate file or database table, for example:

```text
user_clades.yaml
```

or, more likely in the final app:

```text
user_clades.sqlite
```

A YAML-style development format might look like this:

```yaml
user_clades:
  - id: user_tyrannosaurus_rex
    label: Tyrannosaurus rex
    scientific_name: Tyrannosaurus rex
    rank: species
    parent_id: non_avian_dinosaurs
    start_ma: 68.0
    end_ma: 66.0
    range_note: Late Cretaceous
    user_notes: Favourite dinosaur
    source_status: user_entered
    validation_status: unverified
    display_priority: 80
    visible: true
```

The core principle is:

```text
Core clades = curated by the app
User clades = added by the user
OpenTree = optional validation/reference
```

### Ask Users for Attachment, Not a Full Taxonomy

Most users should not be asked to enter a full cladistic chain. The app should ask for a small number of practical details:

```text
What species or clade are you interested in?
Where should it attach?
What time range should it show?
```

For example:

```text
Species: Tyrannosaurus rex
Attach under: Non-avian dinosaurs
Range: 68-66 Ma
```

Advanced users could later edit deeper lineage details, but the basic workflow should stay simple.

### Suggested User-Entry Workflow

A future workflow could be:

```text
1. User enters a species or clade name.
2. App searches local known clades first.
3. App optionally queries OpenTree for accepted name and lineage.
4. App suggests a parent clade.
5. User confirms or changes the parent.
6. User adds or confirms start/end Ma.
7. App stores the entry as a user layer.
8. Display merges core + user entries.
```

Example:

```text
User enters: Tyrannosaurus rex

App suggests:
Scientific name: Tyrannosaurus rex
Rank: species
Likely parent: Theropoda / Dinosauria / Non-avian dinosaurs
Suggested display parent: Non-avian dinosaurs
Range: 68-66 Ma
```

The app could then ask:

```text
Add this to your clade tree?
```

### Keep OpenTree Optional

OpenTree is useful for checking accepted names, synonyms, lineages, parent-child placement, and OTT ids. It should not be required for every user addition, because it does not reliably provide first appearance dates, last appearance dates, display priorities, or educational range-bar decisions.

A future user-added record could include optional OpenTree metadata:

```yaml
opentree:
  ott_id: null
  matched_name: null
  unique_name: null
  rank: null
  lineage_ids: []
  lineage_names: []
  validation_status: not_checked
```

If OpenTree is unavailable, the user should still be able to add the item manually.

### Use Confidence and Validation States

User-added entries should have clear validation states so the app does not present user-entered data as if it has the same authority as the curated core dataset.

Useful states include:

```text
user_entered
opentree_matched
opentree_mismatch
date_missing
date_uncertain
manually_verified
```

Example:

```yaml
validation:
  taxonomy_status: opentree_matched
  date_status: user_estimated
  parent_status: user_confirmed
```

### Avoid Screen Overload

User additions can quickly clutter the tree. Each user-added entry should therefore have display controls:

```yaml
visible: true
show_in_main_tree: false
show_in_details: true
min_zoom_level: stage
display_priority: 90
collapsed_by_default: true
```

A sensible default is:

```text
User-added species appear in details or close zoom only.
Only user-pinned favourites appear in the main timeline.
```

Pinned entries could use:

```yaml
pinned: true
min_zoom_level: epoch
```

Unpinned entries could use:

```yaml
pinned: false
min_zoom_level: stage
```

### Use a Favourites Model

Because the goal is to support species that users are particularly interested in, the user-facing language should emphasise favourites rather than technical taxonomy entry.

Possible UI wording:

```text
Add favourite species
Add to my clade tree
Pin to timeline
Show in details only
```

This is friendlier than asking users to "enter cladistic details", even though the app stores cladistic data behind the scenes.

### Possible Future Storage Model

A future implementation could use three datasets:

```text
data/clades.yaml
```

App-curated clades.

```text
data/clade_aliases.yaml
```

Known synonyms and common names.

```text
user_data/user_clades.sqlite
```

User-added species and clades.

During development, a YAML-only version could use:

```text
data/clades.yaml
data/clade_aliases.yaml
user_clades.yaml
```

### Example Merged Display

Core tree:

```text
Dinosauria
└── Non-avian dinosaurs
```

User adds:

```text
Tyrannosaurus rex
Triceratops horridus
Velociraptor mongoliensis
```

Display at broad zoom:

```text
Dinosauria
└── Non-avian dinosaurs
```

Display at close zoom or in details:

```text
Dinosauria
└── Non-avian dinosaurs
    ├── Tyrannosaurus rex
    ├── Triceratops horridus
    └── Velociraptor mongoliensis
```

This keeps the main app clean while allowing personalisation.

### Recommended Long-Term Model

The long-term structure should be:

```text
Curated backbone clade tree
+
User favourites layer
+
Optional OpenTree lookup/validation
+
Zoom/pin controls
```

The user should only need to enter:

```text
name
optional parent
optional date range
personal note
whether to pin it
```

The app can manage the deeper cladistic structure behind the scenes.
