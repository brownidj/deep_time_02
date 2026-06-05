# Clade Representation Discussion Summary

This document summarises the prompts and replies from the conversation starting at:

> “How are clades normally represented diagramatically?”

## 1. How clades are normally represented diagrammatically

### User prompt

> How are clades normally represented diagramatically?

### Summary of reply

Clades are normally represented using a **phylogenetic tree**, also called a **cladogram**.

A clade is a group containing a common ancestor and **all** of its descendants. Diagrammatically, this means a branch point and everything descending from it.

Common diagram types include:

| Diagram type | Main use |
|---|---|
| **Cladogram** | Shows branching relationships; branch lengths are not meaningful. |
| **Phylogram** | Branch lengths represent evolutionary change. |
| **Chronogram / time tree** | Branch lengths represent time. |
| **Radial tree** | Useful for many groups in limited space. |
| **Circular tree** | Useful for very large datasets. |
| **Indented tree/list** | Useful for compact UI navigation. |

A simple cladogram-style representation:

```text
        ┌─ Species A
    ┌───┤
    │   └─ Species B
────┤
    │   ┌─ Species C
    └───┤
        └─ Species D
```

In that example, **A + B** form one clade, **C + D** form another clade, and all four together form a larger clade.

Key interpretation:

```text
branch point = common ancestor
branch       = lineage
tips         = species/groups
whole branch cluster = clade
```

For the **Deep Time** app, the recommendation was:

```text
Main timeline:  simple horizontal range bars
Details pane:   small indented cladogram
Optional:       time-calibrated cladogram
```

The best compact UI label suggested was:

```text
Clades
```

The best explanatory diagram type was:

```text
Cladogram
```

The best timeline-oriented representation was:

```text
Time-calibrated clade ranges
```

---

## 2. Vertical tree with range bars, oldest at the top

### User prompt

> Can we show them as a vertical tree with range bars. Oldest at the top?

### Summary of reply

Yes. This was identified as probably the best representation for the **Deep Time** app.

The proposed design was a **vertical phylogenetic tree with time-range bars**, with:

```text
Oldest at top
Youngest / present at bottom
```

This combines two useful ideas:

1. **Tree structure** shows nesting and evolutionary relationships.
2. **Range bars** show how long each clade exists through geological time.

Conceptual example:

```text
Cambrian
│
├── Arthropoda        █████████████████████████████████████ present
│   ├── Trilobita     ███████████████████
│   └── Chelicerata   █████████████████████████████████████ present
│
├── Chordata          █████████████████████████████████████ present
│   └── Vertebrata        █████████████████████████████████ present
│       ├── Jawless fish  █████████████████████████████████ present
│       └── Gnathostomata     █████████████████████████████ present
│           ├── Chondrichthyes ███████████████████████████ present
│           └── Osteichthyes   ███████████████████████████ present
│               └── Tetrapoda       █████████████████████ present
│                   └── Amniota          ████████████████ present
│
Present
```

A possible YAML model was suggested:

```yaml
- id: tetrapoda
  label: Tetrapoda
  parent_id: osteichthyes
  start_ma: 375.0
  end_ma: 0.0
  rank: clade
  explanation: |
    Tetrapods are vertebrates descended from lobe-finned fish ancestors and
    include amphibians, reptiles, mammals, and birds.
```

Recommended visual rule:

```text
indentation = clade nesting
vertical position = first appearance date
bar height/span = start_ma to end_ma
```

However, an important caution was noted: a strict phylogenetic tree does not always map perfectly onto vertical time rows, because descendant clades originate later than their parent clades. So the more accurate description for the display is:

```text
time-calibrated indented range chart
```

Suggested internal names:

```text
clade_range_tree
phylo_range_tree
```

Suggested UI labels:

```text
Clade tree
Clades
```

Recommended layout:

```text
Left side:   vertical tree connectors and indentation
Centre:      clade names
Right side:  range bars aligned to geological time
Direction:   oldest at top, present at bottom
```

Example:

```text
Ma
541 ─ Chordata
      │ █████████████████████████████████████████
485 ─ ├─ Vertebrata
      │   ███████████████████████████████████████
430 ─ │  ├─ Gnathostomata
      │  │   ████████████████████████████████████
375 ─ │  │  └─ Tetrapoda
      │  │      █████████████████████████████████
320 ─ │  │     └─ Amniota
      │  │         ██████████████████████████████
252 ─ │  │        ├─ Mammalia
      │  │        │   ███████████████████████████
231 ─ │  │        └─ Dinosauria
      │  │            ███████████████████
150 ─ │  │           └─ Aves
      │  │               ████████████████
0   ─ Present
```

For extinct clades, the bar ends before the present:

```text
Trilobita     ███████████████████
Dinosauria    ███████████████████
Aves                          █████████████ present
```

A major modelling caution was included:

```text
Birds are dinosaurs.
```

So the recommended model was:

```yaml
- id: dinosauria
  label: Dinosauria
  start_ma: 231.0
  end_ma: 0.0

- id: non_avian_dinosaurs
  label: Non-avian dinosaurs
  parent_id: dinosauria
  start_ma: 231.0
  end_ma: 66.0

- id: aves
  label: Birds
  parent_id: dinosauria
  start_ma: 150.0
  end_ma: 0.0
```

This avoids the common error of ending all dinosaurs at 66 Ma while also showing birds alive today.

Main conclusion:

```text
Use a vertical clade range tree, oldest at top, with range bars aligned to the existing geological timescale.
```

---

## 3. Which clades should be included in a simplified tree?

### User prompt

> This is obviously going to be a very simplified tree - which clades should be ncluded?

### Summary of reply

The recommendation was to keep the clade tree deliberately simplified, with about **25–40 rows maximum**. The tree should not attempt to include every phylum or taxonomic rank. It should focus on clades that are:

- recognisable,
- useful for the timeline,
- tied to major evolutionary transitions,
- visually meaningful in a Deep Time app.

A suggested first-pass list was:

| Clade | Approx. start Ma | End Ma | Why include it |
|---|---:|---:|---|
| **Life** | 3800 | 0 | Root of the biological tree |
| **Bacteria** | 3500 | 0 | Early life and microbial dominance |
| **Archaea** | 3500 | 0 | Major domain of life |
| **Eukaryotes** | 1800 | 0 | Cells with nuclei; major complexity step |
| **Plants / Archaeplastida** | 1600 | 0 | Photosynthetic eukaryote line |
| **Animals / Metazoa** | 800 | 0 | Main animal clade |
| **Bilateria** | 560 | 0 | Animals with left-right symmetry |
| **Protostomes** | 550 | 0 | One major bilaterian branch |
| **Arthropods** | 540 | 0 | Trilobites, insects, crustaceans, arachnids |
| **Trilobites** | 521 | 252 | Iconic extinct arthropods |
| **Molluscs** | 540 | 0 | Shellfish, cephalopods, gastropods |
| **Deuterostomes** | 540 | 0 | Other major bilaterian branch |
| **Echinoderms** | 540 | 0 | Starfish, crinoids, sea urchins |
| **Chordates** | 535 | 0 | Line leading to vertebrates |
| **Vertebrates** | 518 | 0 | Backboned animals |
| **Jawed vertebrates** | 430 | 0 | Major fish and tetrapod radiation |
| **Bony vertebrates** | 420 | 0 | Ray-finned fish + lobe-finned fish |
| **Tetrapods** | 375 | 0 | Vertebrates with limbs |
| **Amniotes** | 320 | 0 | Fully terrestrial egg/reproduction transition |
| **Synapsids** | 320 | 0 | Mammal line |
| **Therapsids** | 275 | 0 | Closer mammal relatives |
| **Mammals** | 225 | 0 | Major living vertebrate group |
| **Sauropsids** | 320 | 0 | Reptile/bird line |
| **Diapsids** | 310 | 0 | Most reptiles, birds, many extinct marine reptiles |
| **Archosaurs** | 250 | 0 | Crocodiles, pterosaurs, dinosaurs, birds |
| **Pterosaurs** | 228 | 66 | First flying vertebrates |
| **Dinosauria** | 231 | 0 | Includes birds |
| **Non-avian dinosaurs** | 231 | 66 | The extinct dinosaurs most users expect |
| **Birds / Aves** | 150 | 0 | Living dinosaurs |
| **Angiosperms** | 135 | 0 | Flowering plants |
| **Grasses / Poaceae** | 70 | 0 | Important for grasslands and grazing mammals |
| **Primates** | 56 | 0 | Human evolutionary context |
| **Hominins** | 7 | 0 | Human lineage |
| **Homo** | 2.8 | 0 | Genus including humans |
| **Homo sapiens** | 0.3 | 0 | Modern humans |

A simplified tree structure was proposed:

```text
Life
├── Bacteria
├── Archaea
└── Eukaryotes
    ├── Plants
    │   ├── Land plants
    │   ├── Seed plants
    │   ├── Angiosperms
    │   └── Grasses
    └── Animals
        └── Bilateria
            ├── Protostomes
            │   ├── Arthropods
            │   │   └── Trilobites
            │   └── Molluscs
            └── Deuterostomes
                ├── Echinoderms
                └── Chordates
                    └── Vertebrates
                        └── Jawed vertebrates
                            └── Tetrapods
                                └── Amniotes
                                    ├── Synapsids
                                    │   └── Mammals
                                    └── Sauropsids
                                        └── Archosaurs
                                            ├── Pterosaurs
                                            └── Dinosauria
                                                ├── Non-avian dinosaurs
                                                └── Birds
```

A plant branch was strongly recommended so that the timeline does not overemphasise animals.

Suggested plant clades:

| Plant clade | Approx. start Ma | End Ma |
|---|---:|---:|
| **Land plants** | 470 | 0 |
| **Vascular plants** | 430 | 0 |
| **Seed plants** | 365 | 0 |
| **Conifers** | 320 | 0 |
| **Flowering plants / Angiosperms** | 135 | 0 |
| **Grasses** | 70 | 0 |

Suggested first implementation size:

```text
about 30 clades
```

Suggested file:

```text
data/clades.yaml
```

Example YAML shape:

```yaml
clades:
  - id: tetrapoda
    label: Tetrapods
    parent_id: bony_vertebrates
    start_ma: 375.0
    end_ma: 0.0
    type: range_bar
    confidence: moderate
    explanation: |
      Tetrapods are vertebrates descended from lobe-finned fish ancestors and
      include amphibians, reptiles, mammals, and birds.
```

Important modelling rule:

```text
Use “Dinosauria” for dinosaurs including birds: 231–0 Ma.
Use “Non-avian dinosaurs” for the extinct dinosaur bar: 231–66 Ma.
```

This keeps the tree scientifically correct while still matching what ordinary users expect.

---

## 4. Practical recommendation for Deep Time app

The recommended direction is:

```text
Create data/clades.yaml
Render it as a vertical clade range tree
Oldest at the top
Present at the bottom
Use indentation/connector lines for relationships
Use vertical or aligned range bars for duration
Limit the first version to about 30 major clades
```

Suggested dataset fields:

```yaml
clades:
  - id: example_clade
    label: Example clade
    short_label: Example
    parent_id: parent_clade_id
    start_ma: 100.0
    end_ma: 0.0
    type: range_bar
    confidence: approximate
    category: animal_clade
    explanation: |
      Short explanatory text for users.
```

Useful possible categories:

```text
life_domain
eukaryote_clade
plant_clade
animal_clade
vertebrate_clade
tetrapod_clade
dinosaur_clade
human_lineage
extinct_clade
```

Suggested UI terminology:

```text
Column/header: Clades
Details title: Clade tree
Internal renderer: clade_range_tree
```

## 5. Notes and cautions

- This is a simplified educational tree, not a full phylogenetic taxonomy.
- Dates should be approximate and should use confidence flags.
- Parent-child nesting should be biologically meaningful but not too dense for the UI.
- Some clades overlap because descendants are nested inside parent clades.
- Extinct subgroups should end before present, but parent clades may continue through surviving descendants.
- Dinosauria should continue to present if birds are included.
- “Non-avian dinosaurs” should be used for the extinct dinosaur range ending at 66 Ma.
