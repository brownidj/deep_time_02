# Paleoclimate Events: Geography, Extent, and Regional Expression

Major paleoclimate events can be tied to both:

1. **Geographic evidence locations** — where the event is best recorded, such as Siberia, Gondwana, Antarctica, Tethys, North Atlantic, equatorial continents, and so on.
2. **Spatial expression** — whether the climate event was global, hemispheric, ocean-basin scale, polar-amplified, tropical, regional, or mostly known from scattered proxy sites.

The important distinction is:

> **The cause or evidence may be geographically local, but the climate effect may be global.**

For example, the **end-Permian crisis** is strongly tied to the **Siberian Traps**, but its climatic effects were global: greenhouse warming, marine anoxia, acidification, and ecosystem collapse. The **Eocene–Oligocene transition** is centred on **Antarctic glaciation**, but it marks a global shift from greenhouse to icehouse conditions.

---

## Suggested dataset structure

```yaml
paleoclimate_event:
  name: Paleocene-Eocene Thermal Maximum
  start_ma: 56.0
  end_ma: 55.8
  event_type:
    - hyperthermal
    - carbon_cycle_excursion
    - greenhouse_warming
  geographic_anchor:
    - global ocean
    - North Atlantic
    - Arctic Ocean
    - Tethys margins
  spatial_extent: global
  spatial_confidence: high
  hemispheric_bias: both
  latitudinal_expression:
    tropics: warming, hydrological stress, reef/marine turnover
    mid_latitudes: warming, rainfall-pattern change
    high_latitudes: strong polar amplification
  regional_expression:
    Arctic Ocean: freshening, warmth, methane/carbon-cycle feedbacks
    deep_ocean: warming, carbonate dissolution, acidification
    continental_interiors: heat and hydrological stress
  notes: >
    Rapid carbon release caused global warming, ocean acidification,
    hydrological disruption, and strong high-latitude effects.
```

---

## Larger list with geographic links and globality

| Event | Approx. age | Geographic anchor / best evidence | How global? | Regional climate expression |
|---|---:|---|---|---|
| **Early Earth / Hadean climate** | 4.6–4.0 Ga | Whole Earth; earliest crustal and zircon evidence mostly from ancient cratons such as Western Australia | **Global, but poorly constrained** | Hot early surface, heavy impacts, atmosphere/ocean formation; local evidence only preserves fragments. |
| **Early oceans form** | c. 4.4–3.8 Ga | Ancient crustal provinces; detrital zircons, early sedimentary evidence | **Global process inferred from local evidence** | Liquid water likely existed at least episodically; evidence is fragmentary because most crust was recycled. |
| **Faint Young Sun climate problem** | c. 3.8–2.5 Ga | Global Earth system; Archean sedimentary basins in cratons | **Global** | Despite weaker solar luminosity, Earth avoided permanent freezing, probably through greenhouse gases such as CO₂ and methane. |
| **Great Oxidation Event** | c. 2.45–2.2 Ga | Global atmosphere-ocean system; banded iron formations, red beds, sulfur isotope records | **Global** | Oxygen rise changed atmospheric chemistry; methane decline may have contributed to severe cooling and Paleoproterozoic glaciation. The link between GOE and global glaciation is still debated. |
| **Huronian glaciations** | c. 2.4–2.1 Ga | Laurentia / North America, especially Canadian Shield; also correlated Paleoproterozoic records elsewhere | **Probably global or near-global, confidence medium** | Major icehouse interval following atmospheric oxygenation; may have included low-latitude glaciation, but spatial reconstruction is uncertain. |
| **“Boring Billion” relative stability** | c. 1.85–0.85 Ga | Global Proterozoic sedimentary basins | **Global interval** | Long phase of relatively muted climate, tectonic, and biological change; low oxygen and limited climatic extremes compared with adjacent intervals. |
| **Sturtian Snowball Earth** | c. 717–660 Ma | Low-latitude glacial deposits on fragments of Rodinia; Australia, Laurentia, China, Namibia, Scotland/Ireland | **Global or near-global** | Severe glaciation reached low latitudes. The Snowball Earth interpretation is based partly on glacial deposits formed near the tropics and widespread cap carbonate aftermath. |
| **Marinoan Snowball Earth** | c. 650–635 Ma | Namibia, Australia, China, Canada, Svalbard, other Neoproterozoic basins | **Global or near-global** | Extreme icehouse followed by abrupt greenhouse deglaciation; cap carbonates record rapid post-glacial carbonate deposition in many regions. |
| **Ediacaran climate recovery** | c. 635–541 Ma | Global continental shelves; Namibia, Australia, China, Russia, Newfoundland | **Global, but regionally variable** | Post-Snowball greenhouse recovery, unstable carbon cycle, oxygenation changes, expansion of complex multicellular ecosystems. |
| **Cambrian warm climate / radiation** | c. 541 Ma | Low-latitude epicontinental seas; Laurentia, South China, Siberia, Gondwana margins | **Global biological event with regional environmental expression** | Generally warm greenhouse world; widespread shallow seas supported rapid animal diversification. |
| **Late Ordovician glaciation** | c. 445 Ma | Gondwana, especially North Africa / Sahara region when positioned near the South Pole | **Global climate impact, southern polar ice centre** | Southern Hemisphere glaciation, sea-level fall, cooling, then deglaciation; strongly linked to the Late Ordovician mass extinction. |
| **Late Devonian climate instability** | c. 372–359 Ma | Euramerica, North Africa, South China, marine basins with black shales | **Global but pulsed and uneven** | Repeated anoxia, carbon-cycle disturbance, cooling/warming pulses; stronger record in marine shelf settings. |
| **Late Paleozoic Ice Age** | c. 335–260 Ma | Gondwana: South America, Africa, India, Antarctica, Australia | **Global icehouse, southern Gondwanan ice centre** | Large Southern Hemisphere ice sheets, glacial–interglacial cycles, low sea levels, strong latitudinal climate gradients. |
| **End-Permian climate crisis** | c. 252 Ma | Siberian Traps as main volcanic anchor; global marine and terrestrial records | **Global** | Siberian volcanism released CO₂ and other gases; effects included long-term warming, ocean anoxia, acidification, and severe marine/terrestrial extinction. Some models include short volcanic winters before longer greenhouse warming. |
| **End-Triassic warming event** | c. 201 Ma | Central Atlantic Magmatic Province: eastern North America, northwest Africa, South America, Europe | **Global, LIP-driven** | CO₂-driven warming, ocean acidification, ecosystem disruption, major extinction; strongest geological anchor is the rifting Atlantic region. |
| **Toarcian Oceanic Anoxic Event** | c. 183 Ma | Europe, Tethys, Panthalassa margins; black shales in marine basins | **Global carbon-cycle event, basin-variable anoxia** | Greenhouse warming, enhanced weathering, marine anoxia, black shale deposition; strongest in restricted or productive marine basins. |
| **Cretaceous greenhouse world** | c. 145–66 Ma | Global oceans; Tethys, Western Interior Seaway, Pacific, Atlantic margins | **Global** | Warm poles, high sea levels, weak equator-to-pole temperature gradient, widespread shallow seas; regional aridity/humidity varied strongly. |
| **Cretaceous Oceanic Anoxic Events** | c. 120–90 Ma | Tethys, Atlantic, Pacific, North Africa, Europe, western North America | **Global carbon-cycle events, not uniformly anoxic everywhere** | Black shale deposition and low-oxygen waters in many basins, but some regions remained oxic. |
| **K–Pg impact winter and recovery** | 66 Ma | Chicxulub, Yucatán, Mexico; global iridium/ejecta layer | **Global** | Short-term darkness, cooling, photosynthetic collapse, acid rain, wildfires in some regions, followed by longer ecological and climatic recovery. |
| **Paleocene–Eocene Thermal Maximum** | c. 56 Ma | Global marine isotope records; North Atlantic, Arctic Ocean, Tethys, continental basins | **Global** | Rapid carbon release, global warming, ocean acidification, carbonate dissolution, intensified hydrological cycle, strong polar amplification. Arctic records suggest methane-cycle feedbacks may have amplified warming. |
| **Early Eocene Climatic Optimum** | c. 53–49 Ma | Global marine isotope records; Arctic, Antarctic margins, Tethys, continental floras | **Global greenhouse maximum** | Very warm high latitudes, reduced polar ice, warm oceans, subtropical to temperate vegetation at high latitudes. |
| **Eocene–Oligocene transition** | c. 34 Ma | Antarctica; Southern Ocean; global marine isotope records | **Global shift, Antarctic ice centre** | Major cooling and Antarctic ice-sheet expansion; a transition from greenhouse to icehouse climate. Antarctica was the focal region, but ocean circulation and sea level changed globally. |
| **Miocene Climatic Optimum** | c. 17–14 Ma | Global ocean records; Antarctica, North Atlantic, Tethys/Paratethys, continental floras | **Global warm interval** | Warmer climate, reduced Antarctic ice relative to later Miocene, followed by cooling and Antarctic ice expansion. |
| **Pliocene warm period** | c. 5.3–2.6 Ma; especially c. 3.3–3.0 Ma | Global marine records; Arctic, North Atlantic, East Africa, Australia, Pacific | **Global, useful future analogue** | Warmer than preindustrial climate, higher sea level, reduced ice sheets, strong high-latitude warming; regional rainfall patterns differed from today. |
| **Quaternary glacial cycles** | 2.58 Ma–present | Northern Hemisphere ice sheets; Antarctica; global marine isotope record | **Global cycles, northern ice-sheet emphasis** | Orbital forcing drove repeated glacial–interglacial cycles; large ice sheets in North America and Eurasia, Antarctic ice persistence, tropical rainfall belts shifted. |
| **Last Interglacial** | c. 129–116 ka | Global sea-level and coral records; polar ice cores; coastal terraces | **Global interglacial** | Warmer polar regions, higher sea level, reduced ice volume; sea level likely several metres above present. |
| **Last Glacial Maximum** | c. 26.5–19 ka | Laurentide and Cordilleran ice sheets, Fennoscandian ice sheet, Antarctic ice, alpine glaciers | **Global glacial maximum, strongest in high northern latitudes** | Major ice sheets covered North America and northern Europe; sea level was roughly 120–130 m lower; tropical belts shifted and many regions became colder/drier. |
| **Late-glacial abrupt climate shifts** | c. 14.7–11.7 ka | North Atlantic, Greenland ice cores, Europe, North America, monsoon regions | **Global teleconnections, North Atlantic anchor** | Bølling–Allerød warming and Younger Dryas cooling were strongest around the North Atlantic but affected monsoons, vegetation zones, and ocean circulation globally. |
| **Holocene climatic stability** | 11.7 ka–present | Global; especially ice cores, lake records, speleothems, pollen, marine sediments | **Global interglacial, regionally variable** | Relatively stable climate compared with glacial cycles; regional events include African Humid Period, mid-Holocene warmth, neoglacial cooling, Little Ice Age. |
| **Anthropogenic global warming** | c. 1850 CE–present | Global instrumental record; ice cores; oceans; atmosphere | **Global, human-driven** | CO₂ rise, global warming, ocean heat uptake, sea-level rise, cryosphere loss, regional extremes, polar amplification. |

---

## Useful classification fields

For the app, do not use only `location`, because that can be misleading. Use separate fields:

```yaml
geographic_anchor:
  description: where the cause or strongest evidence is located

spatial_extent:
  allowed_values:
    - local
    - regional
    - ocean_basin
    - hemispheric
    - near_global
    - global

spatial_confidence:
  allowed_values:
    - low
    - medium
    - high

latitudinal_expression:
  allowed_keys:
    - tropics
    - mid_latitudes
    - high_latitudes
    - polar

hemispheric_bias:
  allowed_values:
    - northern
    - southern
    - both
    - unclear

manifestation_type:
  allowed_values:
    - warming
    - cooling
    - glaciation
    - deglaciation
    - aridification
    - humidification
    - ocean_anoxia
    - ocean_acidification
    - sea_level_fall
    - sea_level_rise
    - carbon_cycle_disruption
    - impact_winter
```

---

## Example: why this matters

A simple event name such as **“Late Ordovician glaciation”** hides the geography:

```yaml
name: Late Ordovician glaciation
start_ma: 445
geographic_anchor:
  - Gondwana
  - North Africa
  - South Polar region
spatial_extent: global
hemispheric_bias: southern
manifestation_type:
  - cooling
  - glaciation
  - sea_level_fall
regional_expression:
  Gondwana: major ice sheet growth
  low_latitude_shelves: marine habitat loss from sea-level fall
  global_oceans: cooling and ecological disruption
```

That is much richer than simply saying:

```yaml
location: global
```

because the **ice was regionally centred**, while the **sea-level and extinction consequences were global**.
