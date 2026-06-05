# Deep Time 2: Taxonomy View and Dating Data Sources

## Purpose

Deep Time 2 will support two different biological views because clades are difficult to date consistently:

1. **Cladistic view** — preserves the existing Clades column and behaviour, but only aligns clades where reliable `start_ma` data exists.
2. **Taxonomic view** — replaces the Clades column with a Taxonomy column. The taxonomy data will be generated from publicly available sources and stored in an SQLite database called `taxonomy.sqlite`.

The Taxonomy view should not try to behave exactly like the Clades view. Taxonomy is a formal classification hierarchy, while clades are evolutionary groups that can sometimes be aligned to geological time.

---

## Suggested switch mechanism

Use a **two-state segmented switch** in the scale row:

```text
Biology: [ Clades | Taxonomy ]
```

This is preferable to a checkbox or icon because the user is choosing between two alternative biological views, not simply turning a feature on or off.

A possible layout is:

```text
Scale:  [ Eon | Era | Period | Epoch | Stage ]       Biology: [ Clades | Taxonomy ]
```

If the row is crowded, a shorter version could be:

```text
View: [ Clades | Taxonomy ]
```

When **Clades** is selected, the existing Clades column remains visible. It should show only those clades that have usable `start_ma` values, so their positions can be meaningfully aligned with the time scale.

When **Taxonomy** is selected, the same column area is relabelled **Taxonomy** and populated from `taxonomy.sqlite`.

A useful internal model would be:

```text
biologyColumnMode = cladistic | taxonomic
```

This keeps the app architecture simple. The same column region remains in place, but the data source, title, row rendering, and alignment rules change depending on the selected mode.

---

## Taxonomy view: general principle

The Taxonomy view should start from the **oldest and broadest biological categories** and move towards progressively more specific groups.

The organising principle is:

```text
Oldest / broadest
↓
Youngest / most specific
```

However, this should not imply that every taxonomic rank has a precise evolutionary origin date. Many taxonomic ranks are artificial classification levels rather than directly dated evolutionary events.

The Taxonomy view should therefore be a **ranked biological hierarchy**, not a time-scaled bar system.

---

## Suggested top-level taxonomy structure

The default view could begin with:

```text
Life
 ├── Bacteria
 ├── Archaea
 └── Eukaryota
      ├── Animalia
      ├── Plantae
      ├── Fungi
      └── Protists / other eukaryotic groups
```

Expanding **Animalia** could show:

```text
Life
 └── Eukaryota
      └── Animalia
           ├── Porifera
           ├── Cnidaria
           ├── Arthropoda
           ├── Mollusca
           ├── Echinodermata
           └── Chordata
```

Expanding **Chordata** could show:

```text
Chordata
 ├── Cephalochordata
 ├── Tunicata
 └── Vertebrata
      ├── Agnatha / jawless vertebrates
      ├── Chondrichthyes
      ├── Actinopterygii
      ├── Sarcopterygii
      ├── Amphibia
      ├── Reptilia
      ├── Aves
      └── Mammalia
```

---

## Suggested rank sequence

For a teaching-friendly app, the basic sequence should be:

```text
Life
Domain
Kingdom
Phylum
Class
Order
Family
Genus
Species
```

A selected path could appear as:

```text
Life
 └── Domain: Eukaryota
      └── Kingdom: Animalia
           └── Phylum: Chordata
                └── Class: Mammalia
                     └── Order: Primates
                          └── Family: Hominidae
                               └── Genus: Homo
                                    └── Species: Homo sapiens
```

Each row could show three pieces of information:

```text
Rank        Name              Plain-language label
Domain      Eukaryota          organisms with complex cells
Kingdom     Animalia           animals
Phylum      Chordata           animals with a notochord
Class       Mammalia           mammals
Order       Primates           primates
Family      Hominidae          great apes
Genus       Homo               humans and close relatives
Species     Homo sapiens       modern humans
```

---

## Suggested visual format

The Taxonomy column could use a compact tree format:

```text
TAXONOMY
────────────────────────
Life
  Eukaryota
    Animalia
      Chordata
        Mammalia
          Primates
            Hominidae
              Homo
                Homo sapiens
```

Expandable branches could use disclosure arrows:

```text
TAXONOMY
────────────────────────
Life
  Bacteria ▸
  Archaea ▸
  Eukaryota ▾
    Animalia ▾
      Chordata ▾
        Mammalia ▾
          Primates ▾
            Hominidae ▾
              Homo ▾
                Homo sapiens
    Plantae ▸
    Fungi ▸
```

The app should avoid showing the whole taxonomy at once because it would quickly become unreadable. Instead, it should use a **drill-down hierarchy**.

---

## Recommended interaction model

The preferred interaction model is:

```text
Top:      breadcrumb showing the current lineage
Middle:   selected taxon details
Bottom:   immediate child taxa
```

For example, if the selected taxon is **Chordata**:

```text
TAXONOMY
────────────────────────
Life > Eukaryota > Animalia > Chordata

Selected:
Phylum: Chordata
Common description: animals with a notochord

Children:
  Vertebrata
  Tunicata
  Cephalochordata
```

If the user then selects **Mammalia**, the display could update to:

```text
Life > Eukaryota > Animalia > Chordata > Mammalia

Children:
  Monotremata
  Marsupialia
  Placentalia
```

Then selecting **Placentalia** could show:

```text
Life > Eukaryota > Animalia > Chordata > Mammalia > Placentalia

Children:
  Primates
  Carnivora
  Cetartiodactyla
  Rodentia
  Chiroptera
  Proboscidea
```

This keeps the view educational, navigable, and compact.

---

## Important distinction between the two views

The app should make this distinction clear:

```text
Clades view    = evolutionary groups aligned to geological time where dates are available.
Taxonomy view  = formal classification hierarchy, shown broadest-to-most-specific, not necessarily time-aligned.
```

Suggested tooltip text for **Clades**:

```text
Shows evolutionary groups aligned to geological time where start-date data is available.
```

Suggested tooltip text for **Taxonomy**:

```text
Shows formal biological classification from taxonomy data. Not all ranks imply evolutionary start dates.
```

---

## Publicly available sources for taxonomy and start-time data

The best solution is not a single source. No one public database provides reliable taxonomy, fossil first appearances, and molecular-clock divergence estimates in one clean app-ready format.

A good data pipeline would use:

```text
Primary taxonomy backbone:     Open Tree of Life / OTT
Primary molecular dates:       TimeTree 5
Primary fossil dates:          Paleobiology Database
Optional synthesis layer:      DateLife
```

---

## Open Tree of Life / OTT

Use **Open Tree of Life** as the main taxonomic scaffold.

Its role would be to provide:

- accepted names
- synonyms
- parent-child relationships
- taxonomic hierarchy
- stable Open Tree Taxonomy IDs
- links between taxonomy and phylogenetic structure where available

For `taxonomy.sqlite`, Open Tree of Life would be the best source for building the core taxon table and resolving names.

---

## TimeTree 5

Use **TimeTree 5** as the primary source for molecular-clock divergence estimates.

Its role would be to provide:

- molecular divergence estimates
- estimated origin/divergence times
- confidence intervals where available
- published-study provenance
- downloadable or programmatic data access

TimeTree is especially useful because it is designed specifically around the evolutionary timescale of life. It synthesises published molecular timetree studies and can provide dates for many taxa where direct fossil evidence is incomplete or absent.

---

## Paleobiology Database

Use the **Paleobiology Database** as the main source for fossil-based first appearance data.

Its role would be to provide:

- fossil occurrence records
- taxonomic identifications of fossil material
- stratigraphic and age information
- geographic occurrence data
- oldest known fossil records for a taxon or its descendants

However, the Paleobiology Database is not a simple ready-made clade start-date database. Fossil first appearance dates would need to be derived from occurrence records, usually by finding the oldest occurrence assigned to a taxon or to one of its descendants.

Fossil first appearance should be treated as a **minimum age**, not necessarily the true origin time of the group.

---

## DateLife

DateLife could be used as an optional synthesis or validation layer.

Its role would be to help discover, summarise, reuse, and compare published divergence-time data from peer-reviewed chronograms.

It should not be the only dependency, but it may be useful for cross-checking TimeTree estimates or filling gaps where appropriate.

---

## Recommended database fields

The SQLite database should store fossil and molecular dates separately.

A possible structure is:

```text
taxon_id
parent_taxon_id
taxon_name
rank
ott_id
ncbi_id
gbif_id
pbdb_id

fossil_first_ma
fossil_first_source
fossil_first_confidence

molecular_origin_ma
molecular_origin_min_ma
molecular_origin_max_ma
molecular_source

display_start_ma
display_start_basis
```

The field `display_start_basis` could use values such as:

```text
fossil_first_appearance
molecular_clock
combined_range
manual_curated
proxy
unknown
```

---

## Why fossil and molecular dates should remain separate

The app should not silently merge fossil and molecular estimates into one `start_ma` value.

They mean different things:

- **Fossil first appearance** is a minimum age. The group must already have existed by that time, but it may be older.
- **Molecular-clock estimate** attempts to estimate the actual divergence or origin time, but it can vary depending on the study, taxa sampled, calibration points, and analytical method.

The app should therefore preserve both values and display their source clearly.

Example display:

```text
Mammalia
Fossil evidence:       ~225 Ma
Molecular estimate:    ~180–220 Ma
Display position:      molecular estimate
```

Another example:

```text
Angiosperms
Fossil evidence:       ~135 Ma
Molecular estimate:    older, variable
Display position:      combined range
```

---

## Recommended Deep Time 2 data architecture

The recommended architecture is:

```text
Open Tree of Life
→ gives the names, hierarchy, IDs, synonyms, and parent-child structure

TimeTree
→ gives molecular-clock divergence estimates and confidence intervals

Paleobiology Database
→ gives fossil first appearances from occurrence data

DateLife
→ optional cross-check / summary source for published chronograms
```

The app should then calculate a display date only after assigning a provenance label.

Recommended rule:

```text
Use Open Tree of Life as the taxonomic scaffold.
Attach TimeTree molecular dates where available.
Attach Paleobiology Database fossil first-appearance dates where available.
Store both dates separately in taxonomy.sqlite.
Only calculate display_start_ma after assigning display_start_basis.
```

---

## Suggested provenance messages for the UI

The UI should be able to communicate the basis of any displayed date:

```text
This taxon is shown using fossil evidence.
This taxon is shown using molecular-clock evidence.
This taxon is shown using both fossil and molecular evidence.
This taxon uses a curated proxy estimate.
This taxon has no reliable date yet.
```

This is especially important because taxonomic ranks do not always correspond neatly to dated evolutionary origins.

---

## Summary recommendation

Use the Taxonomy column as a **drill-down hierarchy**, not as a direct replacement for a time-aligned clade bar system.

The taxonomy should begin at **Life**, then move through increasingly specific ranks such as:

```text
Domain → Kingdom → Phylum → Class → Order → Family → Genus → Species
```

The data should be stored in `taxonomy.sqlite`, using Open Tree of Life as the taxonomic backbone, TimeTree 5 for molecular-clock dates, and the Paleobiology Database for fossil first appearances.

Both fossil and molecular dates should be stored separately, with a separate `display_start_ma` used only when the app has assigned a clear provenance label.
