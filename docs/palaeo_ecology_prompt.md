# Palaeo-ecology data generation prompt

Use the following JSON request to generate the contents of `data/paleo_ecology.yaml`. Return only valid YAML matching the requested `yaml_shape`.

```json
{
  "task": "Generate paleo-ecology data for the geological divisions listed below.",
  "output_file": "data/paleo_ecology.yaml",
  "requirements": [
    "Return YAML only, with root key paleo_ecology.",
    "Use current peer-reviewed synthesis values where possible.",
    "Return approximate values suitable for an educational deep-time timeline, not high-precision climate modelling.",
    "Use null where evidence is too uncertain rather than inventing precision.",
    "Express all numeric environmental fields as signed deltas from the present global baseline.",
    "Use Ma-aware stage context: values should represent average conditions across the Stage/Age, not a single boundary value.",
    "Use avg_co2_ppm for atmospheric CO2 concentration in ppm.",
    "Include a concise confidence value: high, moderate, low, or very_low.",
    "Include a short note explaining major uncertainty or important palaeo-ecological context."
  ],
  "fields_to_return": {
    "rank": "Geologic rank exactly as supplied.",
    "name": "Division name exactly as supplied.",
    "path": "Full hierarchy path exactly as supplied.",
    "avg_temp_delta_c": "Signed average global surface temperature delta from present, in degrees Celsius. Example: +6.5.",
    "avg_humidity_delta_percent": "Signed average global humidity delta from present, in percent. Example: +8.0. Use null when not defensible.",
    "avg_co2_ppm": "Average atmospheric CO2 concentration in ppm. Use null when not defensible.",
    "sea_level_delta_m": "Signed average eustatic sea-level delta from present, in metres. Example: +80.0 or -60.0.",
    "icehouse_greenhouse_state": "One of: icehouse, cool_greenhouse, greenhouse, hothouse, transitional, uncertain.",
    "dominant_ecology": "Brief phrase describing dominant global ecological setting.",
    "confidence": "high, moderate, low, or very_low.",
    "note": "One short sentence explaining uncertainty or context.",
    "sources": "Short list of source names or DOI-style references used."
  },
  "yaml_shape": {
    "paleo_ecology": [
      {
        "rank": "stage",
        "name": "Example Stage",
        "path": [
          "Eon",
          "Era",
          "Period",
          "Epoch",
          "Stage"
        ],
        "avg_temp_delta_c": "+0.0",
        "avg_humidity_delta_percent": "+0.0",
        "avg_co2_ppm": 400,
        "sea_level_delta_m": "+0.0",
        "icehouse_greenhouse_state": "uncertain",
        "dominant_ecology": "brief ecological summary",
        "confidence": "low",
        "note": "brief note",
        "sources": [
          "source 1",
          "source 2"
        ]
      }
    ]
  },
  "divisions": [
    {
      "name": "Fortunian",
      "rank": "stage",
      "path": [
        "Phanerozoic",
        "Paleozoic",
        "Cambrian",
        "Terreneuvian",
        "Fortunian"
      ]
    },
    {
      "name": "Stage 2",
      "rank": "stage",
      "path": [
        "Phanerozoic",
        "Paleozoic",
        "Cambrian",
        "Terreneuvian",
        "Stage 2"
      ]
    },
    {
      "name": "Stage 3",
      "rank": "stage",
      "path": [
        "Phanerozoic",
        "Paleozoic",
        "Cambrian",
        "Series 2",
        "Stage 3"
      ]
    },
    {
      "name": "Stage 4",
      "rank": "stage",
      "path": [
        "Phanerozoic",
        "Paleozoic",
        "Cambrian",
        "Series 2",
        "Stage 4"
      ]
    },
    {
      "name": "Wuliuan",
      "rank": "stage",
      "path": [
        "Phanerozoic",
        "Paleozoic",
        "Cambrian",
        "Miaolingian",
        "Wuliuan"
      ]
    },
    {
      "name": "Drumian",
      "rank": "stage",
      "path": [
        "Phanerozoic",
        "Paleozoic",
        "Cambrian",
        "Miaolingian",
        "Drumian"
      ]
    },
    {
      "name": "Guzhangian",
      "rank": "stage",
      "path": [
        "Phanerozoic",
        "Paleozoic",
        "Cambrian",
        "Miaolingian",
        "Guzhangian"
      ]
    },
    {
      "name": "Paibian",
      "rank": "stage",
      "path": [
        "Phanerozoic",
        "Paleozoic",
        "Cambrian",
        "Furongian",
        "Paibian"
      ]
    },
    {
      "name": "Jiangshanian",
      "rank": "stage",
      "path": [
        "Phanerozoic",
        "Paleozoic",
        "Cambrian",
        "Furongian",
        "Jiangshanian"
      ]
    },
    {
      "name": "Stage 10",
      "rank": "stage",
      "path": [
        "Phanerozoic",
        "Paleozoic",
        "Cambrian",
        "Furongian",
        "Stage 10"
      ]
    },
    {
      "name": "Tremadocian",
      "rank": "stage",
      "path": [
        "Phanerozoic",
        "Paleozoic",
        "Ordovician",
        "Lower",
        "Tremadocian"
      ]
    },
    {
      "name": "Floian",
      "rank": "stage",
      "path": [
        "Phanerozoic",
        "Paleozoic",
        "Ordovician",
        "Lower",
        "Floian"
      ]
    },
    {
      "name": "Dapingian",
      "rank": "stage",
      "path": [
        "Phanerozoic",
        "Paleozoic",
        "Ordovician",
        "Middle",
        "Dapingian"
      ]
    },
    {
      "name": "Darriwilian",
      "rank": "stage",
      "path": [
        "Phanerozoic",
        "Paleozoic",
        "Ordovician",
        "Middle",
        "Darriwilian"
      ]
    },
    {
      "name": "Sandbian",
      "rank": "stage",
      "path": [
        "Phanerozoic",
        "Paleozoic",
        "Ordovician",
        "Upper",
        "Sandbian"
      ]
    },
    {
      "name": "Katian",
      "rank": "stage",
      "path": [
        "Phanerozoic",
        "Paleozoic",
        "Ordovician",
        "Upper",
        "Katian"
      ]
    },
    {
      "name": "Hirnantian",
      "rank": "stage",
      "path": [
        "Phanerozoic",
        "Paleozoic",
        "Ordovician",
        "Upper",
        "Hirnantian"
      ]
    },
    {
      "name": "Rhuddanian",
      "rank": "stage",
      "path": [
        "Phanerozoic",
        "Paleozoic",
        "Silurian",
        "Llandovery",
        "Rhuddanian"
      ]
    },
    {
      "name": "Aeronian",
      "rank": "stage",
      "path": [
        "Phanerozoic",
        "Paleozoic",
        "Silurian",
        "Llandovery",
        "Aeronian"
      ]
    },
    {
      "name": "Telychian",
      "rank": "stage",
      "path": [
        "Phanerozoic",
        "Paleozoic",
        "Silurian",
        "Llandovery",
        "Telychian"
      ]
    },
    {
      "name": "Sheinwoodian",
      "rank": "stage",
      "path": [
        "Phanerozoic",
        "Paleozoic",
        "Silurian",
        "Wenlock",
        "Sheinwoodian"
      ]
    },
    {
      "name": "Homerian",
      "rank": "stage",
      "path": [
        "Phanerozoic",
        "Paleozoic",
        "Silurian",
        "Wenlock",
        "Homerian"
      ]
    },
    {
      "name": "Gorstian",
      "rank": "stage",
      "path": [
        "Phanerozoic",
        "Paleozoic",
        "Silurian",
        "Ludlow",
        "Gorstian"
      ]
    },
    {
      "name": "Ludfordian",
      "rank": "stage",
      "path": [
        "Phanerozoic",
        "Paleozoic",
        "Silurian",
        "Ludlow",
        "Ludfordian"
      ]
    },
    {
      "name": "Kopanina*",
      "rank": "stage",
      "path": [
        "Phanerozoic",
        "Paleozoic",
        "Silurian",
        "Přídolí",
        "Kopanina*"
      ]
    },
    {
      "name": "Přídolí*",
      "rank": "stage",
      "path": [
        "Phanerozoic",
        "Paleozoic",
        "Silurian",
        "Přídolí",
        "Přídolí*"
      ]
    },
    {
      "name": "Lochkovian",
      "rank": "stage",
      "path": [
        "Phanerozoic",
        "Paleozoic",
        "Devonian",
        "Lower",
        "Lochkovian"
      ]
    },
    {
      "name": "Emsian",
      "rank": "stage",
      "path": [
        "Phanerozoic",
        "Paleozoic",
        "Devonian",
        "Lower",
        "Emsian"
      ]
    },
    {
      "name": "Pragian",
      "rank": "stage",
      "path": [
        "Phanerozoic",
        "Paleozoic",
        "Devonian",
        "Lower",
        "Pragian"
      ]
    },
    {
      "name": "Eifelian",
      "rank": "stage",
      "path": [
        "Phanerozoic",
        "Paleozoic",
        "Devonian",
        "Middle",
        "Eifelian"
      ]
    },
    {
      "name": "Givetian",
      "rank": "stage",
      "path": [
        "Phanerozoic",
        "Paleozoic",
        "Devonian",
        "Middle",
        "Givetian"
      ]
    },
    {
      "name": "Frasnian",
      "rank": "stage",
      "path": [
        "Phanerozoic",
        "Paleozoic",
        "Devonian",
        "Upper",
        "Frasnian"
      ]
    },
    {
      "name": "Famennian",
      "rank": "stage",
      "path": [
        "Phanerozoic",
        "Paleozoic",
        "Devonian",
        "Upper",
        "Famennian"
      ]
    },
    {
      "name": "Tournaisian",
      "rank": "stage",
      "path": [
        "Phanerozoic",
        "Paleozoic",
        "Carboniferous",
        "Mississippian",
        "Tournaisian"
      ]
    },
    {
      "name": "Visean",
      "rank": "stage",
      "path": [
        "Phanerozoic",
        "Paleozoic",
        "Carboniferous",
        "Mississippian",
        "Visean"
      ]
    },
    {
      "name": "Serpukhovian",
      "rank": "stage",
      "path": [
        "Phanerozoic",
        "Paleozoic",
        "Carboniferous",
        "Mississippian",
        "Serpukhovian"
      ]
    },
    {
      "name": "Bashkirian",
      "rank": "stage",
      "path": [
        "Phanerozoic",
        "Paleozoic",
        "Carboniferous",
        "Pennsylvanian",
        "Bashkirian"
      ]
    },
    {
      "name": "Moscovian",
      "rank": "stage",
      "path": [
        "Phanerozoic",
        "Paleozoic",
        "Carboniferous",
        "Pennsylvanian",
        "Moscovian"
      ]
    },
    {
      "name": "Kasimovian",
      "rank": "stage",
      "path": [
        "Phanerozoic",
        "Paleozoic",
        "Carboniferous",
        "Pennsylvanian",
        "Kasimovian"
      ]
    },
    {
      "name": "Gzhelian",
      "rank": "stage",
      "path": [
        "Phanerozoic",
        "Paleozoic",
        "Carboniferous",
        "Pennsylvanian",
        "Gzhelian"
      ]
    },
    {
      "name": "Asselian",
      "rank": "stage",
      "path": [
        "Phanerozoic",
        "Paleozoic",
        "Permian",
        "Cisuralian",
        "Asselian"
      ]
    },
    {
      "name": "Sakmarian",
      "rank": "stage",
      "path": [
        "Phanerozoic",
        "Paleozoic",
        "Permian",
        "Cisuralian",
        "Sakmarian"
      ]
    },
    {
      "name": "Artinskian",
      "rank": "stage",
      "path": [
        "Phanerozoic",
        "Paleozoic",
        "Permian",
        "Cisuralian",
        "Artinskian"
      ]
    },
    {
      "name": "Kungurian",
      "rank": "stage",
      "path": [
        "Phanerozoic",
        "Paleozoic",
        "Permian",
        "Cisuralian",
        "Kungurian"
      ]
    },
    {
      "name": "Roadian",
      "rank": "stage",
      "path": [
        "Phanerozoic",
        "Paleozoic",
        "Permian",
        "Guadalupian",
        "Roadian"
      ]
    },
    {
      "name": "Wordian",
      "rank": "stage",
      "path": [
        "Phanerozoic",
        "Paleozoic",
        "Permian",
        "Guadalupian",
        "Wordian"
      ]
    },
    {
      "name": "Capitanian",
      "rank": "stage",
      "path": [
        "Phanerozoic",
        "Paleozoic",
        "Permian",
        "Guadalupian",
        "Capitanian"
      ]
    },
    {
      "name": "Wuchiapingian",
      "rank": "stage",
      "path": [
        "Phanerozoic",
        "Paleozoic",
        "Permian",
        "Lopingian",
        "Wuchiapingian"
      ]
    },
    {
      "name": "Changhsingian",
      "rank": "stage",
      "path": [
        "Phanerozoic",
        "Paleozoic",
        "Permian",
        "Lopingian",
        "Changhsingian"
      ]
    },
    {
      "name": "Induan",
      "rank": "stage",
      "path": [
        "Phanerozoic",
        "Mesozoic",
        "Triassic",
        "Lower",
        "Induan"
      ]
    },
    {
      "name": "Olenekian",
      "rank": "stage",
      "path": [
        "Phanerozoic",
        "Mesozoic",
        "Triassic",
        "Lower",
        "Olenekian"
      ]
    },
    {
      "name": "Anisian",
      "rank": "stage",
      "path": [
        "Phanerozoic",
        "Mesozoic",
        "Triassic",
        "Middle",
        "Anisian"
      ]
    },
    {
      "name": "Ladinian",
      "rank": "stage",
      "path": [
        "Phanerozoic",
        "Mesozoic",
        "Triassic",
        "Middle",
        "Ladinian"
      ]
    },
    {
      "name": "Carnian",
      "rank": "stage",
      "path": [
        "Phanerozoic",
        "Mesozoic",
        "Triassic",
        "Upper",
        "Carnian"
      ]
    },
    {
      "name": "Norian",
      "rank": "stage",
      "path": [
        "Phanerozoic",
        "Mesozoic",
        "Triassic",
        "Upper",
        "Norian"
      ]
    },
    {
      "name": "Rhaetian",
      "rank": "stage",
      "path": [
        "Phanerozoic",
        "Mesozoic",
        "Triassic",
        "Upper",
        "Rhaetian"
      ]
    },
    {
      "name": "Hettangian",
      "rank": "stage",
      "path": [
        "Phanerozoic",
        "Mesozoic",
        "Jurassic",
        "Lower",
        "Hettangian"
      ]
    },
    {
      "name": "Sinemurian",
      "rank": "stage",
      "path": [
        "Phanerozoic",
        "Mesozoic",
        "Jurassic",
        "Lower",
        "Sinemurian"
      ]
    },
    {
      "name": "Pliensbachian",
      "rank": "stage",
      "path": [
        "Phanerozoic",
        "Mesozoic",
        "Jurassic",
        "Lower",
        "Pliensbachian"
      ]
    },
    {
      "name": "Toarcian",
      "rank": "stage",
      "path": [
        "Phanerozoic",
        "Mesozoic",
        "Jurassic",
        "Lower",
        "Toarcian"
      ]
    },
    {
      "name": "Aalenian",
      "rank": "stage",
      "path": [
        "Phanerozoic",
        "Mesozoic",
        "Jurassic",
        "Middle",
        "Aalenian"
      ]
    },
    {
      "name": "Bajocian",
      "rank": "stage",
      "path": [
        "Phanerozoic",
        "Mesozoic",
        "Jurassic",
        "Middle",
        "Bajocian"
      ]
    },
    {
      "name": "Bathonian",
      "rank": "stage",
      "path": [
        "Phanerozoic",
        "Mesozoic",
        "Jurassic",
        "Middle",
        "Bathonian"
      ]
    },
    {
      "name": "Callovian",
      "rank": "stage",
      "path": [
        "Phanerozoic",
        "Mesozoic",
        "Jurassic",
        "Middle",
        "Callovian"
      ]
    },
    {
      "name": "Oxfordian",
      "rank": "stage",
      "path": [
        "Phanerozoic",
        "Mesozoic",
        "Jurassic",
        "Upper",
        "Oxfordian"
      ]
    },
    {
      "name": "Kimmeridgian",
      "rank": "stage",
      "path": [
        "Phanerozoic",
        "Mesozoic",
        "Jurassic",
        "Upper",
        "Kimmeridgian"
      ]
    },
    {
      "name": "Tithonian",
      "rank": "stage",
      "path": [
        "Phanerozoic",
        "Mesozoic",
        "Jurassic",
        "Upper",
        "Tithonian"
      ]
    },
    {
      "name": "Berriasian",
      "rank": "stage",
      "path": [
        "Phanerozoic",
        "Mesozoic",
        "Cretaceous",
        "Lower",
        "Berriasian"
      ]
    },
    {
      "name": "Valanginian",
      "rank": "stage",
      "path": [
        "Phanerozoic",
        "Mesozoic",
        "Cretaceous",
        "Lower",
        "Valanginian"
      ]
    },
    {
      "name": "Hauterivian",
      "rank": "stage",
      "path": [
        "Phanerozoic",
        "Mesozoic",
        "Cretaceous",
        "Lower",
        "Hauterivian"
      ]
    },
    {
      "name": "Barremian",
      "rank": "stage",
      "path": [
        "Phanerozoic",
        "Mesozoic",
        "Cretaceous",
        "Lower",
        "Barremian"
      ]
    },
    {
      "name": "Aptian",
      "rank": "stage",
      "path": [
        "Phanerozoic",
        "Mesozoic",
        "Cretaceous",
        "Lower",
        "Aptian"
      ]
    },
    {
      "name": "Albian",
      "rank": "stage",
      "path": [
        "Phanerozoic",
        "Mesozoic",
        "Cretaceous",
        "Lower",
        "Albian"
      ]
    },
    {
      "name": "Cenomanian",
      "rank": "stage",
      "path": [
        "Phanerozoic",
        "Mesozoic",
        "Cretaceous",
        "Upper",
        "Cenomanian"
      ]
    },
    {
      "name": "Turonian",
      "rank": "stage",
      "path": [
        "Phanerozoic",
        "Mesozoic",
        "Cretaceous",
        "Upper",
        "Turonian"
      ]
    },
    {
      "name": "Coniacian",
      "rank": "stage",
      "path": [
        "Phanerozoic",
        "Mesozoic",
        "Cretaceous",
        "Upper",
        "Coniacian"
      ]
    },
    {
      "name": "Santonian",
      "rank": "stage",
      "path": [
        "Phanerozoic",
        "Mesozoic",
        "Cretaceous",
        "Upper",
        "Santonian"
      ]
    },
    {
      "name": "Campanian",
      "rank": "stage",
      "path": [
        "Phanerozoic",
        "Mesozoic",
        "Cretaceous",
        "Upper",
        "Campanian"
      ]
    },
    {
      "name": "Maastrichtian",
      "rank": "stage",
      "path": [
        "Phanerozoic",
        "Mesozoic",
        "Cretaceous",
        "Upper",
        "Maastrichtian"
      ]
    },
    {
      "name": "Danian",
      "rank": "stage",
      "path": [
        "Phanerozoic",
        "Cenozoic",
        "Paleogene",
        "Paleocene",
        "Danian"
      ]
    },
    {
      "name": "Selandian",
      "rank": "stage",
      "path": [
        "Phanerozoic",
        "Cenozoic",
        "Paleogene",
        "Paleocene",
        "Selandian"
      ]
    },
    {
      "name": "Thanetian",
      "rank": "stage",
      "path": [
        "Phanerozoic",
        "Cenozoic",
        "Paleogene",
        "Paleocene",
        "Thanetian"
      ]
    },
    {
      "name": "Ypresian",
      "rank": "stage",
      "path": [
        "Phanerozoic",
        "Cenozoic",
        "Paleogene",
        "Eocene",
        "Ypresian"
      ]
    },
    {
      "name": "Lutetian",
      "rank": "stage",
      "path": [
        "Phanerozoic",
        "Cenozoic",
        "Paleogene",
        "Eocene",
        "Lutetian"
      ]
    },
    {
      "name": "Bartonian",
      "rank": "stage",
      "path": [
        "Phanerozoic",
        "Cenozoic",
        "Paleogene",
        "Eocene",
        "Bartonian"
      ]
    },
    {
      "name": "Priabonian",
      "rank": "stage",
      "path": [
        "Phanerozoic",
        "Cenozoic",
        "Paleogene",
        "Eocene",
        "Priabonian"
      ]
    },
    {
      "name": "Rupelian",
      "rank": "stage",
      "path": [
        "Phanerozoic",
        "Cenozoic",
        "Paleogene",
        "Oligocene",
        "Rupelian"
      ]
    },
    {
      "name": "Chattian",
      "rank": "stage",
      "path": [
        "Phanerozoic",
        "Cenozoic",
        "Paleogene",
        "Oligocene",
        "Chattian"
      ]
    },
    {
      "name": "Aquitanian",
      "rank": "stage",
      "path": [
        "Phanerozoic",
        "Cenozoic",
        "Neogene",
        "Miocene",
        "Aquitanian"
      ]
    },
    {
      "name": "Burdigalian",
      "rank": "stage",
      "path": [
        "Phanerozoic",
        "Cenozoic",
        "Neogene",
        "Miocene",
        "Burdigalian"
      ]
    },
    {
      "name": "Langhian",
      "rank": "stage",
      "path": [
        "Phanerozoic",
        "Cenozoic",
        "Neogene",
        "Miocene",
        "Langhian"
      ]
    },
    {
      "name": "Serravallian",
      "rank": "stage",
      "path": [
        "Phanerozoic",
        "Cenozoic",
        "Neogene",
        "Miocene",
        "Serravallian"
      ]
    },
    {
      "name": "Tortonian",
      "rank": "stage",
      "path": [
        "Phanerozoic",
        "Cenozoic",
        "Neogene",
        "Miocene",
        "Tortonian"
      ]
    },
    {
      "name": "Messinian",
      "rank": "stage",
      "path": [
        "Phanerozoic",
        "Cenozoic",
        "Neogene",
        "Miocene",
        "Messinian"
      ]
    },
    {
      "name": "Zanclean",
      "rank": "stage",
      "path": [
        "Phanerozoic",
        "Cenozoic",
        "Neogene",
        "Pliocene",
        "Zanclean"
      ]
    },
    {
      "name": "Piacenzian",
      "rank": "stage",
      "path": [
        "Phanerozoic",
        "Cenozoic",
        "Neogene",
        "Pliocene",
        "Piacenzian"
      ]
    },
    {
      "name": "Gelasian",
      "rank": "stage",
      "path": [
        "Phanerozoic",
        "Cenozoic",
        "Quaternary",
        "Pleistocene",
        "Gelasian"
      ]
    },
    {
      "name": "Calabrian",
      "rank": "stage",
      "path": [
        "Phanerozoic",
        "Cenozoic",
        "Quaternary",
        "Pleistocene",
        "Calabrian"
      ]
    },
    {
      "name": "Chibanian",
      "rank": "stage",
      "path": [
        "Phanerozoic",
        "Cenozoic",
        "Quaternary",
        "Pleistocene",
        "Chibanian"
      ]
    },
    {
      "name": "Upper",
      "rank": "stage",
      "path": [
        "Phanerozoic",
        "Cenozoic",
        "Quaternary",
        "Pleistocene",
        "Upper"
      ]
    },
    {
      "name": "Greenlandian",
      "rank": "stage",
      "path": [
        "Phanerozoic",
        "Cenozoic",
        "Quaternary",
        "Holocene",
        "Greenlandian"
      ]
    },
    {
      "name": "Northgrippian",
      "rank": "stage",
      "path": [
        "Phanerozoic",
        "Cenozoic",
        "Quaternary",
        "Holocene",
        "Northgrippian"
      ]
    },
    {
      "name": "Meghalayan",
      "rank": "stage",
      "path": [
        "Phanerozoic",
        "Cenozoic",
        "Quaternary",
        "Holocene",
        "Meghalayan"
      ]
    }
  ]
}
```
