#!/usr/bin/env python3
"""Rename clade `label` -> `common_label` and add `scientific_label`.

Preserves file ordering/comments by editing line-by-line.
"""

from __future__ import annotations

import argparse
import re
from pathlib import Path


LABEL_RE = re.compile(r"^(?P<indent>\s*)label:\s*(?P<value>.+?)\s*$")
COMMON_RE = re.compile(r"^(?P<indent>\s*)common_label:\s*(?P<value>.+?)\s*$")
SCIENTIFIC_RE = re.compile(r"^(?P<indent>\s*)scientific_label:\s*(?P<value>.+?)\s*$")
ID_RE = re.compile(r"^\s*-\s+id:\s+.+$")
KEY_RE = re.compile(r"^(?P<indent>\s*)(?P<key>[a-zA-Z0-9_]+):\s*.*$")


def _unquote(value: str) -> str:
    value = value.strip()
    if len(value) >= 2 and (
        (value[0] == "'" and value[-1] == "'")
        or (value[0] == '"' and value[-1] == '"')
    ):
        return value[1:-1]
    return value


def _quote_like(value: str, template: str) -> str:
    template = template.strip()
    if len(template) >= 2 and template[0] == "'" and template[-1] == "'":
        return f"'{value}'"
    if len(template) >= 2 and template[0] == '"' and template[-1] == '"':
        return f'"{value}"'
    return value


def _derive_names(raw_label_value: str) -> tuple[str, str]:
    label = _unquote(raw_label_value).strip()
    # Scientific (common) pattern
    match = re.match(r"^(.*?)\s*\((.*?)\)\s*$", label)
    if match:
        scientific = match.group(1).strip() or label
        common = match.group(2).strip() or label
        return common, scientific
    return label, label


def migrate(path: Path, dry_run: bool) -> None:
    lines = path.read_text(encoding="utf-8").splitlines()
    out: list[str] = []

    i = 0
    while i < len(lines):
        line = lines[i]
        if not ID_RE.match(line):
            out.append(line)
            i += 1
            continue

        # Collect one clade block.
        block = [line]
        i += 1
        while i < len(lines):
            next_line = lines[i]
            if ID_RE.match(next_line):
                break
            block.append(next_line)
            i += 1

        common_idx = None
        label_idx = None
        sci_idx = None
        label_value = None
        common_value = None

        for idx, candidate in enumerate(block):
            m_common = COMMON_RE.match(candidate)
            if m_common:
                common_idx = idx
                common_value = m_common.group("value")
                continue
            m_label = LABEL_RE.match(candidate)
            if m_label:
                label_idx = idx
                label_value = m_label.group("value")
                continue
            if SCIENTIFIC_RE.match(candidate):
                sci_idx = idx

        source_value = common_value or label_value
        if source_value is None:
            out.extend(block)
            continue

        derived_common, derived_scientific = _derive_names(source_value)

        # Replace legacy label key with common_label.
        if label_idx is not None:
            m = LABEL_RE.match(block[label_idx])
            assert m is not None
            indent = m.group("indent")
            rendered_common = _quote_like(derived_common, source_value)
            block[label_idx] = f"{indent}common_label: {rendered_common}"
            common_idx = label_idx
        elif common_idx is not None:
            m = COMMON_RE.match(block[common_idx])
            assert m is not None
            indent = m.group("indent")
            rendered_common = _quote_like(derived_common, source_value)
            block[common_idx] = f"{indent}common_label: {rendered_common}"

        # Insert or replace scientific_label near common_label.
        if common_idx is None:
            out.extend(block)
            continue
        common_line = block[common_idx]
        m_common_line = COMMON_RE.match(common_line)
        assert m_common_line is not None
        indent = m_common_line.group("indent")
        rendered_scientific = _quote_like(derived_scientific, source_value)
        scientific_line = f"{indent}scientific_label: {rendered_scientific}"

        if sci_idx is not None:
            block[sci_idx] = scientific_line
        else:
            block.insert(common_idx + 1, scientific_line)

        out.extend(block)

    content = "\n".join(out) + "\n"
    if dry_run:
        print(content)
    else:
        path.write_text(content, encoding="utf-8")


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Rename clade label -> common_label and add scientific_label."
    )
    parser.add_argument("--yaml", default="data/clades.yaml", help="Clades YAML path.")
    parser.add_argument("--dry-run", action="store_true", help="Print output only.")
    args = parser.parse_args()

    migrate(Path(args.yaml), dry_run=args.dry_run)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
