#!/usr/bin/env python3
"""Import taxonomy backbone data into taxonomy.sqlite.

This script uses Open Tree of Life as the taxonomic scaffold, enriches exact
name matches from the Paleobiology Database for fossil first-appearance dates,
and optionally merges a manually curated molecular-date JSON file.

It is intentionally build-time/offline-safe for the app runtime: it writes a
SQLite cache file that can later be bundled or copied into app support.
"""

from __future__ import annotations

import argparse
import datetime as dt
import hashlib
import json
import sqlite3
import urllib.parse
import urllib.request
from dataclasses import dataclass, field
from pathlib import Path
from typing import Any


DEFAULT_ROOTS = ("Bacteria", "Archaea", "Eukaryota")
DEFAULT_CACHE_DIR = Path(".cache/taxonomy_import")
OPENTREE_BASE = "https://api.opentreeoflife.org/v3"
PBDB_BASE = "https://paleobiodb.org/data1.2"
EXCLUDED_NAME_FRAGMENTS = (
    "uncultured",
    "environmental sample",
    "environmental samples",
    "unclassified sequences",
    "mixed sample",
    "mixed samples",
    "mixed culture",
    "collection",
)
EXCLUDED_FLAGS = {"not_otu", "was_container"}


@dataclass
class TaxonRecord:
    id: str
    name: str
    rank: str
    parent_id: str | None
    source_ids: dict[str, int | None] = field(
        default_factory=lambda: {
            "ott_id": None,
            "ncbi_id": None,
            "gbif_id": None,
            "pbdb_id": None,
        }
    )
    synonyms: list[str] = field(default_factory=list)
    fossil_first_ma: float | None = None
    fossil_first_source: str | None = None
    fossil_first_confidence: str | None = None
    molecular_origin_ma: float | None = None
    molecular_origin_min_ma: float | None = None
    molecular_origin_max_ma: float | None = None
    molecular_source: str | None = None
    display_start_ma: float | None = None
    display_start_basis: str = "unknown"
    has_children: bool = False
    source_backbone: str = "OpenTree"
    last_fetched_at: str | None = None


def _parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--db", default="data/taxonomy.sqlite")
    parser.add_argument("--root", action="append", dest="roots", default=[])
    parser.add_argument(
        "--expand-root",
        action="append",
        dest="expand_roots",
        default=[],
        help="Resolve this root name and import descendants up to --max-depth.",
    )
    parser.add_argument("--max-depth", type=int, default=1)
    parser.add_argument("--child-limit", type=int, default=40)
    parser.add_argument("--cache-dir", default=str(DEFAULT_CACHE_DIR))
    parser.add_argument("--molecular-json")
    parser.add_argument("--skip-pbdb", action="store_true")
    return parser.parse_args()


def _http_json(
    url: str,
    *,
    payload: dict[str, Any] | None = None,
    cache_dir: Path | None,
) -> dict[str, Any]:
    cache_key = hashlib.sha256(
        json.dumps({"url": url, "payload": payload}, sort_keys=True).encode("utf-8")
    ).hexdigest()
    cache_file = cache_dir / f"{cache_key}.json" if cache_dir else None
    if cache_file and cache_file.exists():
        return json.loads(cache_file.read_text(encoding="utf-8"))

    if payload is None:
        request = urllib.request.Request(url, headers={"User-Agent": "DeepTime2/1.0"})
    else:
        request = urllib.request.Request(
            url,
            data=json.dumps(payload).encode("utf-8"),
            headers={
                "Content-Type": "application/json",
                "User-Agent": "DeepTime2/1.0",
            },
            method="POST",
        )
    with urllib.request.urlopen(request, timeout=60) as response:
        data = json.loads(response.read().decode("utf-8"))
    if cache_file:
        cache_file.parent.mkdir(parents=True, exist_ok=True)
        cache_file.write_text(json.dumps(data, indent=2), encoding="utf-8")
    return data


def _match_name(name: str, cache_dir: Path | None) -> dict[str, Any]:
    response = _http_json(
        f"{OPENTREE_BASE}/tnrs/match_names",
        payload={"names": [name], "do_approximate_matching": True},
        cache_dir=cache_dir,
    )
    results = response.get("results") or []
    if not results or not (results[0].get("matches") or []):
        raise RuntimeError(f"Unable to resolve root name '{name}' via OpenTree TNRS")
    matches = sorted(
        results[0]["matches"],
        key=lambda match: (
            float(match.get("score", 0.0)),
            0 if match.get("is_approximate_match") else 1,
        ),
        reverse=True,
    )
    return matches[0]["taxon"]


def _taxon_info(ott_id: int, cache_dir: Path | None) -> dict[str, Any]:
    return _http_json(
        f"{OPENTREE_BASE}/taxonomy/taxon_info",
        payload={"ott_id": ott_id, "include_lineage": True, "include_children": True},
        cache_dir=cache_dir,
    )


def _pbdb_exact(name: str, cache_dir: Path | None) -> dict[str, Any] | None:
    query = urllib.parse.urlencode({"name": name, "show": "attr,app,parent,size"})
    response = _http_json(f"{PBDB_BASE}/taxa/list.json?{query}", cache_dir=cache_dir)
    records = response.get("records") or []
    for record in records:
        if str(record.get("nam", "")).casefold() == name.casefold():
            return record
    return None


def _source_ids_from_tax_sources(tax_sources: list[str], ott_id: int) -> dict[str, int | None]:
    ids: dict[str, int | None] = {
        "ott_id": ott_id,
        "ncbi_id": None,
        "gbif_id": None,
        "pbdb_id": None,
    }
    for source in tax_sources:
        if ":" not in source:
            continue
        prefix, raw_value = source.split(":", 1)
        try:
            value = int(raw_value)
        except ValueError:
            continue
        if prefix == "ncbi":
            ids["ncbi_id"] = value
        elif prefix == "gbif":
            ids["gbif_id"] = value
    return ids


def _should_include_child(child: dict[str, Any]) -> bool:
    if child.get("is_suppressed"):
        return False
    flags = set(child.get("flags") or [])
    if flags.intersection(EXCLUDED_FLAGS):
        return False
    name = str(child.get("name", "")).casefold()
    return not any(fragment in name for fragment in EXCLUDED_NAME_FRAGMENTS)


def _record_from_opentree(info: dict[str, Any], parent_id: str | None, fetched_at: str) -> TaxonRecord:
    ott_id = int(info["ott_id"])
    synonyms = sorted(
        {
            value.strip()
            for value in (info.get("synonyms") or [])
            if isinstance(value, str) and value.strip() and value.strip() != info.get("name")
        }
    )
    children = [child for child in (info.get("children") or []) if _should_include_child(child)]
    return TaxonRecord(
        id=f"ott:{ott_id}",
        name=info.get("name") or info.get("unique_name") or f"ott:{ott_id}",
        rank=info.get("rank") or "unranked",
        parent_id=parent_id,
        source_ids=_source_ids_from_tax_sources(info.get("tax_sources") or [], ott_id),
        synonyms=synonyms,
        has_children=bool(children),
        last_fetched_at=fetched_at,
    )


def _apply_pbdb(record: TaxonRecord, cache_dir: Path | None) -> None:
    if record.source_backbone == "synthetic" or record.rank == "root":
        return
    pbdb = _pbdb_exact(record.name, cache_dir)
    if not pbdb:
        return
    oid = str(pbdb.get("oid") or "")
    if oid.startswith("txn:"):
        record.source_ids["pbdb_id"] = int(oid.split(":", 1)[1])
    if pbdb.get("fea") is not None:
        record.fossil_first_ma = float(pbdb["fea"])
        record.fossil_first_source = "PBDB taxa/list exact name match"
        record.fossil_first_confidence = "high"


def _apply_molecular(records: dict[str, TaxonRecord], molecular_path: Path) -> int:
    payload = json.loads(molecular_path.read_text(encoding="utf-8"))
    matches = 0
    for item in payload.get("taxa", []):
        target = None
        if isinstance(item.get("ott_id"), int):
            target = records.get(f"ott:{item['ott_id']}")
        if target is None and item.get("id"):
            target = records.get(str(item["id"]))
        if target is None and item.get("name"):
            target = next((value for value in records.values() if value.name == item["name"]), None)
        if target is None:
            continue
        target.molecular_origin_ma = _maybe_float(item.get("origin_ma"))
        target.molecular_origin_min_ma = _maybe_float(item.get("origin_min_ma"))
        target.molecular_origin_max_ma = _maybe_float(item.get("origin_max_ma"))
        target.molecular_source = str(item.get("source") or "manual_molecular_overlay")
        matches += 1
    return matches


def _maybe_float(value: Any) -> float | None:
    if value is None:
        return None
    return float(value)


def _assign_display_date(record: TaxonRecord) -> None:
    if record.molecular_origin_ma is not None:
        record.display_start_ma = record.molecular_origin_ma
        record.display_start_basis = "molecular_clock"
    elif record.fossil_first_ma is not None:
        record.display_start_ma = record.fossil_first_ma
        record.display_start_basis = "fossil_first_appearance"


def _open_db(path: Path) -> sqlite3.Connection:
    path.parent.mkdir(parents=True, exist_ok=True)
    db = sqlite3.connect(path)
    db.executescript(
        """
        PRAGMA foreign_keys = ON;
        CREATE TABLE IF NOT EXISTS taxonomy_taxa (
          id TEXT PRIMARY KEY,
          parent_id TEXT,
          name TEXT NOT NULL,
          rank TEXT NOT NULL,
          common_name TEXT,
          summary TEXT,
          ott_id INTEGER,
          ncbi_id INTEGER,
          gbif_id INTEGER,
          pbdb_id INTEGER,
          fossil_first_ma REAL,
          fossil_first_source TEXT,
          fossil_first_confidence TEXT,
          molecular_origin_ma REAL,
          molecular_origin_min_ma REAL,
          molecular_origin_max_ma REAL,
          molecular_source TEXT,
          display_start_ma REAL,
          display_start_basis TEXT NOT NULL DEFAULT 'unknown',
          has_children INTEGER NOT NULL DEFAULT 0,
          source_backbone TEXT,
          last_fetched_at TEXT,
          FOREIGN KEY (parent_id) REFERENCES taxonomy_taxa(id) ON DELETE SET NULL
        );
        CREATE TABLE IF NOT EXISTS taxonomy_synonyms (
          taxon_id TEXT NOT NULL,
          synonym TEXT NOT NULL,
          PRIMARY KEY (taxon_id, synonym),
          FOREIGN KEY (taxon_id) REFERENCES taxonomy_taxa(id) ON DELETE CASCADE
        );
        """
    )
    return db


def _write_records(db: sqlite3.Connection, records: dict[str, TaxonRecord]) -> None:
    with db:
        db.execute("DELETE FROM taxonomy_synonyms")
        db.execute("DELETE FROM taxonomy_taxa")
        for record in records.values():
            _assign_display_date(record)
            db.execute(
                """
                INSERT INTO taxonomy_taxa (
                  id, parent_id, name, rank, common_name, summary, ott_id, ncbi_id,
                  gbif_id, pbdb_id, fossil_first_ma, fossil_first_source,
                  fossil_first_confidence, molecular_origin_ma, molecular_origin_min_ma,
                  molecular_origin_max_ma, molecular_source, display_start_ma,
                  display_start_basis, has_children, source_backbone, last_fetched_at
                ) VALUES (?, ?, ?, ?, NULL, NULL, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
                """,
                (
                    record.id,
                    record.parent_id,
                    record.name,
                    record.rank,
                    record.source_ids["ott_id"],
                    record.source_ids["ncbi_id"],
                    record.source_ids["gbif_id"],
                    record.source_ids["pbdb_id"],
                    record.fossil_first_ma,
                    record.fossil_first_source,
                    record.fossil_first_confidence,
                    record.molecular_origin_ma,
                    record.molecular_origin_min_ma,
                    record.molecular_origin_max_ma,
                    record.molecular_source,
                    record.display_start_ma,
                    record.display_start_basis,
                    1 if record.has_children else 0,
                    record.source_backbone,
                    record.last_fetched_at,
                ),
            )
            for synonym in record.synonyms:
                db.execute(
                    "INSERT OR IGNORE INTO taxonomy_synonyms (taxon_id, synonym) VALUES (?, ?)",
                    (record.id, synonym),
                )


def main() -> None:
    args = _parse_args()
    cache_dir = Path(args.cache_dir) if args.cache_dir else None
    roots = args.roots or list(DEFAULT_ROOTS)
    expand_roots = set(args.expand_roots)
    fetched_at = dt.datetime.now(dt.timezone.utc).isoformat()
    records: dict[str, TaxonRecord] = {
        "life": TaxonRecord(
            id="life",
            name="Life",
            rank="root",
            parent_id=None,
            has_children=True,
            source_backbone="synthetic",
            last_fetched_at=fetched_at,
        )
    }

    for root_name in roots:
        root_taxon = _match_name(root_name, cache_dir)
        root_info = _taxon_info(int(root_taxon["ott_id"]), cache_dir) if root_name in expand_roots else root_taxon
        root_record = _record_from_opentree(root_info, "life", fetched_at)
        root_record.has_children = True
        records[root_record.id] = root_record

        if root_name not in expand_roots:
            continue
        queue = [(root_info, 0)]
        while queue:
            current_info, depth = queue.pop(0)
            if depth >= args.max_depth:
                continue
            children = [child for child in (current_info.get("children") or []) if _should_include_child(child)]
            for child in children[: args.child_limit]:
                child_info = _taxon_info(int(child["ott_id"]), cache_dir)
                child_record = _record_from_opentree(
                    child_info,
                    f"ott:{int(current_info['ott_id'])}",
                    fetched_at,
                )
                records[child_record.id] = child_record
                queue.append((child_info, depth + 1))

    enriched_pbdb = 0
    if not args.skip_pbdb:
        for record in records.values():
            before = record.fossil_first_ma
            _apply_pbdb(record, cache_dir)
            if before is None and record.fossil_first_ma is not None:
                enriched_pbdb += 1

    molecular_matches = 0
    if args.molecular_json:
        molecular_matches = _apply_molecular(records, Path(args.molecular_json))

    db = _open_db(Path(args.db))
    try:
        _write_records(db, records)
    finally:
        db.close()

    print(
        f"Imported {len(records)} taxa into {args.db} "
        f"(pbdb_enriched={enriched_pbdb}, molecular_enriched={molecular_matches})"
    )


if __name__ == "__main__":
    main()
