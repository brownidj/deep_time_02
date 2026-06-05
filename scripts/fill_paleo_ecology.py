#!/usr/bin/env python3
from pathlib import Path
import sys
import yaml


DATA_PATH = Path("data/paleo_ecology.yaml")
TIME_DIVISIONS_PATH = Path("data/time_divisions.yaml")
ROOT_KEY = "paleo_ecology"
GENERATED_RANKS = {"eon", "era", "period", "age", "stage"}
LOWER_RANKS = {"age", "stage"}

SOURCES = {
    "temperature": "Scotese et al. 2021 Phanerozoic temperature reconstruction",
    "co2": "Foster et al. 2017 Phanerozoic CO2 synthesis",
    "sea_level_paleozoic": "Haq and Schutter 2008 Paleozoic sea-level synthesis",
    "sea_level_phanerozoic": "van der Meer et al. 2022 Phanerozoic sea-level synthesis",
    "holocene": "Holocene climate and sea-level synthesis",
}

ENV_KEYS = [
    "avg_temp_delta_c",
    "avg_humidity_delta_percent",
    "avg_co2_ppm",
    "sea_level_delta_m",
    "icehouse_greenhouse_state",
    "dominant_ecology",
    "confidence",
    "note",
    "sources",
]


def path_contains(row, value):
    return value in (row.get("path") or [])


def stage(row):
    return row.get("name") or row.get("stage")


def rank(row):
    return row.get("rank") or "stage"


def blank(value):
    return value is None or value == "" or value == []


def weak(value):
    return blank(value) or value == "uncertain" or value == "very_low"


def set_if_missing(row, values, overwrite=False):
    changed = False
    for key, value in values.items():
        current = row.get(key)
        should_set = overwrite
        if key in {"icehouse_greenhouse_state", "confidence"}:
            should_set = overwrite or weak(current)
        elif key == "sources":
            should_set = overwrite or blank(current)
        else:
            should_set = overwrite or blank(current)

        if should_set:
            row[key] = value
            changed = True
    return changed


def common_sources(row):
    if (
        path_contains(row, "Cambrian")
        or path_contains(row, "Mesozoic")
        or path_contains(row, "Cenozoic")
    ):
        sea = SOURCES["sea_level_phanerozoic"]
    else:
        sea = SOURCES["sea_level_paleozoic"]
    return [SOURCES["temperature"], SOURCES["co2"], sea]


def row_key(row):
    return (rank(row), tuple(row.get("path") or []))


def load_existing_rows():
    if not DATA_PATH.exists():
        return []
    data = yaml.safe_load(DATA_PATH.read_text(encoding="utf-8")) or {}
    rows = data.get(ROOT_KEY)
    if not isinstance(rows, list):
        raise SystemExit("Expected root key " + ROOT_KEY + " to contain a list")
    return rows


def generated_rows_from_time_divisions():
    if not TIME_DIVISIONS_PATH.exists():
        raise SystemExit("Could not find " + str(TIME_DIVISIONS_PATH))
    data = yaml.safe_load(TIME_DIVISIONS_PATH.read_text(encoding="utf-8")) or {}
    rows = []

    def walk(nodes, path=()):
        for node in nodes or []:
            node_rank = node.get("rank")
            name = node.get("name")
            if not isinstance(name, str) or not isinstance(node_rank, str):
                continue
            next_path = path + (name,)
            if node_rank in GENERATED_RANKS:
                rows.append(
                    {
                        "rank": node_rank,
                        "name": name,
                        "path": list(next_path),
                    }
                )
            walk(node.get("children") or [], next_path)

    walk(data.get("eons") or [])
    return rows


def recreate_rows():
    existing_by_key = {row_key(row): row for row in load_existing_rows()}
    rows = []
    for row in generated_rows_from_time_divisions():
        existing = existing_by_key.get(row_key(row))
        if existing is not None:
            merged = dict(row)
            for key, value in existing.items():
                if key not in {"rank", "name", "path"}:
                    merged[key] = value
            rows.append(merged)
        else:
            rows.append(row)
    return rows


def load_rows(recreate=False):
    if recreate:
        return recreate_rows()
    if not DATA_PATH.exists():
        raise SystemExit("Could not find " + str(DATA_PATH))
    return load_existing_rows()


def values_for(row):
    s = stage(row)

    # Pre-Phanerozoic and higher-rank rows.
    # These are broad educational estimates only.
    # They are applied only where fields are missing unless --overwrite is used.

    if s == "Hadean":
        return {
            "avg_temp_delta_c": +80.0,
            "avg_humidity_delta_percent": None,
            "avg_co2_ppm": 100000,
            "sea_level_delta_m": None,
            "icehouse_greenhouse_state": "hothouse",
            "confidence": "very_low",
            "note": "Hadean environmental values are highly speculative; Earth was forming, cooling, and undergoing intense impacts and volcanism.",
            "sources": [
                "Early Earth atmosphere and ocean formation synthesis",
                "Hadean climate synthesis",
            ],
        }

    if s == "Archean":
        return {
            "avg_temp_delta_c": +20.0,
            "avg_humidity_delta_percent": None,
            "avg_co2_ppm": 50000,
            "sea_level_delta_m": None,
            "icehouse_greenhouse_state": "hothouse",
            "confidence": "very_low",
            "note": "Archean estimates are highly uncertain; high greenhouse gas levels probably helped compensate for the faint young Sun.",
            "sources": [
                "Archean climate synthesis",
                "Faint young Sun palaeoclimate synthesis",
            ],
        }

    if s == "Eoarchean":
        return {
            "avg_temp_delta_c": +30.0,
            "avg_humidity_delta_percent": None,
            "avg_co2_ppm": 80000,
            "sea_level_delta_m": None,
            "icehouse_greenhouse_state": "hothouse",
            "confidence": "very_low",
            "note": "Eoarchean conditions are very poorly constrained; values represent an extremely broad early Earth approximation.",
            "sources": [
                "Archean climate synthesis",
                "Early Earth atmosphere and ocean formation synthesis",
            ],
        }

    if s == "Paleoarchean":
        return {
            "avg_temp_delta_c": +25.0,
            "avg_humidity_delta_percent": None,
            "avg_co2_ppm": 60000,
            "sea_level_delta_m": None,
            "icehouse_greenhouse_state": "hothouse",
            "confidence": "very_low",
            "note": "Paleoarchean climate estimates are highly uncertain and represent broad greenhouse conditions rather than precise stage averages.",
            "sources": [
                "Archean climate synthesis",
                "Faint young Sun palaeoclimate synthesis",
            ],
        }

    if s == "Mesoarchean":
        return {
            "avg_temp_delta_c": +20.0,
            "avg_humidity_delta_percent": None,
            "avg_co2_ppm": 40000,
            "sea_level_delta_m": None,
            "icehouse_greenhouse_state": "hothouse",
            "confidence": "very_low",
            "note": "Mesoarchean values are broad approximations for a warm greenhouse Earth with limited continental land area.",
            "sources": [
                "Archean climate synthesis",
                "Faint young Sun palaeoclimate synthesis",
            ],
        }

    if s == "Neoarchean":
        return {
            "avg_temp_delta_c": +15.0,
            "avg_humidity_delta_percent": None,
            "avg_co2_ppm": 25000,
            "sea_level_delta_m": None,
            "icehouse_greenhouse_state": "greenhouse",
            "confidence": "very_low",
            "note": "Neoarchean values are approximate; late Archean climate may have included cooler intervals and early glaciation.",
            "sources": [
                "Archean climate synthesis",
                "Late Archean glaciation synthesis",
            ],
        }

    if s == "Proterozoic":
        return {
            "avg_temp_delta_c": +5.0,
            "avg_humidity_delta_percent": None,
            "avg_co2_ppm": 5000,
            "sea_level_delta_m": None,
            "icehouse_greenhouse_state": "transitional",
            "confidence": "very_low",
            "note": "Proterozoic values average several very different climate states, including greenhouse intervals and major glaciations.",
            "sources": [
                "Proterozoic climate synthesis",
                "Precambrian glaciation synthesis",
            ],
        }

    if s == "Paleoproterozoic":
        return {
            "avg_temp_delta_c": +2.0,
            "avg_humidity_delta_percent": None,
            "avg_co2_ppm": 8000,
            "sea_level_delta_m": None,
            "icehouse_greenhouse_state": "transitional",
            "confidence": "very_low",
            "note": "Paleoproterozoic values compress the Great Oxidation interval and major Huronian glaciations into one broad estimate.",
            "sources": [
                "Paleoproterozoic climate synthesis",
                "Great Oxidation Event synthesis",
                "Huronian glaciation synthesis",
            ],
        }

    if s in {"Siderian", "Rhyacian"}:
        return {
            "avg_temp_delta_c": -5.0,
            "avg_humidity_delta_percent": None,
            "avg_co2_ppm": 5000,
            "sea_level_delta_m": None,
            "icehouse_greenhouse_state": "icehouse",
            "confidence": "very_low",
            "note": "Values reflect broad Paleoproterozoic glacial influence during and after atmospheric oxygenation.",
            "sources": [
                "Great Oxidation Event synthesis",
                "Huronian glaciation synthesis",
            ],
        }

    if s in {"Orosirian", "Statherian"}:
        return {
            "avg_temp_delta_c": +5.0,
            "avg_humidity_delta_percent": None,
            "avg_co2_ppm": 8000,
            "sea_level_delta_m": None,
            "icehouse_greenhouse_state": "greenhouse",
            "confidence": "very_low",
            "note": "Values represent broad post-Huronian greenhouse recovery and stabilisation of Proterozoic environments.",
            "sources": [
                "Paleoproterozoic climate synthesis",
                "Proterozoic atmosphere synthesis",
            ],
        }

    if s == "Mesoproterozoic":
        return {
            "avg_temp_delta_c": +6.0,
            "avg_humidity_delta_percent": None,
            "avg_co2_ppm": 6000,
            "sea_level_delta_m": None,
            "icehouse_greenhouse_state": "greenhouse",
            "confidence": "very_low",
            "note": "Mesoproterozoic values are broad greenhouse estimates for the so-called boring billion interval.",
            "sources": [
                "Mesoproterozoic climate synthesis",
                "Proterozoic atmosphere synthesis",
            ],
        }

    if s in {"Calymmian", "Ectasian", "Stenian"}:
        return {
            "avg_temp_delta_c": +6.0,
            "avg_humidity_delta_percent": None,
            "avg_co2_ppm": 6000,
            "sea_level_delta_m": None,
            "icehouse_greenhouse_state": "greenhouse",
            "confidence": "very_low",
            "note": "Mesoproterozoic period-level values are broad greenhouse approximations with weak stage-scale constraints.",
            "sources": [
                "Mesoproterozoic climate synthesis",
                "Proterozoic atmosphere synthesis",
            ],
        }

    if s == "Neoproterozoic":
        return {
            "avg_temp_delta_c": +1.0,
            "avg_humidity_delta_percent": None,
            "avg_co2_ppm": 6000,
            "sea_level_delta_m": None,
            "icehouse_greenhouse_state": "transitional",
            "confidence": "very_low",
            "note": "Neoproterozoic values average greenhouse intervals with Cryogenian snowball Earth glaciations and late Ediacaran recovery.",
            "sources": [
                "Neoproterozoic climate synthesis",
                "Snowball Earth synthesis",
                "Ediacaran environment synthesis",
            ],
        }

    if s == "Tonian":
        return {
            "avg_temp_delta_c": +5.0,
            "avg_humidity_delta_percent": None,
            "avg_co2_ppm": 5000,
            "sea_level_delta_m": None,
            "icehouse_greenhouse_state": "greenhouse",
            "confidence": "very_low",
            "note": "Tonian values represent broad pre-Cryogenian greenhouse conditions before major snowball Earth glaciations.",
            "sources": [
                "Neoproterozoic climate synthesis",
                "Proterozoic atmosphere synthesis",
            ],
        }

    if s == "Cryogenian":
        return {
            "avg_temp_delta_c": -20.0,
            "avg_humidity_delta_percent": -15.0,
            "avg_co2_ppm": 8000,
            "sea_level_delta_m": -100.0,
            "icehouse_greenhouse_state": "icehouse",
            "confidence": "low",
            "note": "Cryogenian values represent snowball Earth glacial intervals; CO2 may have varied greatly between glacial buildup and deglaciation.",
            "sources": [
                "Snowball Earth synthesis",
                "Neoproterozoic glaciation synthesis",
            ],
        }

    if s == "Ediacaran":
        return {
            "avg_temp_delta_c": +4.0,
            "avg_humidity_delta_percent": +2.0,
            "avg_co2_ppm": 4000,
            "sea_level_delta_m": +30.0,
            "icehouse_greenhouse_state": "greenhouse",
            "confidence": "low",
            "note": "Ediacaran values reflect post-Cryogenian greenhouse recovery, rising oxygenation, and expansion of early animal ecosystems.",
            "sources": [
                "Ediacaran environment synthesis",
                "Neoproterozoic climate synthesis",
            ],
        }

    if path_contains(row, "Cambrian"):
        return {
            "avg_temp_delta_c": +8.0,
            "avg_humidity_delta_percent": +6.0,
            "avg_co2_ppm": 4000,
            "sea_level_delta_m": +80.0,
            "icehouse_greenhouse_state": "greenhouse",
            "confidence": "low",
            "note": "Broad Cambrian greenhouse estimate; stage-level values are approximate and should be refined from specialist datasets.",
            "sources": common_sources(row),
        }

    if path_contains(row, "Ordovician"):
        if s == "Hirnantian":
            return {
                "avg_temp_delta_c": +1.0,
                "avg_humidity_delta_percent": -5.0,
                "avg_co2_ppm": 1400,
                "sea_level_delta_m": -50.0,
                "icehouse_greenhouse_state": "icehouse",
                "confidence": "moderate",
                "note": "Hirnantian values reflect the short-lived end-Ordovician glaciation and associated sea-level fall.",
                "sources": common_sources(row),
            }
        return {
            "avg_temp_delta_c": +7.0,
            "avg_humidity_delta_percent": +5.0,
            "avg_co2_ppm": 3600,
            "sea_level_delta_m": +120.0,
            "icehouse_greenhouse_state": "greenhouse",
            "confidence": "low",
            "note": "Broad Ordovician greenhouse and high-sea-level estimate; values are approximate at stage scale.",
            "sources": common_sources(row),
        }

    if path_contains(row, "Silurian"):
        return {
            "avg_temp_delta_c": +6.0,
            "avg_humidity_delta_percent": +4.0,
            "avg_co2_ppm": 2200,
            "sea_level_delta_m": +90.0,
            "icehouse_greenhouse_state": "greenhouse",
            "confidence": "low",
            "note": "Broad Silurian warm greenhouse estimate; short-term glacio-eustatic changes are not represented here.",
            "sources": common_sources(row),
        }

    if path_contains(row, "Devonian"):
        if s == "Famennian":
            return {
                "avg_temp_delta_c": +3.0,
                "avg_humidity_delta_percent": +1.0,
                "avg_co2_ppm": 1200,
                "sea_level_delta_m": +40.0,
                "icehouse_greenhouse_state": "transitional",
                "confidence": "low",
                "note": "Broad latest Devonian estimate; Hangenberg cooling and extinction stress should be represented separately as events.",
                "sources": common_sources(row),
            }
        if s == "Frasnian":
            return {
                "avg_temp_delta_c": +5.0,
                "avg_humidity_delta_percent": +2.0,
                "avg_co2_ppm": 1400,
                "sea_level_delta_m": +70.0,
                "icehouse_greenhouse_state": "greenhouse",
                "confidence": "low",
                "note": "Broad late Devonian estimate; reef decline and Kellwasser environmental stress are not captured by average values alone.",
                "sources": common_sources(row),
            }
        return {
            "avg_temp_delta_c": +5.0,
            "avg_humidity_delta_percent": +3.0,
            "avg_co2_ppm": 1600,
            "sea_level_delta_m": +80.0,
            "icehouse_greenhouse_state": "greenhouse",
            "confidence": "low",
            "note": "Broad Devonian greenhouse estimate; regional humidity and sea-level conditions varied substantially.",
            "sources": common_sources(row),
        }

    if path_contains(row, "Carboniferous"):
        if s == "Tournaisian":
            return {
                "avg_temp_delta_c": +3.0,
                "avg_humidity_delta_percent": +4.0,
                "avg_co2_ppm": 1000,
                "sea_level_delta_m": +60.0,
                "icehouse_greenhouse_state": "transitional",
                "confidence": "low",
                "note": "Early Carboniferous estimate during transition toward late Paleozoic icehouse conditions.",
                "sources": common_sources(row),
            }
        if s in {"Visean", "Serpukhovian"}:
            return {
                "avg_temp_delta_c": +2.0,
                "avg_humidity_delta_percent": +6.0,
                "avg_co2_ppm": 800,
                "sea_level_delta_m": +50.0,
                "icehouse_greenhouse_state": "cool_greenhouse",
                "confidence": "low",
                "note": "Mississippian values reflect humid equatorial coal-forming settings superimposed on broad global cooling.",
                "sources": common_sources(row),
            }
        return {
            "avg_temp_delta_c": -1.0,
            "avg_humidity_delta_percent": +5.0,
            "avg_co2_ppm": 600,
            "sea_level_delta_m": +25.0,
            "icehouse_greenhouse_state": "icehouse",
            "confidence": "low",
            "note": "Pennsylvanian values reflect late Paleozoic icehouse climate with humid tropical coal swamps and strong regional contrasts.",
            "sources": common_sources(row),
        }

    if path_contains(row, "Permian"):
        if s in {"Asselian", "Sakmarian", "Artinskian", "Kungurian"}:
            return {
                "avg_temp_delta_c": +0.5,
                "avg_humidity_delta_percent": -2.0,
                "avg_co2_ppm": 700,
                "sea_level_delta_m": +10.0,
                "icehouse_greenhouse_state": "icehouse",
                "confidence": "low",
                "note": "Early Permian values reflect late Paleozoic icehouse conditions with increasing continental aridity.",
                "sources": common_sources(row),
            }
        if s in {"Roadian", "Wordian", "Capitanian"}:
            return {
                "avg_temp_delta_c": +3.0,
                "avg_humidity_delta_percent": -3.0,
                "avg_co2_ppm": 1000,
                "sea_level_delta_m": +20.0,
                "icehouse_greenhouse_state": "transitional",
                "confidence": "low",
                "note": "Middle Permian estimate during warming and weakening of late Paleozoic icehouse conditions.",
                "sources": common_sources(row),
            }
        return {
            "avg_temp_delta_c": +5.0,
            "avg_humidity_delta_percent": -4.0,
            "avg_co2_ppm": 1400,
            "sea_level_delta_m": +15.0,
            "icehouse_greenhouse_state": "greenhouse",
            "confidence": "low",
            "note": "Late Permian values reflect warming, aridity, and environmental instability before the end-Permian crisis.",
            "sources": common_sources(row),
        }

    if path_contains(row, "Triassic"):
        if s == "Induan":
            return {
                "avg_temp_delta_c": +8.0,
                "avg_humidity_delta_percent": -3.0,
                "avg_co2_ppm": 1800,
                "sea_level_delta_m": +20.0,
                "icehouse_greenhouse_state": "hothouse",
                "confidence": "low",
                "note": "Induan values reflect severe post-end-Permian greenhouse conditions and ecological stress.",
                "sources": common_sources(row),
            }
        return {
            "avg_temp_delta_c": +7.0,
            "avg_humidity_delta_percent": -2.0,
            "avg_co2_ppm": 1600,
            "sea_level_delta_m": +40.0,
            "icehouse_greenhouse_state": "hothouse",
            "confidence": "low",
            "note": "Broad Triassic hothouse estimate; aridity was strong across many continental interiors.",
            "sources": common_sources(row),
        }

    if path_contains(row, "Jurassic"):
        return {
            "avg_temp_delta_c": +6.0,
            "avg_humidity_delta_percent": +4.0,
            "avg_co2_ppm": 1600,
            "sea_level_delta_m": +80.0,
            "icehouse_greenhouse_state": "greenhouse",
            "confidence": "low",
            "note": "Broad Jurassic greenhouse estimate; short events such as the Toarcian OAE should be treated separately.",
            "sources": common_sources(row),
        }

    if path_contains(row, "Cretaceous"):
        if path_contains(row, "Lower"):
            return {
                "avg_temp_delta_c": +7.0,
                "avg_humidity_delta_percent": +5.0,
                "avg_co2_ppm": 1800,
                "sea_level_delta_m": +90.0,
                "icehouse_greenhouse_state": "greenhouse",
                "confidence": "low",
                "note": "Broad Early Cretaceous greenhouse estimate with rising sea levels and regional oceanic anoxic events.",
                "sources": common_sources(row),
            }
        return {
            "avg_temp_delta_c": +9.0,
            "avg_humidity_delta_percent": +7.0,
            "avg_co2_ppm": 2000,
            "sea_level_delta_m": +140.0,
            "icehouse_greenhouse_state": "hothouse",
            "confidence": "low",
            "note": "Broad Late Cretaceous hothouse estimate with very high sea levels; stage-scale variation is simplified.",
            "sources": common_sources(row),
        }

    if path_contains(row, "Paleocene"):
        return {
            "avg_temp_delta_c": +5.0,
            "avg_humidity_delta_percent": +4.0,
            "avg_co2_ppm": 1000,
            "sea_level_delta_m": +60.0,
            "icehouse_greenhouse_state": "greenhouse",
            "confidence": "moderate",
            "note": "Paleocene estimate after K-Pg recovery and before the early Eocene climatic optimum.",
            "sources": common_sources(row),
        }

    if path_contains(row, "Eocene"):
        if s == "Priabonian":
            return {
                "avg_temp_delta_c": +5.0,
                "avg_humidity_delta_percent": +2.0,
                "avg_co2_ppm": 800,
                "sea_level_delta_m": +40.0,
                "icehouse_greenhouse_state": "transitional",
                "confidence": "moderate",
                "note": "Late Eocene values reflect cooling toward the Eocene-Oligocene transition and Antarctic glaciation.",
                "sources": common_sources(row),
            }
        return {
            "avg_temp_delta_c": +9.0,
            "avg_humidity_delta_percent": +7.0,
            "avg_co2_ppm": 1200,
            "sea_level_delta_m": +70.0,
            "icehouse_greenhouse_state": "hothouse",
            "confidence": "moderate",
            "note": "Eocene values reflect globally warm greenhouse to hothouse conditions, especially in the early Eocene.",
            "sources": common_sources(row),
        }

    if path_contains(row, "Oligocene"):
        return {
            "avg_temp_delta_c": +2.0,
            "avg_humidity_delta_percent": -1.0,
            "avg_co2_ppm": 600,
            "sea_level_delta_m": +20.0,
            "icehouse_greenhouse_state": "icehouse",
            "confidence": "moderate",
            "note": "Oligocene values reflect cooler icehouse conditions after Antarctic glaciation began.",
            "sources": common_sources(row),
        }

    if path_contains(row, "Miocene"):
        if s in {"Aquitanian", "Burdigalian", "Langhian"}:
            return {
                "avg_temp_delta_c": +3.0,
                "avg_humidity_delta_percent": +2.0,
                "avg_co2_ppm": 500,
                "sea_level_delta_m": +25.0,
                "icehouse_greenhouse_state": "cool_greenhouse",
                "confidence": "moderate",
                "note": "Early to middle Miocene values include the Miocene climatic optimum and relatively warm global conditions.",
                "sources": common_sources(row),
            }
        return {
            "avg_temp_delta_c": +1.5,
            "avg_humidity_delta_percent": -1.0,
            "avg_co2_ppm": 400,
            "sea_level_delta_m": +10.0,
            "icehouse_greenhouse_state": "transitional",
            "confidence": "moderate",
            "note": "Late Miocene values reflect cooling, increasing aridity, and expansion of open habitats.",
            "sources": common_sources(row),
        }

    if path_contains(row, "Pliocene"):
        return {
            "avg_temp_delta_c": +1.5,
            "avg_humidity_delta_percent": +0.0,
            "avg_co2_ppm": 400,
            "sea_level_delta_m": +10.0,
            "icehouse_greenhouse_state": "cool_greenhouse",
            "confidence": "moderate",
            "note": "Pliocene values reflect warmer-than-present conditions before intensification of Northern Hemisphere glaciation.",
            "sources": common_sources(row),
        }

    if path_contains(row, "Pleistocene"):
        return {
            "avg_temp_delta_c": -2.0,
            "avg_humidity_delta_percent": -3.0,
            "avg_co2_ppm": 300,
            "sea_level_delta_m": -60.0,
            "icehouse_greenhouse_state": "icehouse",
            "confidence": "moderate",
            "note": "Pleistocene values average repeated glacial-interglacial cycles; individual interglacials were much closer to present.",
            "sources": common_sources(row),
        }

    if path_contains(row, "Holocene"):
        if s == "Greenlandian":
            return {
                "avg_temp_delta_c": -0.3,
                "avg_humidity_delta_percent": +0.0,
                "avg_co2_ppm": 300,
                "sea_level_delta_m": -20.0,
                "icehouse_greenhouse_state": "icehouse",
                "confidence": "moderate",
                "note": "Early Holocene values reflect warming after the last glacial period while sea level was still rising toward present.",
                "sources": [SOURCES["holocene"], SOURCES["co2"]],
            }
        if s == "Northgrippian":
            return {
                "avg_temp_delta_c": +0.0,
                "avg_humidity_delta_percent": +0.0,
                "avg_co2_ppm": 300,
                "sea_level_delta_m": -2.0,
                "icehouse_greenhouse_state": "icehouse",
                "confidence": "moderate",
                "note": "Middle Holocene values are close to present but still preindustrial in atmospheric CO2 terms.",
                "sources": [SOURCES["holocene"], SOURCES["co2"]],
            }
        return {
            "avg_temp_delta_c": +0.5,
            "avg_humidity_delta_percent": +0.0,
            "avg_co2_ppm": 400,
            "sea_level_delta_m": +0.0,
            "icehouse_greenhouse_state": "icehouse",
            "confidence": "moderate",
            "note": "Late Holocene values are close to the present baseline; recent industrial warming is compressed into the latest part of the stage.",
            "sources": [SOURCES["holocene"], SOURCES["co2"]],
        }

    return None


def format_signed_numbers(text):
    keys = {
        "avg_temp_delta_c",
        "avg_humidity_delta_percent",
        "sea_level_delta_m",
    }
    output = []
    for line in text.splitlines():
        stripped = line.strip()
        new_line = line
        for key in keys:
            prefix = key + ": "
            if stripped.startswith(prefix):
                value = stripped[len(prefix):]
                try:
                    number = float(value)
                except ValueError:
                    break
                if number > 0 and not value.startswith("+"):
                    indent = line[: len(line) - len(line.lstrip())]
                    new_line = indent + key + ": +" + value
                break
        output.append(new_line)
    return "\n".join(output) + "\n"


def main():
    overwrite = "--overwrite" in sys.argv
    include_higher_ranks = "--include-higher-ranks" in sys.argv
    recreate = "--recreate" in sys.argv
    if "--help" in sys.argv or "-h" in sys.argv:
        print(
            "Usage: scripts/fill_paleo_ecology.py "
            "[--recreate] [--include-higher-ranks] [--overwrite]"
        )
        raise SystemExit(0)

    rows = load_rows(recreate=recreate)

    changed = 0
    unchanged = 0
    unmatched = []

    for row in rows:
        if rank(row) not in LOWER_RANKS and not include_higher_ranks:
            unchanged += 1
            continue
        values = values_for(row)
        if values is None:
            unmatched.append(stage(row) or "UNKNOWN")
            unchanged += 1
            continue
        if set_if_missing(row, values, overwrite=overwrite):
            changed += 1
        else:
            unchanged += 1

    if changed > 0 or recreate:
        data = {ROOT_KEY: rows}
        text = yaml.safe_dump(data, sort_keys=False, allow_unicode=True, width=88)
        text = format_signed_numbers(text)
        DATA_PATH.write_text(text, encoding="utf-8")
        print("Updated " + str(DATA_PATH))
    else:
        print("No changes needed for " + str(DATA_PATH))
    print("Changed rows: " + str(changed))
    print("Unchanged rows: " + str(unchanged))
    if unmatched:
        print("Unmatched stages:")
        for name in unmatched:
            print("  - " + str(name))


if __name__ == "__main__":
    main()
