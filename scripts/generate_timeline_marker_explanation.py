#!/usr/bin/env python3
import argparse
import os
import re
import sys
import textwrap
from pathlib import Path

try:
    import yaml
except ModuleNotFoundError:  # pragma: no cover - script guard
    yaml = None

try:
    from openai import OpenAI
except ModuleNotFoundError:  # pragma: no cover - script guard
    OpenAI = None


SECTION_PATTERN = re.compile(r"^(?P<indent>\s*)(?P<section>events|extinctions):\s*$")
LABEL_PATTERN = re.compile(r"^(?P<indent>\s*)- label:\s*(?P<label>.+?)\s*$")


def _call_openai(api_key, model, prompt):
    if OpenAI is None:
        raise RuntimeError(
            "openai package is not installed. Install it with `pip install openai`.",
        )
    client = OpenAI(api_key=api_key)
    response = client.responses.create(
        model=model,
        input=prompt,
    )
    text = getattr(response, "output_text", None)
    if not text:
        raise RuntimeError("No text output found in API response.")
    return text.strip()


def _wrap_explanation(explanation, indent):
    wrapped = textwrap.fill(explanation, width=80)
    lines = wrapped.splitlines()
    return "\n".join(f"{indent}{line}" for line in lines)


def _scan_nodes(content):
    nodes = []
    current_section = None
    current_section_indent = 0

    for index, line in enumerate(content):
        section_match = SECTION_PATTERN.match(line)
        if section_match and len(section_match.group("indent")) == 0:
            current_section = section_match.group("section")
            current_section_indent = len(section_match.group("indent"))
            continue

        label_match = LABEL_PATTERN.match(line)
        if not label_match or current_section is None:
            continue

        base_indent = label_match.group("indent")
        if len(base_indent) <= current_section_indent:
            continue

        label = label_match.group("label")
        entry_indent = base_indent + "  "

        node_end = len(content)
        for i in range(index + 1, len(content)):
            candidate = content[i]
            if not candidate.strip():
                continue
            if candidate.startswith(base_indent + "- label:"):
                node_end = i
                break
            if len(candidate) - len(candidate.lstrip()) < len(base_indent):
                node_end = i
                break

        has_explanation = False
        for i in range(index + 1, node_end):
            candidate = content[i]
            if candidate.startswith(f"{entry_indent}explanation:"):
                has_explanation = True
                break

        nodes.append(
            {
                "section": current_section,
                "label": label,
                "has_explanation": has_explanation,
                "indent": base_indent,
                "index": index,
            }
        )

    return nodes


def _collect_nodes(path):
    content = path.read_text(encoding="utf-8").splitlines()
    return _scan_nodes(content)


def _find_node_by_section_label(content, section, label):
    for node in _scan_nodes(content):
        if node["section"] == section and node["label"] == label:
            return node
    raise RuntimeError(f'Node not found for "{section}/{label}".')


def _update_yaml(path, section, label, explanation):
    content = path.read_text(encoding="utf-8").splitlines()
    node = _find_node_by_section_label(content, section, label)
    match_index = node["index"]
    match_indent = node["indent"]

    entry_indent = match_indent + "  "
    explanation_line = f"{entry_indent}explanation:"

    node_end = len(content)
    for i in range(match_index + 1, len(content)):
        line = content[i]
        if not line.strip():
            continue
        if line.startswith(match_indent + "- label:") and i > match_index:
            node_end = i
            break
        if len(line) - len(line.lstrip()) < len(match_indent):
            node_end = i
            break

    remove_start = None
    remove_end = None
    for i in range(match_index + 1, node_end):
        line = content[i]
        if line.startswith(explanation_line):
            remove_start = i
            remove_end = i + 1
            while remove_end < node_end:
                next_line = content[remove_end]
                if next_line.strip() == "":
                    remove_end += 1
                    continue
                if len(next_line) - len(next_line.lstrip()) <= len(entry_indent):
                    break
                remove_end += 1
            break

    if remove_start is not None:
        del content[remove_start:remove_end]
        insert_at = remove_start
    else:
        insert_at = match_index + 1

    block_header = f"{entry_indent}explanation: |"
    block_body = _wrap_explanation(explanation, entry_indent + "  ").splitlines()
    insertion = [block_header] + block_body
    content[insert_at:insert_at] = insertion

    path.write_text("\n".join(content) + "\n", encoding="utf-8")


def _build_prompt(label, section, item):
    lines = [
        f'Write a ~120-word explanation of the geologic timeline marker "{label}".',
        "Use 2 short paragraphs, precise academic language (not oversimplified), and no bullet points.",
        "Target 120 words (100–140 acceptable).",
    ]

    marker_type = item.get("type")
    if marker_type == "bar":
        start = item.get("start_ma")
        end = item.get("end_ma")
        if start is not None and end is not None:
            lines.append(
                f"It spans from {start} to {end} million years ago (Ma)."
            )
    elif marker_type == "point":
        at = item.get("at_ma")
        if at is not None:
            lines.append(f"It occurs at approximately {at} Ma.")

    if section == "extinctions":
        anchor = item.get("anchor", {})
        anchor_type = anchor.get("type")
        if anchor_type in ("period", "stage"):
            anchor_label = anchor.get("label")
            if anchor_label:
                lines.append(
                    f"It is anchored to the {anchor_label} {anchor_type} boundary."
                )
        elif anchor_type == "ma":
            anchor_ma = anchor.get("ma")
            if anchor_ma is not None:
                lines.append(f"It is anchored at about {anchor_ma} Ma.")
        if item.get("is_major") is True:
            lines.append("This is a major extinction event.")
        elif item.get("is_major") is False:
            lines.append("This is a minor extinction pulse.")

    return " ".join(lines)


def _load_marker_data(yaml_path):
    if yaml is None:
        raise RuntimeError(
            "pyyaml is not installed. Install it with `pip install pyyaml`.",
        )
    data = yaml.safe_load(yaml_path.read_text(encoding="utf-8"))
    sections = {}
    for section in ("events", "extinctions"):
        items = data.get(section, [])
        section_map = {}
        for item in items:
            label = item.get("label")
            if not label:
                continue
            section_map.setdefault(label, []).append(item)
        sections[section] = section_map
    return sections


def main():
    parser = argparse.ArgumentParser(
        description=(
            "Generate explanations for timeline markers and store them in "
            "timeline_markers.yaml."
        ),
    )
    parser.add_argument(
        "--test",
        action="store_true",
        help="Generate sample explanations without writing YAML.",
    )
    parser.add_argument("--label", help="Marker label to update.")
    parser.add_argument(
        "--section",
        choices=["events", "extinctions"],
        help="Marker section (events/extinctions) for disambiguation.",
    )
    parser.add_argument(
        "--all",
        action="store_true",
        help="Generate explanations for all markers in timeline_markers.yaml.",
    )
    parser.add_argument(
        "--overwrite",
        action="store_true",
        help="Replace existing explanations (use with --all or --label).",
    )
    parser.add_argument(
        "--limit",
        type=int,
        help="Maximum number of markers to process when using --all.",
    )
    parser.add_argument(
        "--offset",
        type=int,
        default=0,
        help="Number of markers to skip when using --all.",
    )
    parser.add_argument(
        "--yaml",
        default="data/timeline_markers.yaml",
        help="Path to timeline_markers.yaml.",
    )
    parser.add_argument(
        "--model",
        default="gpt-4.1-mini",
        help="OpenAI model to use.",
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Print the explanation without updating YAML.",
    )
    args = parser.parse_args()

    if args.test:
        api_key = os.getenv("OPENAI_API_KEY")
        if not api_key:
            print("Missing OPENAI_API_KEY environment variable.", file=sys.stderr)
            sys.exit(1)
        yaml_path = Path(args.yaml).resolve()
        markers = _load_marker_data(yaml_path)
        samples = [
            ("events", "Cambrian explosion"),
            ("extinctions", "End-Permian"),
        ]
        for section, label in samples:
            items = markers.get(section, {}).get(label, [])
            if not items:
                raise RuntimeError(f'Missing sample "{section}/{label}".')
            prompt = _build_prompt(label, section, items[0])
            explanation = _call_openai(api_key, args.model, prompt)
            print(f"--- {section}/{label} ---")
            print(explanation)
            print("")
        return

    if args.all and args.label:
        parser.error("Use --all or --label, not both.")
    if not args.all and not args.label:
        parser.error("--label or --all is required unless --test is provided.")

    api_key = os.getenv("OPENAI_API_KEY")
    if not api_key:
        print("Missing OPENAI_API_KEY environment variable.", file=sys.stderr)
        sys.exit(1)

    yaml_path = Path(args.yaml).resolve()
    markers = _load_marker_data(yaml_path)

    if args.all:
        nodes = _collect_nodes(yaml_path)
        if args.offset:
            nodes = nodes[args.offset :]
        if args.limit is not None:
            nodes = nodes[: args.limit]
        for node in nodes:
            if node["has_explanation"] and not args.overwrite:
                continue
            items = markers.get(node["section"], {}).get(node["label"], [])
            if not items:
                raise RuntimeError(
                    f'Marker not found for "{node["section"]}/{node["label"]}".'
                )
            if len(items) > 1:
                raise RuntimeError(
                    f'Ambiguous label "{node["label"]}" in section "{node["section"]}".'
                )
            prompt = _build_prompt(node["label"], node["section"], items[0])
            explanation = _call_openai(api_key, args.model, prompt)
            if args.dry_run:
                print(f'--- {node["section"]}/{node["label"]} ---')
                print(explanation)
                print("")
                continue
            _update_yaml(yaml_path, node["section"], node["label"], explanation)
            print(
                f'Updated {yaml_path} with explanation for "{node["section"]}/{node["label"]}".'
            )
        return

    matches = [
        node
        for node in _collect_nodes(yaml_path)
        if node["label"] == args.label
        and (args.section is None or node["section"] == args.section)
    ]
    if not matches:
        raise RuntimeError(
            f'No marker labeled "{args.label}"'
            + (f' in section "{args.section}".' if args.section else ".")
        )
    if len(matches) > 1:
        options = "\n".join(
            f'  - {node["section"]}/{node["label"]}' for node in matches
        )
        raise RuntimeError(
            f'Ambiguous marker label "{args.label}".\n'
            f"Matches:\n{options}\n"
            "Please disambiguate with --section or use --all."
        )

    node = matches[0]
    items = markers.get(node["section"], {}).get(node["label"], [])
    if not items:
        raise RuntimeError(
            f'Marker not found for "{node["section"]}/{node["label"]}".'
        )
    if len(items) > 1:
        raise RuntimeError(
            f'Ambiguous label "{node["label"]}" in section "{node["section"]}".'
        )
    prompt = _build_prompt(node["label"], node["section"], items[0])
    explanation = _call_openai(api_key, args.model, prompt)
    if args.dry_run:
        print(explanation)
        return

    _update_yaml(yaml_path, node["section"], node["label"], explanation)
    print(
        f'Updated {yaml_path} with explanation for "{node["section"]}/{node["label"]}".'
    )


if __name__ == "__main__":
    main()
