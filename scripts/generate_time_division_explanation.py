#!/usr/bin/env python3
import argparse
import os
import re
import sys
import textwrap
from pathlib import Path

try:
    from openai import OpenAI
except ModuleNotFoundError:  # pragma: no cover - script guard
    OpenAI = None

def _call_openai(api_key, model, name, rank):
    if OpenAI is None:
        raise RuntimeError(
            "openai package is not installed. Install it with `pip install openai`.",
        )
    prompt = (
        f"Write a ~200-word explanation of the geologic {rank} \"{name}\" for a "
        "postdoctoral university student in geology or palaeontology. "
        "Explain the name's origin or meaning, its timeframe, key stratigraphic "
        "context, and why it matters. Use 2–3 short paragraphs, precise academic "
        "language (not oversimplified), and avoid bullet points. "
        "Target 200 words (180–220 acceptable)."
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
    name_pattern = re.compile(r"^(?P<indent>\s*)- name:\s*(?P<name>.+?)\s*$")
    nodes = []
    stack = []

    for index, line in enumerate(content):
        match = name_pattern.match(line)
        if not match:
            continue
        name = match.group("name")
        base_indent = match.group("indent")
        entry_indent = base_indent + "  "

        while stack and stack[-1]["indent"] >= len(base_indent):
            stack.pop()

        path = [entry["name"] for entry in stack] + [name]

        node_end = len(content)
        for i in range(index + 1, len(content)):
            candidate = content[i]
            if not candidate.strip():
                continue
            if candidate.startswith(base_indent + "- name:"):
                node_end = i
                break
            if len(candidate) - len(candidate.lstrip()) < len(base_indent):
                node_end = i
                break

        rank = None
        has_explanation = False
        for i in range(index + 1, node_end):
            candidate = content[i]
            if candidate.startswith(f"{entry_indent}rank:"):
                rank = candidate.split(":", 1)[1].strip()
            if candidate.startswith(f"{entry_indent}explanation:"):
                has_explanation = True

        if rank:
            nodes.append(
                {
                    "name": name,
                    "rank": rank,
                    "path": path,
                    "has_explanation": has_explanation,
                    "indent": base_indent,
                    "index": index,
                }
            )

        stack.append({"name": name, "indent": len(base_indent)})

    return nodes


def _collect_nodes(path):
    content = path.read_text(encoding="utf-8").splitlines()
    return _scan_nodes(content)


def _find_node_by_path(content, target_path, target_rank):
    for node in _scan_nodes(content):
        if node["path"] == target_path and node["rank"] == target_rank:
            return node
    raise RuntimeError(
        f'Node not found for path "{"/".join(target_path)}" ({target_rank}).'
    )


def _update_yaml(path, target_path, target_rank, explanation):
    content = path.read_text(encoding="utf-8").splitlines()
    node = _find_node_by_path(content, target_path, target_rank)
    match_index = node["index"]
    match_indent = node["indent"]

    entry_indent = match_indent + "  "
    explanation_line = f"{entry_indent}explanation:"

    node_end = len(content)
    for i in range(match_index + 1, len(content)):
        line = content[i]
        if not line.strip():
            continue
        if line.startswith(match_indent + "- name:") and i > match_index:
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


def main():
    parser = argparse.ArgumentParser(
        description="Generate a 200-word time division explanation and store it in time_divisions.yaml.",
    )
    parser.add_argument(
        "--test",
        action="store_true",
        help="Generate two sample explanations (Hadean eon, Cambrian period) without writing YAML.",
    )
    parser.add_argument("--name", help="Division name to update.")
    parser.add_argument(
        "--all",
        action="store_true",
        help="Generate explanations for all divisions in time_divisions.yaml.",
    )
    parser.add_argument(
        "--overwrite",
        action="store_true",
        help="Replace existing explanations (use with --all or --name).",
    )
    parser.add_argument(
        "--limit",
        type=int,
        help="Maximum number of divisions to process when using --all.",
    )
    parser.add_argument(
        "--offset",
        type=int,
        default=0,
        help="Number of divisions to skip when using --all.",
    )
    parser.add_argument(
        "--rank",
        default="period",
        help="Division rank (eon/era/period/epoch/age). Used for the prompt.",
    )
    parser.add_argument(
        "--yaml",
        default="data/time_divisions.yaml",
        help="Path to time_divisions.yaml.",
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
        samples = [("Hadean", "eon"), ("Cambrian", "period")]
        for name, rank in samples:
            explanation = _call_openai(api_key, args.model, name, rank)
            print(f"--- {name} ({rank}) ---")
            print(explanation)
            print("")
        return

    if args.all and args.name:
        parser.error("Use --all or --name, not both.")
    if not args.all and not args.name:
        parser.error("--name or --all is required unless --test is provided.")

    api_key = os.getenv("OPENAI_API_KEY")
    if not api_key:
        print("Missing OPENAI_API_KEY environment variable.", file=sys.stderr)
        sys.exit(1)

    yaml_path = Path(args.yaml).resolve()
    if args.all:
        nodes = _collect_nodes(yaml_path)
        if args.offset:
            nodes = nodes[args.offset :]
        if args.limit is not None:
            nodes = nodes[: args.limit]
        for node in nodes:
            if node["has_explanation"] and not args.overwrite:
                continue
            explanation = _call_openai(
                api_key,
                args.model,
                node["name"],
                node["rank"],
            )
            if args.dry_run:
                print(f"--- {node['name']} ({node['rank']}) ---")
                print(explanation)
                print("")
                continue
            _update_yaml(yaml_path, node["path"], node["rank"], explanation)
            print(
                f'Updated {yaml_path} with explanation for "{"/".join(node["path"])}".'
            )
        return

    explanation = _call_openai(api_key, args.model, args.name, args.rank)
    if args.dry_run:
        print(explanation)
        return

    nodes = _collect_nodes(yaml_path)
    matches = [
        node for node in nodes if node["name"] == args.name and node["rank"] == args.rank
    ]
    if not matches:
        raise RuntimeError(
            f'No division named "{args.name}" with rank "{args.rank}" found.'
        )
    if len(matches) > 1:
        paths = "\n".join(f'  - {"/".join(node["path"])}' for node in matches)
        raise RuntimeError(
            f'Ambiguous division name "{args.name}" with rank "{args.rank}".\n'
            f"Matches:\n{paths}\n"
            "Please disambiguate by running with --all and --limit/--offset."
        )
    _update_yaml(yaml_path, matches[0]["path"], args.rank, explanation)
    print(
        f'Updated {yaml_path} with explanation for "{"/".join(matches[0]["path"])}".'
    )


if __name__ == "__main__":
    main()
