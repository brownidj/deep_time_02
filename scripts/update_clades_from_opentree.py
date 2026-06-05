#!/usr/bin/env python3
"""Resolve and validate curated clades against OpenTree at build time.

This script is intentionally offline-safe for runtime: it updates cache/report
artifacts and optionally updates clade metadata in `data/clades.yaml` only when
`--write-clades` is explicitly requested.
"""

from __future__ import annotations

import argparse
import datetime as dt
import json
import sys
import urllib.error
import urllib.request
from pathlib import Path
from typing import Any

try:
    import yaml
except ModuleNotFoundError:  # pragma: no cover - script guard
    yaml = None


OPENTREE_BASE = "https://api.opentreeoflife.org/v3"
DEFAULT_CLADES = Path("data/clades.yaml")
DEFAULT_CACHE = Path("docs/opentree/clades_opentree_cache.yaml")
DEFAULT_REPORT = Path("docs/opentree/clades_opentree_report.md")


def _require_yaml() -> None:
    if yaml is None:
        raise RuntimeError(
            "pyyaml is not installed. Install it with `pip install pyyaml`."
        )


def _read_yaml(path: Path) -> Any:
    _require_yaml()
    return yaml.safe_load(path.read_text(encoding="utf-8"))


def _write_yaml(path: Path, data: Any) -> None:
  _require_yaml()
  path.parent.mkdir(parents=True, exist_ok=True)
  path.write_text(
    yaml.safe_dump(data, sort_keys=False, allow_unicode=True),
    encoding="utf-8",
  )


def _post(endpoint: str, payload: dict[str, Any], timeout_s: int) -> dict[str, Any]:
    body = json.dumps(payload).encode("utf-8")
    request = urllib.request.Request(
        f"{OPENTREE_BASE}{endpoint}",
        data=body,
        headers={"Content-Type": "application/json"},
        method="POST",
    )
    try:
        with urllib.request.urlopen(request, timeout=timeout_s) as response:
            return json.loads(response.read().decode("utf-8"))
    except urllib.error.HTTPError as exc:
        detail = exc.read().decode("utf-8", errors="replace")
        raise RuntimeError(f"OpenTree HTTP {exc.code} on {endpoint}: {detail}") from exc
    except urllib.error.URLError as exc:
        raise RuntimeError(f"OpenTree request failed for {endpoint}: {exc}") from exc


def _normalize_name(clade: dict[str, Any]) -> str:
    return (
        (clade.get("opentree_name") or "").strip()
        or (clade.get("scientific_label") or "").strip()
        or (clade.get("common_label") or "").strip()
        or (clade.get("label") or "").strip()
    )


def _to_int(value: Any) -> int | None:
    if isinstance(value, bool):
        return None
    if isinstance(value, int):
        return value
    if isinstance(value, float):
        return int(value)
    if isinstance(value, str):
        try:
            return int(value.strip())
        except ValueError:
            return None
    return None


def _resolve_one_name(name: str, timeout_s: int) -> dict[str, Any] | None:
    response = _post(
        "/tnrs/match_names",
        {"names": [name], "do_approximate_matching": True},
        timeout_s=timeout_s,
    )
    results = response.get("results") or []
    if not results:
        return None
    matches = results[0].get("matches") or []
    if not matches:
        return None
    # Prefer score then non-approximate match.
    matches_sorted = sorted(
        matches,
        key=lambda m: (
            float(m.get("score", 0.0)),
            0 if m.get("is_approximate_match") else 1,
        ),
        reverse=True,
    )
    best = matches_sorted[0]
    taxon = best.get("taxon") or {}
    return {
        "ott_id": _to_int(taxon.get("ott_id")),
        "matched_name": best.get("matched_name"),
        "unique_name": taxon.get("unique_name"),
        "rank": taxon.get("rank"),
        "flags": taxon.get("flags") or [],
        "is_approximate_match": bool(best.get("is_approximate_match", False)),
        "score": best.get("score"),
    }


def _taxon_info(ott_id: int, timeout_s: int) -> dict[str, Any]:
    response = _post(
        "/taxonomy/taxon_info",
        {"ott_id": ott_id, "include_lineage": True},
        timeout_s=timeout_s,
    )
    lineage = response.get("lineage") or []
    lineage_ids = [_to_int(node.get("ott_id")) for node in lineage]
    lineage_ids = [x for x in lineage_ids if x is not None]
    return {
        "ott_id": _to_int(response.get("ott_id")) or ott_id,
        "name": response.get("name"),
        "unique_name": response.get("unique_name"),
        "rank": response.get("rank"),
        "flags": response.get("flags") or [],
        "lineage_ids": lineage_ids,
    }


def _build_cache(
    clades: list[dict[str, Any]],
    timeout_s: int,
    resolve: bool,
    validate: bool,
    subtree: bool,
) -> dict[str, Any]:
    now = dt.datetime.now(dt.timezone.utc).isoformat()
    cache: dict[str, Any] = {
        "generated_at": now,
        "source": "OpenTree of Life API v3",
        "clades": {},
        "warnings": [],
        "errors": [],
        "subtree": None,
    }

    # Resolve names and fetch lineage.
    for clade in clades:
        clade_id = clade.get("id")
        if not clade_id:
            continue
        entry: dict[str, Any] = {
            "id": clade_id,
            "label": clade.get("label"),
            "parent_id": clade.get("parent_id"),
            "requested_name": _normalize_name(clade),
            "checked_at": now,
            "opentree": None,
        }
        cache["clades"][clade_id] = entry

        if not resolve:
            continue
        if not entry["requested_name"]:
            cache["warnings"].append(f"{clade_id}: no candidate name for TNRS")
            continue

        resolved = _resolve_one_name(entry["requested_name"], timeout_s=timeout_s)
        if not resolved or not resolved.get("ott_id"):
            cache["warnings"].append(
                f"{clade_id}: unable to resolve name '{entry['requested_name']}'"
            )
            continue

        ott_id = int(resolved["ott_id"])
        taxon = _taxon_info(ott_id, timeout_s=timeout_s)
        entry["opentree"] = {
            "ott_id": ott_id,
            "matched_name": resolved.get("matched_name"),
            "unique_name": taxon.get("unique_name") or resolved.get("unique_name"),
            "rank": taxon.get("rank") or resolved.get("rank"),
            "flags": taxon.get("flags") or resolved.get("flags") or [],
            "lineage_ids": taxon.get("lineage_ids") or [],
            "is_approximate_match": resolved.get("is_approximate_match", False),
            "score": resolved.get("score"),
            "checked_at": now,
        }

    if validate:
        _validate_parentage(clades, cache)
    if subtree:
        _generate_subtree(cache, timeout_s=timeout_s)
    return cache


def _validate_parentage(clades: list[dict[str, Any]], cache: dict[str, Any]) -> None:
    by_id = {clade.get("id"): clade for clade in clades if clade.get("id")}
    for clade in clades:
        clade_id = clade.get("id")
        parent_id = clade.get("parent_id")
        if not clade_id or not parent_id:
            continue
        cache_child = cache["clades"].get(clade_id, {})
        cache_parent = cache["clades"].get(parent_id, {})
        child_meta = (cache_child or {}).get("opentree") or {}
        parent_meta = (cache_parent or {}).get("opentree") or {}
        child_ott = _to_int(child_meta.get("ott_id"))
        parent_ott = _to_int(parent_meta.get("ott_id"))
        if child_ott is None or parent_ott is None:
            cache["warnings"].append(
                f"{clade_id}: cannot validate parent '{parent_id}' (missing ott ids)"
            )
            continue
        lineage_ids = set(child_meta.get("lineage_ids") or [])
        if parent_ott in lineage_ids:
            continue
        # If both are resolved but lineage does not include declared parent, flag.
        cache["errors"].append(
            f"{clade_id}: parent_id={parent_id} (ott {parent_ott}) "
            f"not present in OpenTree lineage for child ott {child_ott}"
        )
        # Extra context for omitted intermediates is handled as OK by parent-in-lineage.

    # Informational warning for simplified tree gaps (no error).
    for clade in clades:
        clade_id = clade.get("id")
        if not clade_id:
            continue
        parent_id = clade.get("parent_id")
        if parent_id and parent_id not in by_id:
            cache["warnings"].append(
                f"{clade_id}: parent '{parent_id}' is not in curated clade set"
            )


def _generate_subtree(cache: dict[str, Any], timeout_s: int) -> None:
    ott_ids: list[int] = []
    for entry in cache.get("clades", {}).values():
        meta = (entry or {}).get("opentree") or {}
        ott_id = _to_int(meta.get("ott_id"))
        if ott_id is not None:
            ott_ids.append(ott_id)
    ott_ids = sorted(set(ott_ids))
    if len(ott_ids) < 2:
        cache["warnings"].append("subtree: need at least two resolved ott ids")
        return
    response = _post("/tree_of_life/induced_subtree", {"ott_ids": ott_ids}, timeout_s)
    cache["subtree"] = {
        "ott_id_count": len(ott_ids),
        "newick": response.get("newick"),
        "node_ids_not_in_tree": response.get("node_ids_not_in_tree") or [],
        "ott_ids_not_in_tree": response.get("ott_ids_not_in_tree") or [],
    }


def _write_report(cache: dict[str, Any], report_path: Path) -> None:
    report_path.parent.mkdir(parents=True, exist_ok=True)
    lines = [
        "# OpenTree Clade Validation Report",
        "",
        f"- Generated: {cache.get('generated_at', '-')}",
        f"- Resolved clades: {sum(1 for c in cache['clades'].values() if (c or {}).get('opentree'))}",
        f"- Warnings: {len(cache.get('warnings', []))}",
        f"- Errors: {len(cache.get('errors', []))}",
        "",
        "## Warnings",
        "",
    ]
    warnings = cache.get("warnings", [])
    if warnings:
        lines.extend([f"- {w}" for w in warnings])
    else:
        lines.append("- None")

    lines.extend(["", "## Errors", ""])
    errors = cache.get("errors", [])
    if errors:
        lines.extend([f"- {e}" for e in errors])
    else:
        lines.append("- None")

    subtree = cache.get("subtree")
    lines.extend(["", "## Induced Subtree", ""])
    if subtree:
        lines.append(f"- Included OTT IDs: {subtree.get('ott_id_count', 0)}")
        if subtree.get("ott_ids_not_in_tree"):
            lines.append(
                f"- OTT IDs not in tree: {subtree.get('ott_ids_not_in_tree')}"
            )
        lines.extend(["", "```newick", subtree.get("newick") or "", "```"])
    else:
        lines.append("- Not generated.")

    report_path.write_text("\n".join(lines) + "\n", encoding="utf-8")


def _merge_back_into_clades(
    clades: list[dict[str, Any]],
    cache: dict[str, Any],
    preserve_existing_ott: bool,
) -> list[dict[str, Any]]:
    updated: list[dict[str, Any]] = []
    for clade in clades:
        clade_id = clade.get("id")
        if not clade_id:
            updated.append(clade)
            continue
        cache_entry = cache.get("clades", {}).get(clade_id) or {}
        open_tree = cache_entry.get("opentree")
        if not open_tree:
            updated.append(clade)
            continue

        next_clade = dict(clade)
        if not preserve_existing_ott or _to_int(next_clade.get("ott_id")) is None:
            next_clade["ott_id"] = open_tree.get("ott_id")
        next_clade.setdefault("opentree_name", cache_entry.get("requested_name"))
        next_clade["opentree"] = {
            "ott_id": open_tree.get("ott_id"),
            "matched_name": open_tree.get("matched_name"),
            "unique_name": open_tree.get("unique_name"),
            "rank": open_tree.get("rank"),
            "flags": open_tree.get("flags") or [],
            "lineage_ids": open_tree.get("lineage_ids") or [],
            "checked_at": open_tree.get("checked_at"),
        }
        updated.append(next_clade)
    return updated


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Resolve and validate curated clades against OpenTree.",
    )
    parser.add_argument(
        "--mode",
        choices=["resolve", "validate", "subtree", "report", "all"],
        default="all",
        help="Which operation to run.",
    )
    parser.add_argument("--clades", default=str(DEFAULT_CLADES), help="clades YAML path")
    parser.add_argument("--cache", default=str(DEFAULT_CACHE), help="cache YAML path")
    parser.add_argument("--report", default=str(DEFAULT_REPORT), help="report MD path")
    parser.add_argument(
        "--timeout",
        type=int,
        default=20,
        help="HTTP timeout seconds per OpenTree call.",
    )
    parser.add_argument(
        "--write-clades",
        action="store_true",
        help="Write OpenTree metadata back into clades.yaml.",
    )
    parser.add_argument(
        "--preserve-existing-ott",
        action="store_true",
        help="When writing clades, keep pre-existing top-level ott_id values.",
    )
    parser.add_argument(
        "--ids",
        help="Comma-separated clade ids to process (for scoped runs).",
    )
    args = parser.parse_args()

    clades_path = Path(args.clades)
    cache_path = Path(args.cache)
    report_path = Path(args.report)
    if not clades_path.exists():
        print(f"ERROR: missing clades file: {clades_path}", file=sys.stderr)
        return 2

    clades_doc = _read_yaml(clades_path)
    if not isinstance(clades_doc, list):
        print(f"ERROR: expected YAML list in {clades_path}", file=sys.stderr)
        return 2
    clades = [entry for entry in clades_doc if isinstance(entry, dict)]
    if args.ids:
        target_ids = {x.strip() for x in args.ids.split(",") if x.strip()}
        clades = [c for c in clades if c.get("id") in target_ids]
        if not clades:
            print("ERROR: no clades matched --ids filter", file=sys.stderr)
            return 2

    mode = args.mode
    resolve = mode in {"resolve", "all", "validate", "subtree", "report"}
    validate = mode in {"validate", "all", "report"}
    subtree = mode in {"subtree", "all", "report"}

    cache = _build_cache(
        clades=clades,
        timeout_s=args.timeout,
        resolve=resolve,
        validate=validate,
        subtree=subtree,
    )
    _write_yaml(cache_path, cache)
    _write_report(cache, report_path)

    if args.write_clades:
        merged = _merge_back_into_clades(
            clades=clades,
            cache=cache,
            preserve_existing_ott=args.preserve_existing_ott,
        )
        _write_yaml(clades_path, merged)

    print(f"Wrote cache: {cache_path}")
    print(f"Wrote report: {report_path}")
    if args.write_clades:
        print(f"Updated clades: {clades_path}")
    if cache.get("errors"):
        print(f"Validation errors: {len(cache['errors'])}")
        return 1
    print(f"Warnings: {len(cache.get('warnings', []))}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
