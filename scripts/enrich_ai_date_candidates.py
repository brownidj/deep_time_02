#!/usr/bin/env python3
"""
Deep Time 2: AI date-candidate enrichment script.

Purpose
-------
This script reads ai_date_candidates.yaml and attempts to produce Alethoalaornithidae-style
proposed date-resolution blocks for every taxon entry.

It is deliberately conservative. It does NOT overwrite the input file. It writes a new
review file containing:

- current context;
- proposed date resolution;
- public-source evidence;
- confidence labels;
- review notes;
- unresolved status where evidence is insufficient.

Recommended use
---------------
From the Deep_Time_2 project root:

    python3 scripts/enrich_ai_date_candidates.py \
      --input ai_date_candidates.yaml \
      --output ai_date_candidates.enriched.yaml

Optional:

    python3 scripts/enrich_ai_date_candidates.py \
      --input ai_date_candidates.yaml \
      --output ai_date_candidates.enriched.yaml \
      --limit 10

Dependencies
------------
This script uses only common Python packages plus PyYAML and requests.

    python3 -m pip install pyyaml requests

If this script is added to the project permanently, also add these to requirements.txt:

    PyYAML
    requests

Important limitation
--------------------
This script does not use ChatGPT directly. Instead it performs a structured public-source
fallback using:

- Paleobiology Database public API;
- GBIF species API;
- Wikidata SPARQL;
- Crossref bibliographic search.

For truly obscure taxa, it will usually produce a high-quality unresolved block rather
than invent a precise fossil_start_ma.

That behaviour is intentional.
"""

from __future__ import annotations

import argparse
import copy
import datetime as _dt
import json
import re
import sys
import time
import urllib.parse
from dataclasses import dataclass
from pathlib import Path
from typing import Any, Optional

import requests
import yaml


USER_AGENT = "DeepTime2DateCandidateEnricher/1.0 (local research script)"
REQUEST_TIMEOUT = 20
REQUEST_PAUSE_SECONDS = 0.25


PBDB_TAXA_URL = "https://paleobiodb.org/data1.2/taxa/list.json"
PBDB_OCCS_URL = "https://paleobiodb.org/data1.2/occs/list.json"
GBIF_SPECIES_SEARCH_URL = "https://api.gbif.org/v1/species/search"
CROSSREF_WORKS_URL = "https://api.crossref.org/works"
WIKIDATA_SPARQL_URL = "https://query.wikidata.org/sparql"


CONTROLLED_METHODS = {
    "fossil_first_appearance",
    "formation_age_inference",
    "stage_range_inference",
    "molecular_clock_estimate",
    "combined_fossil_and_molecular",
    "taxonomic_proxy",
    "ai_literature_fallback",
    "unresolved",
}

CONTROLLED_BASES = {
    "fossil_first_appearance",
    "formation_constrained_fossil_occurrence",
    "stage_constrained_fossil_occurrence",
    "molecular_divergence_estimate",
    "combined_fossil_and_molecular_estimate",
    "taxonomic_proxy_estimate",
    "unresolved",
}


@dataclass
class SourceRecord:
    source_label: Optional[str]
    source_type: Optional[str]
    url: Optional[str]
    note: Optional[str]

    def to_yaml(self) -> dict[str, Optional[str]]:
        return {
            "source_label": self.source_label,
            "source_type": self.source_type,
            "url": self.url,
            "note": self.note,
        }


@dataclass
class Evidence:
    taxon_key: str
    label: str
    rank: Optional[str]
    pbdb_taxa: list[dict[str, Any]]
    pbdb_occurrences: list[dict[str, Any]]
    gbif_results: list[dict[str, Any]]
    wikidata_results: list[dict[str, Any]]
    crossref_results: list[dict[str, Any]]


def safe_get_json(url: str, params: dict[str, Any], headers: Optional[dict[str, str]] = None) -> Optional[dict[str, Any]]:
    merged_headers = {"User-Agent": USER_AGENT}
    if headers:
        merged_headers.update(headers)

    try:
        response = requests.get(url, params=params, headers=merged_headers, timeout=REQUEST_TIMEOUT)
        time.sleep(REQUEST_PAUSE_SECONDS)
        if response.status_code >= 400:
            return None
        return response.json()
    except Exception:
        return None


def normalise_label(raw: str) -> str:
    text = raw.strip().replace("_", " ").replace("-", " ")
    text = re.sub(r"\s+", " ", text)
    if not text:
        return raw
    return " ".join(part[:1].upper() + part[1:] for part in text.split(" "))


def candidate_search_terms(taxon_key: str, label: Optional[str]) -> list[str]:
    terms: list[str] = []
    if label:
        terms.append(label)
    terms.append(normalise_label(taxon_key))

    # Obscure family names often have an included genus formed by removing -idae.
    lowered = taxon_key.lower()
    if lowered.endswith("idae"):
        stem = lowered[:-4]
        terms.append(normalise_label(stem))
    if lowered.endswith("inae"):
        stem = lowered[:-4]
        terms.append(normalise_label(stem))
    if lowered.endswith("oidea"):
        stem = lowered[:-5]
        terms.append(normalise_label(stem))

    # Preserve order while deduplicating.
    out: list[str] = []
    seen = set()
    for term in terms:
        key = term.lower()
        if key not in seen:
            seen.add(key)
            out.append(term)
    return out


def query_pbdb_taxa(term: str) -> list[dict[str, Any]]:
    params = {
        "base_name": term,
        "show": "attr,parent,app,ref",
    }
    data = safe_get_json(PBDB_TAXA_URL, params)
    if not data:
        return []
    return data.get("records", []) or []


def query_pbdb_occurrences(term: str) -> list[dict[str, Any]]:
    params = {
        "base_name": term,
        "show": "coords,loc,classext,ident,phylo,time,strat,ref",
        "limit": 200,
    }
    data = safe_get_json(PBDB_OCCS_URL, params)
    if not data:
        return []
    return data.get("records", []) or []


def query_gbif(term: str) -> list[dict[str, Any]]:
    params = {
        "q": term,
        "limit": 10,
    }
    data = safe_get_json(GBIF_SPECIES_SEARCH_URL, params)
    if not data:
        return []
    return data.get("results", []) or []


def query_crossref(term: str) -> list[dict[str, Any]]:
    query = term
    params = {
        "query.title": query,
        "rows": 5,
        "select": "DOI,title,author,issued,container-title,URL,type",
    }
    data = safe_get_json(CROSSREF_WORKS_URL, params)
    if not data:
        return []
    return data.get("message", {}).get("items", []) or []


def query_wikidata(term: str) -> list[dict[str, Any]]:
    sparql = """
    SELECT ?item ?itemLabel ?taxonRankLabel ?parentLabel ?startTime ?fossilRange WHERE {
      ?item rdfs:label "%s"@en .
      OPTIONAL { ?item wdt:P105 ?taxonRank . }
      OPTIONAL { ?item wdt:P171 ?parent . }
      OPTIONAL { ?item wdt:P580 ?startTime . }
      OPTIONAL { ?item wdt:P523 ?fossilRange . }
      SERVICE wikibase:label { bd:serviceParam wikibase:language "en". }
    }
    LIMIT 10
    """ % term.replace('"', '\\"')

    params = {
        "query": sparql,
        "format": "json",
    }
    data = safe_get_json(
        WIKIDATA_SPARQL_URL,
        params,
        headers={"Accept": "application/sparql-results+json"},
    )
    if not data:
        return []
    return data.get("results", {}).get("bindings", []) or []


def get_year_from_crossref_item(item: dict[str, Any]) -> Optional[int]:
    issued = item.get("issued", {})
    parts = issued.get("date-parts", [])
    if parts and parts[0]:
        try:
            return int(parts[0][0])
        except Exception:
            return None
    return None


def format_crossref_label(item: dict[str, Any]) -> str:
    title_list = item.get("title") or []
    title = title_list[0] if title_list else "Crossref work"
    year = get_year_from_crossref_item(item)
    container = item.get("container-title") or []
    journal = container[0] if container else None
    if year and journal:
        return "%s. %s. %s." % (year, title, journal)
    if year:
        return "%s. %s." % (year, title)
    return title


def pbdb_age_values(occurrences: list[dict[str, Any]]) -> tuple[Optional[float], Optional[float]]:
    """
    PBDB occurrence records commonly include early_age and late_age.
    The older bound is usually early_age, the younger bound is late_age.
    """
    older_values: list[float] = []
    younger_values: list[float] = []

    for occ in occurrences:
        for key in ("eag", "early_age"):
            value = occ.get(key)
            if isinstance(value, (int, float)):
                older_values.append(float(value))
                break
            if isinstance(value, str):
                try:
                    older_values.append(float(value))
                    break
                except ValueError:
                    pass

        for key in ("lag", "late_age"):
            value = occ.get(key)
            if isinstance(value, (int, float)):
                younger_values.append(float(value))
                break
            if isinstance(value, str):
                try:
                    younger_values.append(float(value))
                    break
                except ValueError:
                    pass

    if not older_values:
        return None, None

    oldest = max(older_values)
    youngest = min(younger_values) if younger_values else None
    return oldest, youngest


def summarise_pbdb_occurrences(occurrences: list[dict[str, Any]]) -> str:
    if not occurrences:
        return "No PBDB fossil occurrence records were returned."

    oldest, youngest = pbdb_age_values(occurrences)
    formation_counts: dict[str, int] = {}
    interval_counts: dict[str, int] = {}

    for occ in occurrences:
        formation = occ.get("sfm") or occ.get("formation") or occ.get("stratgroup")
        if formation:
            formation_counts[str(formation)] = formation_counts.get(str(formation), 0) + 1

        interval = occ.get("oei") or occ.get("early_interval") or occ.get("interval_name")
        if interval:
            interval_counts[str(interval)] = interval_counts.get(str(interval), 0) + 1

    bits = ["PBDB returned %d fossil occurrence record(s)." % len(occurrences)]

    if oldest is not None and youngest is not None:
        bits.append("The broad PBDB occurrence envelope is approximately %.3f–%.3f Ma." % (oldest, youngest))
    elif oldest is not None:
        bits.append("The oldest PBDB occurrence bound is approximately %.3f Ma." % oldest)

    if formation_counts:
        top_formations = sorted(formation_counts.items(), key=lambda item: item[1], reverse=True)[:5]
        bits.append("Most frequent formation labels: %s." % ", ".join("%s (%d)" % item for item in top_formations))

    if interval_counts:
        top_intervals = sorted(interval_counts.items(), key=lambda item: item[1], reverse=True)[:5]
        bits.append("Most frequent interval labels: %s." % ", ".join("%s (%d)" % item for item in top_intervals))

    return " ".join(bits)


def source_records_from_evidence(evidence: Evidence) -> list[SourceRecord]:
    sources: list[SourceRecord] = []

    if evidence.pbdb_taxa or evidence.pbdb_occurrences:
        sources.append(
            SourceRecord(
                source_label="Paleobiology Database search for %s" % evidence.label,
                source_type="fossil_occurrence_database",
                url="https://paleobiodb.org",
                note=summarise_pbdb_occurrences(evidence.pbdb_occurrences),
            )
        )

    for gbif_item in evidence.gbif_results[:3]:
        key = gbif_item.get("key")
        sci = gbif_item.get("scientificName") or gbif_item.get("canonicalName") or evidence.label
        rank = gbif_item.get("rank")
        status = gbif_item.get("taxonomicStatus")
        sources.append(
            SourceRecord(
                source_label="GBIF species search result: %s" % sci,
                source_type="taxonomic_database",
                url=("https://www.gbif.org/species/%s" % key) if key else "https://www.gbif.org",
                note="GBIF rank=%s; taxonomicStatus=%s. Useful for name checking, not as a date source." % (rank, status),
            )
        )

    for wd_item in evidence.wikidata_results[:2]:
        label = wd_item.get("itemLabel", {}).get("value") or evidence.label
        item_url = wd_item.get("item", {}).get("value")
        rank = wd_item.get("taxonRankLabel", {}).get("value")
        parent = wd_item.get("parentLabel", {}).get("value")
        sources.append(
            SourceRecord(
                source_label="Wikidata item: %s" % label,
                source_type="taxonomic_database",
                url=item_url,
                note="Wikidata rank=%s; parent=%s. Use only as a pointer to stronger sources." % (rank, parent),
            )
        )

    for item in evidence.crossref_results[:3]:
        doi = item.get("DOI")
        url = item.get("URL")
        sources.append(
            SourceRecord(
                source_label=format_crossref_label(item),
                source_type="bibliographic_search_result",
                url=url or (("https://doi.org/%s" % doi) if doi else None),
                note="Crossref bibliographic match. Manual review required to confirm relevance and stratigraphic content.",
            )
        )

    if not sources:
        sources.append(
            SourceRecord(
                source_label=None,
                source_type=None,
                url=None,
                note=None,
            )
        )

    return sources


def collect_evidence(taxon_key: str, entry: dict[str, Any]) -> Evidence:
    context = entry.get("context", {}) or {}
    label = context.get("common_label") or context.get("label") or normalise_label(taxon_key)
    rank = context.get("rank")
    terms = candidate_search_terms(taxon_key, label)

    pbdb_taxa: list[dict[str, Any]] = []
    pbdb_occurrences: list[dict[str, Any]] = []
    gbif_results: list[dict[str, Any]] = []
    wikidata_results: list[dict[str, Any]] = []
    crossref_results: list[dict[str, Any]] = []

    for term in terms:
        if not pbdb_taxa:
            pbdb_taxa = query_pbdb_taxa(term)
        if not pbdb_occurrences:
            pbdb_occurrences = query_pbdb_occurrences(term)
        if not gbif_results:
            gbif_results = query_gbif(term)
        if not wikidata_results:
            wikidata_results = query_wikidata(term)
        if not crossref_results:
            crossref_results = query_crossref(term)

    return Evidence(
        taxon_key=taxon_key,
        label=label,
        rank=rank,
        pbdb_taxa=pbdb_taxa,
        pbdb_occurrences=pbdb_occurrences,
        gbif_results=gbif_results,
        wikidata_results=wikidata_results,
        crossref_results=crossref_results,
    )


def propose_resolution(evidence: Evidence) -> dict[str, Any]:
    sources = source_records_from_evidence(evidence)
    oldest, youngest = pbdb_age_values(evidence.pbdb_occurrences)

    if oldest is not None:
        confidence = "moderate" if len(evidence.pbdb_occurrences) >= 3 else "low"
        end_ma = youngest if youngest is not None and youngest < oldest else None

        date_notes = (
            "%s has at least one public PBDB-derived fossil occurrence or occurrence-like record. "
            "%s The proposed fossil_start_ma uses the oldest available PBDB age bound as a conservative "
            "fossil minimum. This should not be interpreted as the true evolutionary origin or "
            "as a molecular divergence estimate. Manual review should check the accepted taxonomy, "
            "the included genus/species, the exact occurrence record, and whether the PBDB age is "
            "a specimen-level horizon, formation-level range, or broader stage-level estimate."
        ) % (evidence.label, summarise_pbdb_occurrences(evidence.pbdb_occurrences))

        decision_note = (
            "AI/public-source proposal created from PBDB occurrence evidence. Accepted only as a "
            "candidate fossil minimum until manually checked. If the PBDB record is based on a "
            "broad stratigraphic interval, consider keeping fossil_start_ma null or downgrading confidence."
        )

        return {
            "date_basis": "fossil_first_appearance",
            "date_confidence": confidence,
            "date_notes": date_notes,
            "date_resolution_method": "fossil_first_appearance",
            "date_sources": [source.to_yaml() for source in sources],
            "divergence_ma": None,
            "fossil_end_ma": end_ma,
            "fossil_start_ma": round(oldest, 5),
            "_review_decision_note": decision_note,
            "_review_status": "ai_proposed",
        }

    if evidence.gbif_results or evidence.wikidata_results or evidence.crossref_results:
        date_notes = (
            "%s was found in one or more public taxonomic or bibliographic sources, but no usable "
            "public fossil occurrence age or molecular divergence estimate was recovered by this "
            "script. The available sources may help verify spelling, validity, synonymy, membership, "
            "or the original description, but they do not justify a numeric fossil_start_ma. Manual review "
            "should look for the original description, PBDB occurrence records under included genera "
            "or species, museum records, and geochronology of any named host formation."
        ) % evidence.label

        decision_note = (
            "Kept numeric fields null. Public taxonomic or bibliographic pointers were found, "
            "but no defensible public age was extracted. This entry needs manual literature review."
        )

        return {
            "date_basis": "unresolved",
            "date_confidence": "low",
            "date_notes": date_notes,
            "date_resolution_method": "unresolved",
            "date_sources": [source.to_yaml() for source in sources],
            "divergence_ma": None,
            "fossil_end_ma": None,
            "fossil_start_ma": None,
            "_review_decision_note": decision_note,
            "_review_status": "needs_primary_source",
        }

    date_notes = (
        "No usable PBDB fossil occurrence, GBIF taxonomic result, Wikidata taxon record, Crossref "
        "bibliographic pointer, TimeTree-style molecular estimate, or reputable structured date "
        "source was found by this script for %s. Numeric fields remain null to avoid false precision."
    ) % evidence.label

    decision_note = (
        "Kept all numeric fields null. No public structured evidence was found by the automated "
        "fallback. Next steps: manually search the original taxonomic literature and included "
        "genus/species names, then check host formation geochronology if a fossil locality is found."
    )

    return {
        "date_basis": "unresolved",
        "date_confidence": "low",
        "date_notes": date_notes,
        "date_resolution_method": "unresolved",
        "date_sources": [source.to_yaml() for source in sources],
        "divergence_ma": None,
        "fossil_end_ma": None,
        "fossil_start_ma": None,
        "_review_decision_note": decision_note,
        "_review_status": "unresolved",
    }


def clean_internal_keys(proposal: dict[str, Any]) -> tuple[dict[str, Any], str, str]:
    proposal = copy.deepcopy(proposal)
    decision_note = proposal.pop("_review_decision_note")
    status = proposal.pop("_review_status")
    return proposal, decision_note, status


def enrich_entry(taxon_key: str, entry: dict[str, Any]) -> dict[str, Any]:
    new_entry = copy.deepcopy(entry)

    evidence = collect_evidence(taxon_key, entry)
    proposal_with_internal = propose_resolution(evidence)
    proposal, decision_note, status = clean_internal_keys(proposal_with_internal)

    # Preserve the original context exactly where possible.
    if "context" not in new_entry:
        new_entry["context"] = {}

    new_entry["proposed_date_resolution"] = proposal
    new_entry["review"] = {
        "decision_note": decision_note,
        "reviewed_at": _dt.datetime.now(_dt.timezone.utc).isoformat(),
        "reviewer": "deep_time_2_public_source_enrichment_script",
        "status": status,
    }

    return new_entry


def load_yaml(path: Path) -> dict[str, Any]:
    with path.open("r", encoding="utf-8") as handle:
        data = yaml.safe_load(handle)

    if not isinstance(data, dict):
        raise ValueError("Expected top-level YAML mapping in %s" % path)

    return data


def dump_yaml(data: dict[str, Any], path: Path) -> None:
    with path.open("w", encoding="utf-8") as handle:
        yaml.safe_dump(
            data,
            handle,
            allow_unicode=True,
            sort_keys=False,
            width=100,
            default_flow_style=False,
        )


def parse_args(argv: list[str]) -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Enrich Deep Time 2 ai_date_candidates.yaml with public-source date proposals."
    )
    parser.add_argument(
        "--input",
        required=True,
        help="Path to ai_date_candidates.yaml",
    )
    parser.add_argument(
        "--output",
        required=True,
        help="Path for enriched YAML output. The input file is not overwritten.",
    )
    parser.add_argument(
        "--limit",
        type=int,
        default=None,
        help="Optional maximum number of taxa to process, useful for testing.",
    )
    parser.add_argument(
        "--only-missing-start",
        action="store_true",
        help="Only process entries whose proposed_date_resolution.fossil_start_ma is null or missing.",
    )
    return parser.parse_args(argv)


def should_process(entry: dict[str, Any], only_missing_start: bool) -> bool:
    if not only_missing_start:
        return True
    proposal = entry.get("proposed_date_resolution", {}) or {}
    return proposal.get("fossil_start_ma") is None and proposal.get("start_ma") is None


def main(argv: list[str]) -> int:
    args = parse_args(argv)

    input_path = Path(args.input)
    output_path = Path(args.output)

    data = load_yaml(input_path)
    enriched: dict[str, Any] = {}

    processed_count = 0
    skipped_count = 0

    for taxon_key, entry in data.items():
        if args.limit is not None and processed_count >= args.limit:
            enriched[taxon_key] = copy.deepcopy(entry)
            skipped_count += 1
            continue

        if not isinstance(entry, dict):
            enriched[taxon_key] = copy.deepcopy(entry)
            skipped_count += 1
            continue

        if not should_process(entry, args.only_missing_start):
            enriched[taxon_key] = copy.deepcopy(entry)
            skipped_count += 1
            continue

        label = (entry.get("context", {}) or {}).get("common_label") or normalise_label(taxon_key)
        print("Processing %s..." % label)

        try:
            enriched[taxon_key] = enrich_entry(taxon_key, entry)
            processed_count += 1
        except KeyboardInterrupt:
            raise
        except Exception as error:
            failed_entry = copy.deepcopy(entry)
            failed_entry["review"] = {
                "decision_note": "Script failed while processing this entry: %s" % error,
                "reviewed_at": _dt.datetime.now(_dt.timezone.utc).isoformat(),
                "reviewer": "deep_time_2_public_source_enrichment_script",
                "status": "script_error",
            }
            enriched[taxon_key] = failed_entry
            processed_count += 1

    dump_yaml(enriched, output_path)

    print("")
    print("Done.")
    print("Processed: %d" % processed_count)
    print("Skipped: %d" % skipped_count)
    print("Output: %s" % output_path)

    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
