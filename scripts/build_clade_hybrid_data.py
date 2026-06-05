#!/usr/bin/env python3
"""Stage 1 hybrid clade data builder (YAML backbone -> SQLite detail subset).

Current scope:
- Reads curated clades from data/clades.yaml
- Builds one detail subtree rooted at --root-id (default: dinosauria)
- Writes SQLite detail DB (no runtime integration)
- Writes a markdown validation report in docs/
"""

from __future__ import annotations

import argparse
import datetime as dt
import json
import re
import sqlite3
from collections import deque
from pathlib import Path
from typing import Any
import urllib.error
import urllib.parse
import urllib.request

import yaml


DEFAULT_INPUT = Path("data/clades.yaml")
DEFAULT_DB = Path("data/clades_detail.sqlite")
DEFAULT_REPORT = Path("docs/dinosauria_hybrid_stage1_report.md")
DEFAULT_DATE_REPORT = Path("docs/clade_date_resolution_report.md")
OPENTREE_BASE = "https://api.opentreeoflife.org/v3"
PBDB_BASE = "https://paleobiodb.org/data1.2"
TIMETREE_BASE = "https://timetree.org"


def _read_yaml(path: Path) -> list[dict[str, Any]]:
    raw = yaml.safe_load(path.read_text(encoding="utf-8"))
    if not isinstance(raw, list):
        raise ValueError(f"Expected YAML list in {path}")
    rows = [row for row in raw if isinstance(row, dict)]
    return rows


def _build_children_index(clades: list[dict[str, Any]]) -> dict[str, list[dict[str, Any]]]:
    index: dict[str, list[dict[str, Any]]] = {}
    for clade in clades:
        parent = (clade.get("parent_id") or "").strip()
        if not parent:
            continue
        index.setdefault(parent, []).append(clade)
    return index


def _post_json(url: str, payload: dict[str, Any], timeout_s: int) -> dict[str, Any]:
    body = json.dumps(payload).encode("utf-8")
    request = urllib.request.Request(
        url,
        data=body,
        headers={"Content-Type": "application/json"},
        method="POST",
    )
    with urllib.request.urlopen(request, timeout=timeout_s) as response:
        return json.loads(response.read().decode("utf-8"))


def _get_json(url: str, timeout_s: int) -> dict[str, Any]:
    with urllib.request.urlopen(url, timeout=timeout_s) as response:
        return json.loads(response.read().decode("utf-8"))


def _normalize_name(clade: dict[str, Any]) -> str:
    return (
        str(clade.get("opentree_name") or "").strip()
        or str(clade.get("scientific_label") or "").strip()
        or str(clade.get("common_label") or "").strip()
        or str(clade.get("label") or "").strip()
    )


def _slugify_id(value: str) -> str:
    text = value.strip().lower()
    text = re.sub(r"[^a-z0-9]+", "_", text)
    text = re.sub(r"_+", "_", text).strip("_")
    return text or "unnamed_clade"


def _fetch_opentree_metadata(
    clade: dict[str, Any], timeout_s: int
) -> tuple[dict[str, Any] | None, str | None]:
    name = _normalize_name(clade)
    if not name:
        return None, "missing_name"
    try:
        tnrs = _post_json(
            f"{OPENTREE_BASE}/tnrs/match_names",
            {"names": [name], "do_approximate_matching": True},
            timeout_s,
        )
        results = tnrs.get("results") or []
        matches = (results[0] if results else {}).get("matches") or []
        if not matches:
            return None, "no_tnrs_match"
        best = sorted(
            matches,
            key=lambda m: (
                float(m.get("score", 0.0)),
                0 if m.get("is_approximate_match") else 1,
            ),
            reverse=True,
        )[0]
        taxon = best.get("taxon") or {}
        ott_id = taxon.get("ott_id")
        if ott_id is None:
            return None, "tnrs_missing_ott_id"
        info = _post_json(
            f"{OPENTREE_BASE}/taxonomy/taxon_info",
            {"ott_id": int(ott_id), "include_lineage": True},
            timeout_s,
        )
        return (
            {
                "ott_id": int(ott_id),
                "matched_name": best.get("matched_name"),
                "unique_name": info.get("unique_name") or taxon.get("unique_name"),
                "rank": info.get("rank") or taxon.get("rank"),
                "flags": info.get("flags") or taxon.get("flags") or [],
                "tax_sources": info.get("tax_sources") or taxon.get("tax_sources") or [],
                "lineage_ids": [
                    int(node.get("ott_id"))
                    for node in (info.get("lineage") or [])
                    if node.get("ott_id") is not None
                ],
                "score": best.get("score"),
                "is_approximate_match": bool(best.get("is_approximate_match", False)),
                "checked_at": dt.datetime.now(dt.timezone.utc).isoformat(),
            },
            None,
        )
    except (urllib.error.URLError, urllib.error.HTTPError, ValueError) as exc:
        return None, f"opentree_error:{exc}"


def _fetch_pbdb_age(
    clade: dict[str, Any], timeout_s: int
) -> tuple[dict[str, Any] | None, str | None]:
    def _candidate_names() -> list[str]:
        raw = [
            str(clade.get("scientific_label") or "").strip(),
            str(clade.get("opentree_name") or "").strip(),
            str(clade.get("common_label") or "").strip(),
        ]
        variants: list[str] = []
        seen: set[str] = set()
        for base in raw:
            if not base:
                continue
            compact = re.sub(r"\s+", " ", base).strip()
            for variant in (
                compact,
                compact.replace("-", " "),
                re.sub(r"[^A-Za-z0-9 ]+", " ", compact).strip(),
            ):
                v = re.sub(r"\s+", " ", variant).strip()
                if not v:
                    continue
                key = v.lower()
                if key in seen:
                    continue
                seen.add(key)
                variants.append(v)
        return variants

    def _record_age(record: dict[str, Any]) -> tuple[float, float] | None:
        start = record.get("eag") or record.get("max_ma")
        end = record.get("lag") or record.get("min_ma")
        if start is None or end is None:
            return None
        try:
            s = float(start)
            e = float(end)
        except (TypeError, ValueError):
            return None
        if s <= e:
            return None
        return (s, e)

    def _score_record(record: dict[str, Any], query: str) -> tuple[int, int, int]:
        name = str(record.get("nam") or "").strip().lower()
        q = query.strip().lower()
        exact = 1 if name == q else 0
        contains = 1 if q and q in name else 0
        size = 0
        try:
            size = int(record.get("siz") or 0)
        except (TypeError, ValueError):
            size = 0
        return (exact, contains, size)

    names = _candidate_names()
    if not names:
        return None, "missing_name"

    best: tuple[dict[str, Any], str, tuple[int, int, int], tuple[float, float]] | None = None
    had_records = False
    for name in names:
        params = urllib.parse.urlencode(
            {
                "name": name,
                "show": "app,size",
                "limit": "20",
            }
        )
        url = f"{PBDB_BASE}/taxa/list.json?{params}"
        try:
            payload = _get_json(url, timeout_s)
        except (urllib.error.URLError, urllib.error.HTTPError, ValueError) as exc:
            return None, f"pbdb_error:{exc}"
        records = payload.get("records") or []
        if not records:
            continue
        had_records = True
        for record in records:
            age = _record_age(record)
            if age is None:
                continue
            score = _score_record(record, name)
            if best is None or score > best[2]:
                best = (record, name, score, age)

    if best is None:
        return None, "pbdb_no_age_fields" if had_records else "no_pbdb_match"

    record, query_name, _, age = best
    return (
        {
            "name": query_name,
            "start_ma": age[0],
            "end_ma": age[1],
            "taxon_no": record.get("oid") or record.get("taxon_no"),
            "matched_name": record.get("nam"),
            "checked_at": dt.datetime.now(dt.timezone.utc).isoformat(),
        },
        None,
    )


def _load_timetree_cache(path: Path) -> dict[str, Any]:
    if not path.exists():
        return {}
    try:
        raw = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, ValueError):
        return {}
    return raw if isinstance(raw, dict) else {}


def _save_timetree_cache(path: Path, cache: dict[str, Any]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(cache, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")


def _fetch_timetree_pairwise(
    taxon_a: str,
    taxon_b: str,
    timeout_s: int,
) -> tuple[dict[str, Any] | None, str | None]:
    a = re.sub(r"\s+", " ", taxon_a).strip()
    b = re.sub(r"\s+", " ", taxon_b).strip()
    if not a or not b:
        return None, "missing_timetree_taxa"
    try:
        resolve_url = (
            f"{TIMETREE_BASE}/ajax/names/"
            f"{urllib.parse.quote(a, safe='')}/{urllib.parse.quote(b, safe='')}"
        )
        with urllib.request.urlopen(resolve_url, timeout=timeout_s) as response:
            resolve_text = response.read().decode("utf-8", errors="replace")
        ids = re.findall(r'<option value="(\d+)"[^>]*>', resolve_text)
        if len(ids) < 2:
            return None, "timetree_name_resolution_failed"
        pair_url = f"{TIMETREE_BASE}/ajax/pairwise/{ids[0]}/{ids[1]}"
        with urllib.request.urlopen(pair_url, timeout=timeout_s) as response:
            html = response.read().decode("utf-8", errors="replace")
        mya_match = re.search(r">([0-9]+(?:\.[0-9]+)?)\s*MYA<", html)
        if mya_match is None:
            return None, "timetree_missing_mya"
        value = float(mya_match.group(1))
        ci_match = re.search(
            r"CI:\s*\(\s*([0-9]+(?:\.[0-9]+)?)\s*-\s*([0-9]+(?:\.[0-9]+)?)\s*MYA\s*\)",
            html,
        )
        ci_low = float(ci_match.group(1)) if ci_match else None
        ci_high = float(ci_match.group(2)) if ci_match else None
        return (
            {
                "taxon_a": a,
                "taxon_b": b,
                "divergence_ma": value,
                "ci_low_ma": ci_low,
                "ci_high_ma": ci_high,
                "source_url": pair_url,
                "checked_at": dt.datetime.now(dt.timezone.utc).isoformat(),
            },
            None,
        )
    except (urllib.error.URLError, urllib.error.HTTPError, ValueError) as exc:
        return None, f"timetree_error:{exc}"


def _fetch_timetree_pairwise_ids(
    taxid_a: int,
    taxid_b: int,
    timeout_s: int,
) -> tuple[dict[str, Any] | None, str | None]:
    if taxid_a <= 0 or taxid_b <= 0 or taxid_a == taxid_b:
        return None, "invalid_timetree_taxids"
    try:
        pair_url = f"{TIMETREE_BASE}/ajax/pairwise/{taxid_a}/{taxid_b}"
        with urllib.request.urlopen(pair_url, timeout=timeout_s) as response:
            html = response.read().decode("utf-8", errors="replace")
        mya_match = re.search(r">([0-9]+(?:\.[0-9]+)?)\s*MYA<", html)
        if mya_match is None:
            return None, "timetree_missing_mya"
        value = float(mya_match.group(1))
        ci_match = re.search(
            r"CI:\s*\(\s*([0-9]+(?:\.[0-9]+)?)\s*-\s*([0-9]+(?:\.[0-9]+)?)\s*MYA\s*\)",
            html,
        )
        ci_low = float(ci_match.group(1)) if ci_match else None
        ci_high = float(ci_match.group(2)) if ci_match else None
        return (
            {
                "taxid_a": taxid_a,
                "taxid_b": taxid_b,
                "divergence_ma": value,
                "ci_low_ma": ci_low,
                "ci_high_ma": ci_high,
                "source_url": pair_url,
                "checked_at": dt.datetime.now(dt.timezone.utc).isoformat(),
            },
            None,
        )
    except (urllib.error.URLError, urllib.error.HTTPError, ValueError) as exc:
        return None, f"timetree_error:{exc}"


def _timetree_aliases(name: str) -> list[str]:
    key = re.sub(r"\s+", " ", name).strip().lower()
    alias_map = {
        "aves": ["birds"],
        "dinosauria": ["dinosaurs"],
        "non avian dinosaurs": ["dinosaurs"],
        "non-avian dinosaurs": ["dinosaurs"],
    }
    return alias_map.get(key, [])


def _timetree_candidate_names(clade: dict[str, Any]) -> list[str]:
    raw = [
        str(clade.get("scientific_label") or "").strip(),
        str(clade.get("opentree_name") or "").strip(),
        str(clade.get("common_label") or "").strip(),
    ]
    out: list[str] = []
    seen: set[str] = set()
    for base in raw:
        if not base:
            continue
        variants = [
            base,
            re.sub(r"\s*\([^)]*\)\s*", " ", base).strip(),
            base.replace("-", " "),
            re.sub(r"[^A-Za-z0-9 -]+", " ", base).strip(),
        ]
        for alias in _timetree_aliases(base):
            variants.append(alias)
        for variant in variants:
            v = re.sub(r"\s+", " ", variant).strip()
            if not v:
                continue
            key = v.lower()
            if key in seen:
                continue
            seen.add(key)
            out.append(v)
    return out


def _ancestor_chain(
    clade: dict[str, Any],
    by_id: dict[str, dict[str, Any]],
    max_hops: int = 3,
) -> list[dict[str, Any]]:
    chain = [clade]
    visited = {str(clade.get("id") or "")}
    cursor = clade
    hops = 0
    while hops < max_hops:
        parent_id = str(cursor.get("parent_id") or "").strip()
        if not parent_id or parent_id in visited:
            break
        parent = by_id.get(parent_id)
        if parent is None:
            break
        chain.append(parent)
        visited.add(parent_id)
        cursor = parent
        hops += 1
    return chain


def _fetch_opentree_children(ott_id: int, timeout_s: int) -> list[dict[str, Any]]:
    payload = _post_json(
        f"{OPENTREE_BASE}/taxonomy/taxon_info",
        {"ott_id": int(ott_id), "include_children": True},
        timeout_s,
    )
    children = payload.get("children") or []
    rows: list[dict[str, Any]] = []
    for child in children:
        child_ott = child.get("ott_id")
        if child_ott is None:
            continue
        rows.append(
            {
                "ott_id": int(child_ott),
                "name": child.get("name"),
                "unique_name": child.get("unique_name"),
                "rank": child.get("rank"),
                "flags": child.get("flags") or [],
            }
        )
    rows.sort(key=lambda c: (str(c.get("rank") or ""), str(c.get("name") or "")))
    return rows


def _fetch_opentree_taxon_info_by_ott(
    ott_id: int,
    timeout_s: int,
) -> tuple[dict[str, Any] | None, str | None]:
    try:
        payload = _post_json(
            f"{OPENTREE_BASE}/taxonomy/taxon_info",
            {"ott_id": int(ott_id), "include_lineage": False},
            timeout_s,
        )
        return payload, None
    except (urllib.error.URLError, urllib.error.HTTPError, ValueError) as exc:
        return None, f"opentree_taxon_info_error:{exc}"


def _extract_ncbi_taxid(tax_sources: Any) -> int | None:
    if not isinstance(tax_sources, list):
        return None
    for source in tax_sources:
        if not isinstance(source, str):
            continue
        match = re.match(r"^ncbi:(\d+)$", source.strip().lower())
        if match:
            return int(match.group(1))
    return None


def _expand_subtree_from_opentree(
    root_id: str,
    subtree: list[dict[str, Any]],
    by_id: dict[str, dict[str, Any]],
    *,
    max_entries: int,
    timeout_s: int,
) -> tuple[list[dict[str, Any]], list[str]]:
    warnings: list[str] = []
    if len(subtree) >= max_entries:
        return subtree, warnings
    root = by_id.get(root_id)
    if root is None:
        warnings.append(f"{root_id}: root not found in curated source")
        return subtree, warnings

    # Ensure root has an ott id to seed expansion.
    root_ott = root.get("ott_id")
    if root_ott is None:
        meta, err = _fetch_opentree_metadata(root, timeout_s=timeout_s)
        if err is not None or meta is None:
            warnings.append(f"{root_id}: cannot resolve root OTT id ({err})")
            return subtree, warnings
        root["ott_id"] = meta.get("ott_id")
        root["opentree"] = meta
        root["opentree_name"] = meta.get("matched_name") or _normalize_name(root)
        root_ott = root["ott_id"]
    if root_ott is None:
        warnings.append(f"{root_id}: root has no OTT id after resolution")
        return subtree, warnings

    selected_by_id = {str(c.get("id")): c for c in subtree if c.get("id")}
    ott_to_id: dict[int, str] = {}
    for clade in selected_by_id.values():
        ott = clade.get("ott_id")
        if isinstance(ott, int):
            ott_to_id[ott] = str(clade["id"])
    queue: deque[tuple[str, int]] = deque([(root_id, int(root_ott))])
    synthetic_counter = 0

    while queue and len(selected_by_id) < max_entries:
        parent_id, parent_ott = queue.popleft()
        try:
            children = _fetch_opentree_children(parent_ott, timeout_s=timeout_s)
        except (urllib.error.URLError, urllib.error.HTTPError, ValueError) as exc:
            warnings.append(f"{parent_id}: child fetch failed ({exc})")
            continue
        for child in children:
            if len(selected_by_id) >= max_entries:
                break
            child_ott = int(child["ott_id"])
            existing_id = ott_to_id.get(child_ott)
            if existing_id is not None:
                queue.append((existing_id, child_ott))
                continue
            # Reuse curated clade if present by matching ott_id.
            curated_match = None
            for candidate in by_id.values():
                if candidate.get("ott_id") == child_ott:
                    curated_match = candidate
                    break
            if curated_match is not None:
                child_id = str(curated_match.get("id"))
                if child_id in selected_by_id:
                    queue.append((child_id, child_ott))
                    continue
                selected_by_id[child_id] = curated_match
                ott_to_id[child_ott] = child_id
                queue.append((child_id, child_ott))
                continue

            # Create synthetic detail-only node for Stage 2 SQLite population.
            base_name = str(child.get("name") or child.get("unique_name") or "")
            proposed_id = _slugify_id(base_name)
            child_id = proposed_id
            while child_id in selected_by_id:
                synthetic_counter += 1
                child_id = f"{proposed_id}_{synthetic_counter}"
            synthetic = {
                "id": child_id,
                "parent_id": parent_id,
                "common_label": base_name,
                "scientific_label": base_name,
                "scientific_rank": child.get("rank") or "clade",
                "ott_id": child_ott,
                "opentree_name": base_name,
                "display_groups": [],
                "display_priority": 9999,
                "min_zoom_level": "epoch",
                "zoomable": False,
                "confidence": "unknown",
                "uncertainty": "unknown",
                "range_note": "Needs curated dating",
                "opentree": {
                    "ott_id": child_ott,
                    "matched_name": base_name,
                    "unique_name": child.get("unique_name"),
                    "rank": child.get("rank"),
                    "flags": child.get("flags") or [],
                    "checked_at": dt.datetime.now(dt.timezone.utc).isoformat(),
                },
            }
            selected_by_id[child_id] = synthetic
            ott_to_id[child_ott] = child_id
            queue.append((child_id, child_ott))

    # Return deterministic order: breadth approximation by parent chain isn't critical for DB.
    # Keep root first, then by display_priority then id.
    rows = list(selected_by_id.values())
    rows.sort(key=lambda c: (int(c.get("display_priority") or 9999), str(c.get("id") or "")))
    rows_root = [c for c in rows if c.get("id") == root_id]
    rows_non_root = [c for c in rows if c.get("id") != root_id]
    return rows_root + rows_non_root, warnings


def _collect_subtree(
    root_id: str, by_id: dict[str, dict[str, Any]], children: dict[str, list[dict[str, Any]]]
) -> tuple[list[dict[str, Any]], dict[str, int]]:
    root = by_id.get(root_id)
    if root is None:
        raise ValueError(f"Root '{root_id}' not found in clades.yaml")
    ordered: list[dict[str, Any]] = [root]
    depth_by_id: dict[str, int] = {root_id: 0}
    queue: deque[tuple[str, int]] = deque([(root_id, 0)])
    seen = {root_id}
    while queue:
        parent_id, depth = queue.popleft()
        for child in children.get(parent_id, []):
            child_id = str(child.get("id") or "").strip()
            if not child_id or child_id in seen:
                continue
            seen.add(child_id)
            ordered.append(child)
            depth_by_id[child_id] = depth + 1
            queue.append((child_id, depth + 1))
    return ordered, depth_by_id


def _collect_first_layer(
    root_id: str,
    by_id: dict[str, dict[str, Any]],
    children: dict[str, list[dict[str, Any]]],
    *,
    max_direct_children: int | None,
    include_ids: set[str] | None,
) -> tuple[list[dict[str, Any]], dict[str, int]]:
    root = by_id.get(root_id)
    if root is None:
        raise ValueError(f"Root '{root_id}' not found in clades.yaml")
    rows: list[dict[str, Any]] = [root]
    direct = list(children.get(root_id, []))
    if include_ids is not None:
        direct = [c for c in direct if str(c.get("id") or "") in include_ids]
    direct.sort(key=lambda c: (int(c.get("display_priority") or 9999), str(c.get("id") or "")))
    if max_direct_children is not None:
        direct = direct[: max(0, max_direct_children)]
    rows.extend(direct)
    depth_by_id = {str(root.get("id")): 0}
    for child in direct:
        child_id = str(child.get("id") or "").strip()
        if child_id:
            depth_by_id[child_id] = 1
    return rows, depth_by_id


def _collect_progressive_to_cap(
    root_id: str,
    by_id: dict[str, dict[str, Any]],
    children: dict[str, list[dict[str, Any]]],
    *,
    max_entries: int,
    include_ids: set[str] | None,
) -> tuple[list[dict[str, Any]], dict[str, int]]:
    root = by_id.get(root_id)
    if root is None:
        raise ValueError(f"Root '{root_id}' not found in clades.yaml")
    cap = max(1, max_entries)
    selected: list[dict[str, Any]] = [root]
    depth_by_id: dict[str, int] = {root_id: 0}
    seen = {root_id}
    frontier: list[str] = [root_id]
    depth = 1

    while frontier and len(selected) < cap:
        candidates: list[dict[str, Any]] = []
        for parent_id in frontier:
            candidates.extend(children.get(parent_id, []))

        # Optional whitelist only applies to root's direct children.
        if depth == 1 and include_ids is not None:
            candidates = [
                c for c in candidates if str(c.get("id") or "").strip() in include_ids
            ]

        candidates.sort(
            key=lambda c: (int(c.get("display_priority") or 9999), str(c.get("id") or ""))
        )

        next_frontier: list[str] = []
        for clade in candidates:
            clade_id = str(clade.get("id") or "").strip()
            if not clade_id or clade_id in seen:
                continue
            if len(selected) >= cap:
                break
            seen.add(clade_id)
            selected.append(clade)
            depth_by_id[clade_id] = depth
            next_frontier.append(clade_id)

        frontier = next_frontier
        depth += 1

    return selected, depth_by_id


def _compute_depths(root_id: str, rows: list[dict[str, Any]]) -> dict[str, int]:
    by_id = {str(r.get("id")): r for r in rows if r.get("id")}
    children: dict[str, list[str]] = {}
    for row in rows:
        cid = str(row.get("id") or "").strip()
        pid = str(row.get("parent_id") or "").strip()
        if cid and pid and pid in by_id:
            children.setdefault(pid, []).append(cid)
    depth_by_id: dict[str, int] = {root_id: 0}
    queue: deque[tuple[str, int]] = deque([(root_id, 0)])
    seen = {root_id}
    while queue:
        parent, depth = queue.popleft()
        for cid in children.get(parent, []):
            if cid in seen:
                continue
            seen.add(cid)
            depth_by_id[cid] = depth + 1
            queue.append((cid, depth + 1))
    # Any disconnected rows get fallback depth 1 (keeps DB insert stable).
    for row_id in by_id:
        depth_by_id.setdefault(row_id, 1 if row_id != root_id else 0)
    return depth_by_id


def _create_schema(conn: sqlite3.Connection) -> None:
    conn.executescript(
        """
        DROP TABLE IF EXISTS clades_detail;
        DROP TABLE IF EXISTS clade_date_resolution;
        DROP TABLE IF EXISTS clade_date_source;
        DROP TABLE IF EXISTS clade_date_conflict;
        DROP TABLE IF EXISTS clade_date_proxy_mapping;
        DROP TABLE IF EXISTS clade_detail_roots;
        DROP TABLE IF EXISTS clade_data_version;

        CREATE TABLE clades_detail(
          id TEXT PRIMARY KEY,
          parent_id TEXT,
          ott_id INTEGER,
          opentree_name TEXT,
          scientific_label TEXT NOT NULL,
          common_label TEXT,
          scientific_rank TEXT,
          start_ma REAL,
          end_ma REAL,
          divergence_ma REAL,
          range_note TEXT,
          confidence TEXT,
          uncertainty TEXT,
          short_description TEXT,
          extinction_note TEXT,
          display_groups_json TEXT,
          display_priority INTEGER,
          min_zoom_level TEXT,
          representative_taxa_json TEXT,
          tags_json TEXT,
          branch_priority INTEGER,
          cladistic_role TEXT,
          zoomable INTEGER NOT NULL DEFAULT 0,
          include_in_main_tree INTEGER,
          collapsed_by_default INTEGER,
          opentree_json TEXT,
          age_confidence TEXT,
          source_topology TEXT,
          source_age TEXT,
          updated_at TEXT
        );

        CREATE TABLE clade_date_resolution(
          clade_id TEXT PRIMARY KEY,
          estimated_start_ma REAL,
          estimated_end_ma REAL,
          estimated_divergence_ma REAL,
          display_start_ma REAL,
          display_end_ma REAL,
          divergence_ma REAL,
          date_basis TEXT,
          date_confidence TEXT,
          date_resolution_method TEXT,
          date_notes TEXT,
          age_discrepancy_flag INTEGER NOT NULL DEFAULT 0,
          age_discrepancy_note TEXT,
          resolved_at TEXT,
          FOREIGN KEY(clade_id) REFERENCES clades_detail(id)
        );

        CREATE TABLE clade_date_source(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          clade_id TEXT NOT NULL,
          ordinal INTEGER NOT NULL,
          source_type TEXT,
          source_label TEXT,
          source_url TEXT,
          note TEXT,
          proxy_mapping_id TEXT,
          FOREIGN KEY(clade_id) REFERENCES clades_detail(id)
        );

        CREATE TABLE clade_date_conflict(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          clade_id TEXT NOT NULL,
          curated_start_ma REAL,
          resolved_start_ma REAL,
          delta_ma REAL,
          resolution_method TEXT,
          created_at TEXT,
          FOREIGN KEY(clade_id) REFERENCES clades_detail(id)
        );

        CREATE TABLE clade_date_proxy_mapping(
          unresolved_clade_id TEXT PRIMARY KEY,
          proxy_type TEXT,
          proxy_target_id TEXT,
          reason TEXT,
          date_field_to_use TEXT,
          proxy_confidence TEXT
        );

        CREATE TABLE clade_detail_roots(
          root_id TEXT NOT NULL,
          descendant_id TEXT NOT NULL,
          depth INTEGER,
          PRIMARY KEY(root_id, descendant_id)
        );

        CREATE TABLE clade_data_version(
          key TEXT PRIMARY KEY,
          value TEXT NOT NULL
        );

        CREATE INDEX idx_clade_date_resolution_method ON clade_date_resolution(date_resolution_method);
        CREATE INDEX idx_clade_date_resolution_confidence ON clade_date_resolution(date_confidence);
        CREATE INDEX idx_clade_date_resolution_discrepancy ON clade_date_resolution(age_discrepancy_flag);
        CREATE INDEX idx_clade_date_source_clade ON clade_date_source(clade_id);
        CREATE INDEX idx_clade_date_conflict_clade ON clade_date_conflict(clade_id);
        """
    )


def _as_json(value: Any) -> str | None:
    if value is None:
        return None
    return json.dumps(value, ensure_ascii=False, separators=(",", ":"))


def _to_int_bool(value: Any) -> int | None:
    if value is None:
        return None
    if isinstance(value, bool):
        return 1 if value else 0
    if isinstance(value, str):
        normalized = value.strip().lower()
        if normalized == "true":
            return 1
        if normalized == "false":
            return 0
    return None


def _has_valid_age(clade: dict[str, Any]) -> bool:
    start = clade.get("start_ma")
    end = clade.get("end_ma")
    return isinstance(start, (int, float)) and isinstance(end, (int, float)) and float(start) > float(end)


def _to_float(value: Any) -> float | None:
  if value is None:
      return None
  try:
      return float(value)
  except (TypeError, ValueError):
      return None


def _read_yaml_map(path: Path) -> dict[str, Any]:
    if not path.exists():
        return {}
    raw = yaml.safe_load(path.read_text(encoding="utf-8"))
    return raw if isinstance(raw, dict) else {}


def _resolve_age_fields(
    clades: list[dict[str, Any]],
    depth_by_id: dict[str, int],
    *,
    specialist_dates: dict[str, Any],
    educational_dates: dict[str, Any],
    proxy_mappings: dict[str, Any],
    discrepancy_threshold_ma: float,
) -> dict[str, Any]:
    by_id = {str(c.get("id")): c for c in clades if c.get("id")}
    ordered = sorted(clades, key=lambda c: (depth_by_id.get(str(c.get("id") or ""), 999), str(c.get("id") or "")))
    resolved = 0
    unresolved = 0
    inferred = 0
    discrepancies: list[dict[str, Any]] = []
    conflicts: list[dict[str, Any]] = []
    unresolved_ids: list[str] = []
    generalised_fallback_ids: list[str] = []
    proxy_ids: list[str] = []
    groups = {
        "specialist_curated_source": [],
        "pbdb_fossil_occurrence": [],
        "timetree_divergence": [],
        "reputable_educational_source": [],
        "generalised_knowledge_fallback": [],
        "proxy_timetree_mapping": [],
        "unresolved": [],
    }

    def is_descendant_of(clade_obj: dict[str, Any], ancestor_id: str) -> bool:
        visited: set[str] = set()
        current = clade_obj
        while True:
            cid = str(current.get("id") or "").strip()
            if not cid or cid in visited:
                return False
            if cid == ancestor_id:
                return True
            visited.add(cid)
            parent_id = str(current.get("parent_id") or "").strip()
            if not parent_id:
                return False
            parent = by_id.get(parent_id)
            if parent is None:
                return False
            current = parent

    for clade in ordered:
        clade_id = str(clade.get("id") or "")
        curated_start = _to_float(clade.get("start_ma"))
        curated_end = _to_float(clade.get("end_ma"))
        has_curated = curated_start is not None and curated_end is not None and curated_start > curated_end
        pbdb = clade.get("pbdb") if isinstance(clade.get("pbdb"), dict) else None
        pbdb_start = _to_float((pbdb or {}).get("start_ma"))
        pbdb_end = _to_float((pbdb or {}).get("end_ma"))
        molecular = _to_float(clade.get("molecular_divergence_ma") if clade.get("molecular_divergence_ma") is not None else clade.get("divergence_ma"))
        clade["fossil_first_ma"] = pbdb_start
        clade["fossil_last_ma"] = pbdb_end
        clade["molecular_divergence_ma"] = molecular

        resolved_start: float | None = None
        resolved_end: float | None = None
        resolved_divergence: float | None = molecular
        method = "unresolved"
        basis = "unresolved"
        confidence = "low"
        notes: list[str] = []
        sources: list[dict[str, Any]] = []

        specialist = specialist_dates.get(clade_id)
        if isinstance(specialist, dict):
            s_start = _to_float(specialist.get("start_ma"))
            s_end = _to_float(specialist.get("end_ma"))
            if s_start is not None and s_end is not None and s_start > s_end:
                resolved_start = s_start
                resolved_end = s_end
                resolved_divergence = _to_float(specialist.get("divergence_ma")) or resolved_divergence
                method = "specialist_curated_source"
                basis = str(specialist.get("date_basis") or "curated_first_appearance")
                confidence = str(specialist.get("date_confidence") or "high")
                sources.append({"source_type": "specialist_literature", "source_label": str(specialist.get("source_label") or "Specialist curated source"), "note": str(specialist.get("note") or "Specialist curated source applied.")})

        if resolved_start is None and pbdb_start is not None and pbdb_end is not None and pbdb_start > pbdb_end:
            resolved_start = pbdb_start
            resolved_end = pbdb_end
            method = "pbdb_fossil_occurrence"
            basis = "fossil_first_appearance"
            confidence = "moderate"
            sources.append({"source_type": "pbdb", "source_label": "Paleobiology Database", "note": "First fossil occurrence used as displayed start_ma."})

        if resolved_start is None and resolved_divergence is not None:
            resolved_start = resolved_divergence
            resolved_end = 0.0
            method = "timetree_divergence"
            basis = "molecular_or_synthesis_divergence_estimate"
            confidence = "approximate"
            sources.append({"source_type": "timetree", "source_label": "TimeTree", "note": "Divergence estimate retained as divergence_ma."})

        educational = educational_dates.get(clade_id)
        if resolved_start is None and isinstance(educational, dict):
            e_start = _to_float(educational.get("start_ma"))
            e_end = _to_float(educational.get("end_ma"))
            if e_start is not None and e_end is not None and e_start > e_end:
                resolved_start = e_start
                resolved_end = e_end
                method = "reputable_educational_source"
                basis = "educational_first_appearance_estimate"
                confidence = "approximate"
                sources.append({"source_type": "reputable_educational", "source_label": str(educational.get("source_label") or "Reputable educational source"), "note": str(educational.get("note") or "Broad educational estimate.")})

        if resolved_start is None and has_curated:
            resolved_start = curated_start
            resolved_end = curated_end
            method = "generalised_knowledge_fallback"
            basis = "curated_general_knowledge_estimate"
            confidence = "low"
            notes.append(f"WARNING: {clade_id} date filled using generalised knowledge fallback.")
            generalised_fallback_ids.append(clade_id)
            sources.append({"source_type": "generalised_knowledge", "source_label": "Curated educational fallback", "note": "Used only because higher-ranked sources did not yield a usable result."})

        # Additional generalized fallback profile for unresolved Dinosauria families.
        if resolved_start is None:
            rank = str(clade.get("scientific_rank") or "").strip().lower()
            if rank == "family" and is_descendant_of(clade, "dinosauria"):
                resolved_start = 120.0
                resolved_end = 66.0
                method = "generalised_knowledge_fallback"
                basis = "curated_general_knowledge_estimate"
                confidence = "low"
                notes.append(
                    f"WARNING: {clade_id} date filled using generalised knowledge fallback (Dinosauria-family profile)."
                )
                generalised_fallback_ids.append(clade_id)
                sources.append(
                    {
                        "source_type": "generalised_knowledge",
                        "source_label": "Curated educational fallback",
                        "note": "Family-level Dinosauria proxy profile (Early Cretaceous first appearance, end-Cretaceous extinction).",
                    }
                )

        if resolved_start is None:
            proxy = proxy_mappings.get(clade_id) if isinstance(proxy_mappings, dict) else None
            if isinstance(proxy, dict):
                target_id = str(proxy.get("proxy_target_id") or "").strip()
                target = by_id.get(target_id)
                proxy_field = str(proxy.get("date_field_to_use") or "start_ma")
                proxy_value = _to_float((target or {}).get(proxy_field))
                proxy_end = _to_float((target or {}).get("end_ma"))
                if proxy_value is not None:
                    resolved_start = proxy_value
                    resolved_end = proxy_end if proxy_end is not None and proxy_value > proxy_end else max(0.0, proxy_value - 0.1)
                    method = "proxy_timetree_mapping"
                    basis = "proxy_divergence_estimate"
                    confidence = str(proxy.get("proxy_confidence") or "low")
                    proxy_ids.append(clade_id)
                    sources.append({"source_type": "timetree_proxy", "source_label": "TimeTree proxy using representative taxa", "proxy_mapping_id": clade_id, "note": "Date is based on proxy taxa, not direct clade resolution."})

        if resolved_start is None:
            unresolved += 1
            unresolved_ids.append(clade_id)
            groups["unresolved"].append(clade_id)
            notes.append(f"No usable specialist, PBDB, TimeTree, or reputable educational date found for {clade_id}.")
        else:
            if resolved_end is None:
                resolved_end = 0.0
            if resolved_start <= resolved_end:
                resolved_end = max(0.0, resolved_start - 0.1)
            resolved += 1
            if method in groups:
                groups[method].append(clade_id)

        clade["estimated_start_ma"] = resolved_start
        clade["estimated_end_ma"] = resolved_end
        clade["estimated_divergence_ma"] = resolved_divergence
        clade["date_basis"] = basis
        clade["date_confidence"] = confidence
        clade["date_sources"] = sources
        clade["date_resolution_method"] = method
        clade["date_notes"] = " ".join(notes).strip() if notes else None
        clade["display_start_ma"] = resolved_start
        clade["display_end_ma"] = resolved_end
        clade["age_resolution_method"] = method
        clade["age_resolution_confidence"] = confidence
        clade["age_sources_json"] = {"date_sources": sources}

        if has_curated and resolved_start is not None:
            delta = abs(curated_start - resolved_start)
            if delta >= discrepancy_threshold_ma:
                conflicts.append({"id": clade_id, "curated_start_ma": curated_start, "resolved_start_ma": resolved_start, "delta_ma": delta, "method": method})

        discrepancy_flag = 0
        discrepancy_note = None
        if resolved_start is not None and resolved_divergence is not None:
            delta = abs(resolved_start - resolved_divergence)
            if delta >= discrepancy_threshold_ma:
                discrepancy_flag = 1
                discrepancy_note = f"resolved_start_ma={resolved_start:.1f} vs divergence_ma={resolved_divergence:.1f} (delta={delta:.1f} Ma)"
                discrepancies.append({"id": clade_id, "estimated_start_ma": resolved_start, "molecular_divergence_ma": resolved_divergence, "delta_ma": delta, "method": method})
        clade["age_discrepancy_flag"] = discrepancy_flag
        clade["age_discrepancy_note"] = discrepancy_note

        if not has_curated and resolved_start is not None and resolved_end is not None:
            clade["start_ma"] = resolved_start
            clade["end_ma"] = resolved_end
        if clade.get("divergence_ma") is None and resolved_divergence is not None:
            clade["divergence_ma"] = resolved_divergence

    discrepancies.sort(key=lambda row: row["delta_ma"], reverse=True)
    conflicts.sort(key=lambda row: row["delta_ma"], reverse=True)
    return {
        "resolved": resolved,
        "unresolved": unresolved,
        "inferred": inferred,
        "discrepancies": discrepancies,
        "unresolved_ids": unresolved_ids,
        "generalised_fallback_ids": generalised_fallback_ids,
        "proxy_ids": proxy_ids,
        "conflicts": conflicts,
        "groups": groups,
    }


def _insert_clades(
    conn: sqlite3.Connection,
    clades: list[dict[str, Any]],
    updated_at: str,
    *,
    source_topology: str,
    source_age: str,
) -> None:
    sql = """
    INSERT INTO clades_detail(
      id,parent_id,ott_id,opentree_name,scientific_label,common_label,scientific_rank,
      start_ma,end_ma,divergence_ma,range_note,confidence,uncertainty,short_description,
      extinction_note,display_groups_json,display_priority,min_zoom_level,
      representative_taxa_json,tags_json,branch_priority,cladistic_role,zoomable,
      include_in_main_tree,collapsed_by_default,opentree_json,age_confidence,
      source_topology,source_age,updated_at
    ) VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)
    """
    rows: list[tuple[Any, ...]] = []
    for c in clades:
        rows.append(
            (
                c.get("id"),
                c.get("parent_id"),
                c.get("ott_id"),
                c.get("opentree_name"),
                c.get("scientific_label") or c.get("label") or c.get("common_label"),
                c.get("common_label") or c.get("label"),
                c.get("scientific_rank"),
                c.get("start_ma"),
                c.get("end_ma"),
                c.get("divergence_ma"),
                c.get("range_note"),
                c.get("confidence"),
                c.get("uncertainty"),
                c.get("short_description"),
                c.get("extinction_note"),
                _as_json(c.get("display_groups") or []),
                c.get("display_priority"),
                c.get("min_zoom_level"),
                _as_json(c.get("representative_taxa") or []),
                _as_json(c.get("tags") or []),
                c.get("branch_priority"),
                c.get("cladistic_role"),
                _to_int_bool(c.get("zoomable")) or 0,
                _to_int_bool(c.get("include_in_main_tree")),
                _to_int_bool(c.get("collapsed_by_default")),
                _as_json(c.get("opentree")),
                c.get("confidence") or "unknown",
                source_topology,
                source_age,
                updated_at,
            )
        )
    conn.executemany(sql, rows)


def _insert_root_mapping(
    conn: sqlite3.Connection, root_id: str, depth_by_id: dict[str, int]
) -> None:
    rows = [(root_id, clade_id, depth) for clade_id, depth in depth_by_id.items()]
    conn.executemany(
        "INSERT INTO clade_detail_roots(root_id,descendant_id,depth) VALUES (?,?,?)", rows
    )


def _insert_date_resolution(
    conn: sqlite3.Connection,
    clades: list[dict[str, Any]],
    resolved_at: str,
) -> None:
    rows: list[tuple[Any, ...]] = []
    for c in clades:
        clade_id = c.get("id")
        if not clade_id:
            continue
        rows.append(
            (
                clade_id,
                c.get("estimated_start_ma"),
                c.get("estimated_end_ma"),
                c.get("estimated_divergence_ma"),
                c.get("display_start_ma"),
                c.get("display_end_ma"),
                c.get("divergence_ma"),
                c.get("date_basis"),
                c.get("date_confidence"),
                c.get("date_resolution_method"),
                c.get("date_notes"),
                _to_int_bool(c.get("age_discrepancy_flag")) or 0,
                c.get("age_discrepancy_note"),
                resolved_at,
            )
        )
    conn.executemany(
        """
        INSERT INTO clade_date_resolution(
          clade_id,estimated_start_ma,estimated_end_ma,estimated_divergence_ma,
          display_start_ma,display_end_ma,divergence_ma,date_basis,date_confidence,
          date_resolution_method,date_notes,age_discrepancy_flag,age_discrepancy_note,resolved_at
        ) VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?)
        """,
        rows,
    )


def _insert_date_sources(conn: sqlite3.Connection, clades: list[dict[str, Any]]) -> None:
    rows: list[tuple[Any, ...]] = []
    for c in clades:
        clade_id = c.get("id")
        if not clade_id:
            continue
        sources = c.get("date_sources")
        if not isinstance(sources, list):
            continue
        for i, source in enumerate(sources):
            if not isinstance(source, dict):
                continue
            rows.append(
                (
                    clade_id,
                    i,
                    source.get("source_type"),
                    source.get("source_label"),
                    source.get("url"),
                    source.get("note"),
                    source.get("proxy_mapping_id"),
                )
            )
    if rows:
        conn.executemany(
            """
            INSERT INTO clade_date_source(
              clade_id,ordinal,source_type,source_label,source_url,note,proxy_mapping_id
            ) VALUES (?,?,?,?,?,?,?)
            """,
            rows,
        )


def _insert_date_conflicts(conn: sqlite3.Connection, age_resolution: dict[str, Any], created_at: str) -> None:
    conflicts = age_resolution.get("conflicts", [])
    if not isinstance(conflicts, list) or not conflicts:
        return
    rows: list[tuple[Any, ...]] = []
    for row in conflicts:
        if not isinstance(row, dict):
            continue
        rows.append(
            (
                row.get("id"),
                row.get("curated_start_ma"),
                row.get("resolved_start_ma"),
                row.get("delta_ma"),
                row.get("method"),
                created_at,
            )
        )
    if rows:
        conn.executemany(
            """
            INSERT INTO clade_date_conflict(
              clade_id,curated_start_ma,resolved_start_ma,delta_ma,resolution_method,created_at
            ) VALUES (?,?,?,?,?,?)
            """,
            rows,
        )


def _insert_proxy_mappings(conn: sqlite3.Connection, proxy_mappings: dict[str, Any]) -> None:
    if not isinstance(proxy_mappings, dict) or not proxy_mappings:
        return
    rows: list[tuple[Any, ...]] = []
    for unresolved_id, mapping in proxy_mappings.items():
        if not isinstance(mapping, dict):
            continue
        rows.append(
            (
                unresolved_id,
                mapping.get("proxy_type"),
                mapping.get("proxy_target_id"),
                mapping.get("reason"),
                mapping.get("date_field_to_use"),
                mapping.get("proxy_confidence"),
            )
        )
    if rows:
        conn.executemany(
            """
            INSERT INTO clade_date_proxy_mapping(
              unresolved_clade_id,proxy_type,proxy_target_id,reason,date_field_to_use,proxy_confidence
            ) VALUES (?,?,?,?,?,?)
            """,
            rows,
        )


def _insert_version(conn: sqlite3.Connection, root_id: str, input_path: Path) -> None:
    now = dt.datetime.now(dt.timezone.utc).isoformat()
    rows = [
        ("schema_version", "2"),
        ("generated_at", now),
        ("root_id", root_id),
        ("source", str(input_path)),
    ]
    conn.executemany("INSERT INTO clade_data_version(key,value) VALUES (?,?)", rows)


def _report(
    report_path: Path,
    root_id: str,
    subtree: list[dict[str, Any]],
    depth_by_id: dict[str, int],
    db_path: Path,
    *,
    source_topology: str,
    source_age: str,
    opentree_applied: int,
    pbdb_applied: int,
    timetree_applied: int,
    age_resolution: dict[str, Any],
    warnings: list[str],
) -> None:
    missing_age = [
        c.get("id")
        for c in subtree
        if c.get("start_ma") is None or c.get("end_ma") is None
    ]
    missing_label = [
        c.get("id")
        for c in subtree
        if not (c.get("scientific_label") or c.get("common_label") or c.get("label"))
    ]
    max_depth = max(depth_by_id.values()) if depth_by_id else 0
    lines = [
        "# Stage 1 Hybrid Data Report",
        "",
        f"- Generated: {dt.datetime.now(dt.timezone.utc).isoformat()}",
        f"- Root: `{root_id}`",
        f"- SQLite DB: `{db_path}`",
        f"- Clades in subtree: **{len(subtree)}**",
        f"- Max depth: **{max_depth}**",
        f"- Topology source: `{source_topology}`",
        f"- Age source: `{source_age}`",
        f"- OpenTree enrichments applied: **{opentree_applied}**",
        f"- PBDB age enrichments applied: **{pbdb_applied}**",
        f"- TimeTree divergence enrichments applied: **{timetree_applied}**",
        f"- Age resolved: **{age_resolution.get('resolved', 0)}**",
        f"- Age unresolved: **{age_resolution.get('unresolved', 0)}**",
        f"- Age inferred from ancestor: **{age_resolution.get('inferred', 0)}**",
        f"- Age discrepancies flagged: **{len(age_resolution.get('discrepancies', []))}**",
        "",
        "## Validation",
        "",
        f"- Missing `start_ma`/`end_ma`: **{len(missing_age)}**",
        f"- Missing label fields: **{len(missing_label)}**",
        "",
        "## Sample IDs",
        "",
    ]
    for clade in subtree[:25]:
        lines.append(f"- `{clade.get('id')}`")
    if missing_age:
        lines.extend(["", "## Missing Ages", ""])
        for clade_id in missing_age[:100]:
            lines.append(f"- `{clade_id}`")
    if warnings:
        lines.extend(["", "## Warnings", ""])
        for warning in warnings[:200]:
            lines.append(f"- {warning}")
    report_path.parent.mkdir(parents=True, exist_ok=True)
    report_path.write_text("\n".join(lines) + "\n", encoding="utf-8")


def _write_discrepancy_report(
    path: Path,
    root_id: str,
    age_resolution: dict[str, Any],
    *,
    threshold_ma: float,
) -> None:
    discrepancies = age_resolution.get("discrepancies", [])
    lines = [
        "# Clade Age Discrepancy Report",
        "",
        f"- Generated: {dt.datetime.now(dt.timezone.utc).isoformat()}",
        f"- Root: `{root_id}`",
        f"- Threshold: **{threshold_ma:.1f} Ma**",
        f"- Flagged clades: **{len(discrepancies)}**",
        "",
    ]
    if discrepancies:
        lines.extend(
            [
                "## Major Discrepancies",
                "",
                "| Clade ID | Estimated Start (Ma) | Molecular Divergence (Ma) | Delta (Ma) | Method |",
                "|---|---:|---:|---:|---|",
            ]
        )
        for row in discrepancies[:300]:
            lines.append(
                f"| `{row['id']}` | {row['estimated_start_ma']:.1f} | "
                f"{row['molecular_divergence_ma']:.1f} | {row['delta_ma']:.1f} | "
                f"`{row['method']}` |"
            )
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text("\n".join(lines) + "\n", encoding="utf-8")


def _write_date_resolution_report(
    path: Path,
    root_id: str,
    age_resolution: dict[str, Any],
) -> None:
    groups = age_resolution.get("groups", {})
    unresolved_ids = age_resolution.get("unresolved_ids", [])
    generalised_ids = age_resolution.get("generalised_fallback_ids", [])
    proxy_ids = age_resolution.get("proxy_ids", [])
    conflicts = age_resolution.get("conflicts", [])
    lines = [
        "# Clade Date Resolution Report",
        "",
        f"- Generated: {dt.datetime.now(dt.timezone.utc).isoformat()}",
        f"- Root: `{root_id}`",
        f"- Resolved: **{age_resolution.get('resolved', 0)}**",
        f"- Unresolved: **{age_resolution.get('unresolved', 0)}**",
        "",
        "## Grouped Outcomes",
        "",
    ]
    ordered_groups = [
        "specialist_curated_source",
        "pbdb_fossil_occurrence",
        "timetree_divergence",
        "reputable_educational_source",
        "generalised_knowledge_fallback",
        "proxy_timetree_mapping",
        "unresolved",
    ]
    for key in ordered_groups:
        ids = groups.get(key, [])
        lines.append(f"### {key}")
        lines.append("")
        lines.append(f"Count: **{len(ids)}**")
        lines.append("")
        for clade_id in ids[:300]:
            lines.append(f"- `{clade_id}`")
        lines.append("")
    lines.extend(["## Unresolved Clades", ""])
    for clade_id in unresolved_ids[:500]:
        lines.append(f"- `{clade_id}`")
    lines.extend(["", "## Generalised Knowledge Fallback", ""])
    for clade_id in generalised_ids[:500]:
        lines.append(f"- `{clade_id}`")
    lines.extend(["", "## Proxy Strategy", ""])
    for clade_id in proxy_ids[:500]:
        lines.append(f"- `{clade_id}`")
    lines.extend(["", "## Curated vs Resolved Conflicts", ""])
    if conflicts:
        lines.append("| Clade ID | Curated start (Ma) | Resolved start (Ma) | Delta (Ma) | Method |")
        lines.append("|---|---:|---:|---:|---|")
        for row in conflicts[:500]:
            lines.append(
                f"| `{row['id']}` | {row['curated_start_ma']:.1f} | {row['resolved_start_ma']:.1f} | {row['delta_ma']:.1f} | `{row['method']}` |"
            )
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text("\n".join(lines) + "\n", encoding="utf-8")


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--input", type=Path, default=DEFAULT_INPUT)
    parser.add_argument("--db", type=Path, default=DEFAULT_DB)
    parser.add_argument("--report", type=Path, default=DEFAULT_REPORT)
    parser.add_argument("--date-report", type=Path, default=DEFAULT_DATE_REPORT)
    parser.add_argument("--specialist-dates", type=Path, default=Path("data/specialist_clade_dates.yaml"))
    parser.add_argument("--educational-dates", type=Path, default=Path("data/educational_clade_dates.yaml"))
    parser.add_argument("--proxy-mappings", type=Path, default=Path("data/proxy_date_mappings.yaml"))
    parser.add_argument("--root-id", default="dinosauria")
    parser.add_argument("--fetch-opentree", action="store_true")
    parser.add_argument("--expand-from-opentree", action="store_true")
    parser.add_argument("--fetch-pbdb", action="store_true")
    parser.add_argument("--prefer-pbdb-age", action="store_true")
    parser.add_argument("--fetch-timetree", action="store_true")
    parser.add_argument("--timetree-cache", type=Path, default=Path("data/timetree_cache.json"))
    parser.add_argument(
        "--age-discrepancy-report",
        type=Path,
        default=Path("docs/clade_age_discrepancy_report.md"),
    )
    parser.add_argument("--discrepancy-threshold-ma", type=float, default=25.0)
    parser.add_argument("--timeout-s", type=int, default=20)
    parser.add_argument(
        "--stage",
        choices=["full-subtree", "first-layer", "progressive"],
        default="progressive",
        help="Selection mode for detail rows under root.",
    )
    parser.add_argument(
        "--max-direct-children",
        type=int,
        default=40,
        help="Only used for --stage first-layer.",
    )
    parser.add_argument(
        "--max-entries",
        type=int,
        default=40,
        help="Only used for --stage progressive (includes root).",
    )
    parser.add_argument(
        "--include-ids",
        default="",
        help="Comma-separated direct child IDs to include in first-layer mode.",
    )
    args = parser.parse_args()

    clades = _read_yaml(args.input)
    by_id = {str(c.get("id")): c for c in clades if c.get("id")}
    children = _build_children_index(clades)
    include_ids = {
        item.strip()
        for item in args.include_ids.split(",")
        if item.strip()
    } or None
    if args.stage == "first-layer":
        subtree, depth_by_id = _collect_first_layer(
            args.root_id,
            by_id,
            children,
            max_direct_children=args.max_direct_children,
            include_ids=include_ids,
        )
    elif args.stage == "progressive":
        subtree, depth_by_id = _collect_progressive_to_cap(
            args.root_id,
            by_id,
            children,
            max_entries=args.max_entries,
            include_ids=include_ids,
        )
    else:
        subtree, depth_by_id = _collect_subtree(args.root_id, by_id, children)
    warnings: list[str] = []
    opentree_applied = 0
    pbdb_applied = 0
    timetree_applied = 0
    timetree_cache = _load_timetree_cache(args.timetree_cache) if args.fetch_timetree else {}
    opentree_taxon_info_cache: dict[int, dict[str, Any]] = {}

    if args.expand_from_opentree:
        expanded, expand_warnings = _expand_subtree_from_opentree(
            args.root_id,
            subtree,
            by_id,
            max_entries=args.max_entries if args.stage == "progressive" else max(len(subtree), 40),
            timeout_s=args.timeout_s,
        )
        subtree = expanded
        depth_by_id = _compute_depths(args.root_id, subtree)
        warnings.extend(expand_warnings)

    # Optional enrichments (hooked behind flags). Run after expansion so
    # OpenTree-derived detail nodes can also receive metadata/ages.
    for clade in subtree:
        if args.fetch_opentree:
            meta, err = _fetch_opentree_metadata(clade, timeout_s=args.timeout_s)
            if err is not None:
                warnings.append(f"{clade.get('id')}: {err}")
            elif meta is not None:
                clade["opentree"] = meta
                clade["ott_id"] = meta.get("ott_id")
                clade["opentree_name"] = meta.get("matched_name") or _normalize_name(clade)
                opentree_applied += 1
        if args.fetch_pbdb:
            age_meta, err = _fetch_pbdb_age(clade, timeout_s=args.timeout_s)
            if err is not None:
                warnings.append(f"{clade.get('id')}: {err}")
            elif age_meta is not None:
                clade["pbdb"] = age_meta
                # Default behavior: fill missing/invalid ages from PBDB.
                # --prefer-pbdb-age still force-overrides curated values.
                if args.prefer_pbdb_age or not _has_valid_age(clade):
                    clade["start_ma"] = age_meta["start_ma"]
                    clade["end_ma"] = age_meta["end_ma"]
                    clade["confidence"] = "pbdb_derived"
                pbdb_applied += 1
        if args.fetch_timetree:
            parent_id = str(clade.get("parent_id") or "").strip()
            parent = by_id.get(parent_id)
            if parent is not None:
                subtree_by_id = {str(c.get("id")): c for c in subtree if c.get("id")}
                child_chain = _ancestor_chain(clade, subtree_by_id, max_hops=3)
                parent_chain = _ancestor_chain(parent, subtree_by_id, max_hops=3)
                resolved = False
                last_error: str | None = None
                # Attempt OTT->NCBI taxid bridge first.
                for child_ancestor in child_chain:
                    if resolved:
                        break
                    child_ott = _to_float(child_ancestor.get("ott_id"))
                    if child_ott is None:
                        continue
                    child_ott_i = int(child_ott)
                    child_info = opentree_taxon_info_cache.get(child_ott_i)
                    if child_info is None:
                        fetched, err = _fetch_opentree_taxon_info_by_ott(child_ott_i, timeout_s=args.timeout_s)
                        if err is None and fetched is not None:
                            child_info = fetched
                            opentree_taxon_info_cache[child_ott_i] = fetched
                    child_ncbi = _extract_ncbi_taxid((child_info or {}).get("tax_sources"))
                    if child_ncbi is None:
                        child_ncbi = _extract_ncbi_taxid(((child_ancestor.get("opentree") or {}) if isinstance(child_ancestor.get("opentree"), dict) else {}).get("tax_sources"))
                    if child_ncbi is None:
                        continue
                    for parent_ancestor in parent_chain:
                        if resolved:
                            break
                        parent_ott = _to_float(parent_ancestor.get("ott_id"))
                        if parent_ott is None:
                            continue
                        parent_ott_i = int(parent_ott)
                        parent_info = opentree_taxon_info_cache.get(parent_ott_i)
                        if parent_info is None:
                            fetched, err = _fetch_opentree_taxon_info_by_ott(parent_ott_i, timeout_s=args.timeout_s)
                            if err is None and fetched is not None:
                                parent_info = fetched
                                opentree_taxon_info_cache[parent_ott_i] = fetched
                        parent_ncbi = _extract_ncbi_taxid((parent_info or {}).get("tax_sources"))
                        if parent_ncbi is None:
                            parent_ncbi = _extract_ncbi_taxid(((parent_ancestor.get("opentree") or {}) if isinstance(parent_ancestor.get("opentree"), dict) else {}).get("tax_sources"))
                        if parent_ncbi is None or child_ncbi == parent_ncbi:
                            continue
                        id_cache_key = f"ncbi:{child_ncbi}|||ncbi:{parent_ncbi}"
                        cached = timetree_cache.get(id_cache_key)
                        if isinstance(cached, dict) and cached.get("divergence_ma") is not None:
                            clade["timetree"] = cached
                            clade["molecular_divergence_ma"] = cached.get("divergence_ma")
                            timetree_applied += 1
                            resolved = True
                            break
                        if not (isinstance(cached, dict) and cached.get("error")):
                            tt_meta, err = _fetch_timetree_pairwise_ids(
                                child_ncbi,
                                parent_ncbi,
                                timeout_s=args.timeout_s,
                            )
                            if err is None and tt_meta is not None:
                                timetree_cache[id_cache_key] = tt_meta
                                clade["timetree"] = tt_meta
                                clade["molecular_divergence_ma"] = tt_meta.get("divergence_ma")
                                timetree_applied += 1
                                resolved = True
                                break
                            timetree_cache[id_cache_key] = {"error": err}
                            last_error = err
                # Fallback to name matching.
                for child_ancestor in child_chain:
                    if resolved:
                        break
                    child_candidates = _timetree_candidate_names(child_ancestor)
                    for parent_ancestor in parent_chain:
                        if resolved:
                            break
                        parent_candidates = _timetree_candidate_names(parent_ancestor)
                        for child_name in child_candidates:
                            if resolved:
                                break
                            for parent_name in parent_candidates:
                                if child_name.lower() == parent_name.lower():
                                    continue
                                cache_key = f"{child_name.lower()}|||{parent_name.lower()}"
                                cached = timetree_cache.get(cache_key)
                                if isinstance(cached, dict) and cached.get("divergence_ma") is not None:
                                    clade["timetree"] = cached
                                    clade["molecular_divergence_ma"] = cached.get("divergence_ma")
                                    timetree_applied += 1
                                    resolved = True
                                    break
                                if isinstance(cached, dict) and cached.get("error"):
                                    last_error = str(cached.get("error"))
                                    continue
                                tt_meta, err = _fetch_timetree_pairwise(
                                    child_name,
                                    parent_name,
                                    timeout_s=args.timeout_s,
                                )
                                if err is not None:
                                    timetree_cache[cache_key] = {"error": err}
                                    last_error = err
                                    continue
                                if tt_meta is not None:
                                    timetree_cache[cache_key] = tt_meta
                                    clade["timetree"] = tt_meta
                                    clade["molecular_divergence_ma"] = tt_meta.get("divergence_ma")
                                    timetree_applied += 1
                                    resolved = True
                                    break
                if not resolved and last_error is not None:
                    warnings.append(f"{clade.get('id')}: {last_error}")

    source_topology = (
        "opentree+curated_yaml_stage1" if args.fetch_opentree else "curated_yaml_stage1"
    )
    if args.fetch_timetree:
        _save_timetree_cache(args.timetree_cache, timetree_cache)
    if args.fetch_pbdb and args.fetch_timetree:
        source_age = "pbdb+timetree+curated_yaml_stage1"
    elif args.fetch_pbdb:
        source_age = "pbdb+curated_yaml_stage1"
    elif args.fetch_timetree:
        source_age = "timetree+curated_yaml_stage1"
    else:
        source_age = "curated_yaml_stage1"
    specialist_dates = _read_yaml_map(args.specialist_dates)
    educational_dates = _read_yaml_map(args.educational_dates)
    proxy_mappings = _read_yaml_map(args.proxy_mappings)
    age_resolution = _resolve_age_fields(
        subtree,
        depth_by_id,
        specialist_dates=specialist_dates,
        educational_dates=educational_dates,
        proxy_mappings=proxy_mappings,
        discrepancy_threshold_ma=max(0.0, float(args.discrepancy_threshold_ma)),
    )

    args.db.parent.mkdir(parents=True, exist_ok=True)
    with sqlite3.connect(args.db) as conn:
        _create_schema(conn)
        now = dt.datetime.now(dt.timezone.utc).isoformat()
        _insert_clades(
            conn,
            subtree,
            now,
            source_topology=source_topology,
            source_age=source_age,
        )
        _insert_date_resolution(conn, subtree, now)
        _insert_date_sources(conn, subtree)
        _insert_date_conflicts(conn, age_resolution, now)
        _insert_proxy_mappings(conn, proxy_mappings)
        _insert_root_mapping(conn, args.root_id, depth_by_id)
        _insert_version(conn, args.root_id, args.input)
        conn.commit()

    _report(
        args.report,
        args.root_id,
        subtree,
        depth_by_id,
        args.db,
        source_topology=source_topology,
        source_age=source_age,
        opentree_applied=opentree_applied,
        pbdb_applied=pbdb_applied,
        timetree_applied=timetree_applied,
        age_resolution=age_resolution,
        warnings=warnings,
    )
    _write_discrepancy_report(
        args.age_discrepancy_report,
        args.root_id,
        age_resolution,
        threshold_ma=max(0.0, float(args.discrepancy_threshold_ma)),
    )
    _write_date_resolution_report(args.date_report, args.root_id, age_resolution)
    print(f"Built Stage 1 detail DB: {args.db}")
    print(f"Wrote Stage 1 report: {args.report}")
    print(f"Wrote age discrepancy report: {args.age_discrepancy_report}")
    print(f"Wrote date resolution report: {args.date_report}")
    print(f"Subtree size ({args.root_id}): {len(subtree)}")
    print(f"Stage mode: {args.stage}")
    if warnings:
        print(f"Warnings: {len(warnings)} (see report)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
