#!/usr/bin/env python3
"""Prepare AI-assisted date-resolution queue + prompt for clades.

This script does NOT modify curated DB values.
It builds a candidate YAML file plus a prompt markdown file for manual/AI review.
"""

from __future__ import annotations

import argparse
import datetime as dt
import json
import sqlite3
from pathlib import Path
from typing import Any

import yaml


DEFAULT_DB = Path("data/clades_detail_progressive_opentree.sqlite")
DEFAULT_CANDIDATES = Path("data/ai_date_candidates.yaml")
DEFAULT_PROMPT = Path("docs/ai_date_resolution_prompt.md")


def _fetch_rows(
    db_path: Path,
    clade_ids: list[str] | None,
    unresolved_only: bool,
    limit: int | None,
) -> list[dict[str, Any]]:
    if not db_path.exists():
        raise FileNotFoundError(f"Database not found: {db_path}")
    conn = sqlite3.connect(db_path)
    conn.row_factory = sqlite3.Row
    try:
        where: list[str] = []
        args: list[Any] = []
        if clade_ids:
            placeholders = ",".join(["?"] * len(clade_ids))
            where.append(f"id IN ({placeholders})")
            args.extend(clade_ids)
        if unresolved_only:
            where.append("date_resolution_method = 'unresolved'")
        sql = """
        SELECT
          id,
          parent_id,
          scientific_label,
          common_label,
          scientific_rank,
          start_ma,
          end_ma,
          divergence_ma,
          date_resolution_method,
          date_basis,
          date_confidence,
          date_notes
        FROM clades_detail
        """
        if where:
            sql += " WHERE " + " AND ".join(where)
        sql += " ORDER BY id"
        if limit is not None and limit > 0:
            sql += f" LIMIT {int(limit)}"
        rows = [dict(r) for r in conn.execute(sql, args).fetchall()]
        return rows
    finally:
        conn.close()


def _read_yaml_map(path: Path) -> dict[str, Any]:
    if not path.exists():
        return {}
    data = yaml.safe_load(path.read_text(encoding="utf-8"))
    return data if isinstance(data, dict) else {}


def _build_candidate_entry(row: dict[str, Any]) -> dict[str, Any]:
    return {
        "context": {
            "label": row.get("scientific_label") or row.get("common_label"),
            "common_label": row.get("common_label"),
            "rank": row.get("scientific_rank"),
            "parent_id": row.get("parent_id"),
            "current_dates": {
                "start_ma": row.get("start_ma"),
                "end_ma": row.get("end_ma"),
                "divergence_ma": row.get("divergence_ma"),
                "date_resolution_method": row.get("date_resolution_method"),
                "date_basis": row.get("date_basis"),
                "date_confidence": row.get("date_confidence"),
                "date_notes": row.get("date_notes"),
            },
        },
        "proposed_date_resolution": {
            "start_ma": None,
            "end_ma": None,
            "divergence_ma": None,
            "date_basis": None,
            "date_confidence": None,
            "date_resolution_method": None,
            "date_sources": [
                {
                    "source_type": None,
                    "source_label": None,
                    "url": None,
                    "note": None,
                }
            ],
            "date_notes": None,
        },
        "review": {
            "status": "pending",
            "reviewer": None,
            "reviewed_at": None,
            "decision_note": None,
        },
    }


def _merge_candidates(
    existing: dict[str, Any],
    rows: list[dict[str, Any]],
    overwrite: bool,
) -> tuple[dict[str, Any], int, int]:
    out = dict(existing)
    added = 0
    skipped = 0
    for row in rows:
        clade_id = str(row["id"])
        if clade_id in out and not overwrite:
            skipped += 1
            continue
        out[clade_id] = _build_candidate_entry(row)
        added += 1
    return out, added, skipped


def _build_prompt(rows: list[dict[str, Any]]) -> str:
    payload = {
        "task": "Resolve clade dates with provenance and confidence.",
        "rules": [
            "Do not overwrite curated values; propose candidates only.",
            "Use hierarchy: specialist, PBDB, TimeTree, reputable educational, generalised fallback, proxy.",
            "Differentiate fossil first appearance vs molecular divergence.",
            "Mark low-confidence values clearly.",
        ],
        "requested_output_format": {
            "clade_id": {
                "start_ma": "number|null",
                "end_ma": "number|null",
                "divergence_ma": "number|null",
                "date_basis": "string",
                "date_confidence": "high|moderate|approximate|low",
                "date_resolution_method": "string",
                "date_sources": [
                    {
                        "source_type": "string",
                        "source_label": "string",
                        "url": "string|null",
                        "note": "string",
                    }
                ],
                "date_notes": "string",
            }
        },
        "clades": [
            {
                "id": r.get("id"),
                "scientific_label": r.get("scientific_label"),
                "common_label": r.get("common_label"),
                "rank": r.get("scientific_rank"),
                "parent_id": r.get("parent_id"),
                "current_start_ma": r.get("start_ma"),
                "current_end_ma": r.get("end_ma"),
                "current_divergence_ma": r.get("divergence_ma"),
                "current_method": r.get("date_resolution_method"),
            }
            for r in rows
        ],
    }
    return (
        "# AI Date Resolution Prompt\n\n"
        "Use the JSON payload below as context. Return YAML only, with top-level keys as clade ids.\n\n"
        "```json\n"
        f"{json.dumps(payload, indent=2)}\n"
        "```\n"
    )


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--db", type=Path, default=DEFAULT_DB)
    parser.add_argument("--clade-id", action="append", default=[])
    parser.add_argument("--unresolved", action="store_true")
    parser.add_argument("--limit", type=int, default=None)
    parser.add_argument("--candidates-out", type=Path, default=DEFAULT_CANDIDATES)
    parser.add_argument("--prompt-out", type=Path, default=DEFAULT_PROMPT)
    parser.add_argument("--overwrite", action="store_true")
    parser.add_argument("--dry-run", action="store_true")
    args = parser.parse_args()

    if not args.clade_id and not args.unresolved:
        raise SystemExit("Provide --clade-id (repeatable) and/or --unresolved.")

    rows = _fetch_rows(
        db_path=args.db,
        clade_ids=args.clade_id or None,
        unresolved_only=args.unresolved,
        limit=args.limit,
    )
    if not rows:
        print("No matching clades found.")
        return 0

    existing = _read_yaml_map(args.candidates_out)
    merged, added, skipped = _merge_candidates(existing, rows, overwrite=args.overwrite)
    prompt_text = _build_prompt(rows)

    print(f"Selected clades: {len(rows)}")
    print(f"Candidates added/updated: {added}")
    print(f"Candidates skipped: {skipped}")
    print(f"Dry run: {args.dry_run}")

    if args.dry_run:
        preview_ids = [r["id"] for r in rows[:20]]
        print("Preview IDs:", ", ".join(preview_ids))
        return 0

    args.candidates_out.parent.mkdir(parents=True, exist_ok=True)
    args.candidates_out.write_text(
        yaml.safe_dump(merged, sort_keys=True, allow_unicode=False),
        encoding="utf-8",
    )
    args.prompt_out.parent.mkdir(parents=True, exist_ok=True)
    args.prompt_out.write_text(prompt_text, encoding="utf-8")
    print(f"Wrote candidates: {args.candidates_out}")
    print(f"Wrote prompt: {args.prompt_out}")
    print(f"Generated at: {dt.datetime.now(dt.timezone.utc).isoformat()}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

