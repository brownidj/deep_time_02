#!/usr/bin/env python3
import argparse
import json
import re
from pathlib import Path
import yaml

RANKS = ["eon", "era", "period", "epoch", "age"]
NEXT = {RANKS[i]: (RANKS[i + 1] if i + 1 < len(RANKS) else None) for i in range(len(RANKS))}


class Node:
    def __init__(self, name, rank):
        self.name = name
        self.rank = rank
        self.children = []
        self.parent = None
        self.height = None
        self.y_top = None
        self.y_bottom = None
        self.empty_subblock = None


def text_height(name, rank, line_height, padding, char_width, vertical):
    # Approximate single-line label size with padding.
    if vertical:
        # Vertical label height depends on text width.
        return (len(name) * char_width) + (padding * 2)
    return line_height + (padding * 2)


def build_tree(yaml_path):
    data = yaml.safe_load(Path(yaml_path).read_text())

    def build(node_dict):
        name = node_dict.get("name")
        rank = node_dict.get("rank")
        if rank == "stage":
            # Normalize to 'age' for algorithm rank ladder.
            rank = "age"
        n = Node(name, rank)
        for ch in node_dict.get("children", []) or []:
            cn = build(ch)
            cn.parent = n
            n.children.append(cn)
        return n

    return [build(e) for e in data.get("eons", [])]


def compute_height(node, min_age_height, line_height, padding, char_width, vertical_ranks):
    if node.rank == "age":
        node.height = min_age_height
        return node.height

    next_rank = NEXT.get(node.rank)
    children_next = [c for c in node.children if c.rank == next_rank]

    if not children_next:
        node.height = text_height(
            node.name,
            node.rank,
            line_height,
            padding,
            char_width,
            vertical=(node.rank in vertical_ranks),
        )
        node.empty_subblock = {"rank": next_rank, "height": node.height}
        return node.height

    total = 0.0
    for c in children_next:
        total += compute_height(c, min_age_height, line_height, padding, char_width, vertical_ranks)
    node.height = total
    return node.height


def assign_y(node, y_top):
    node.y_top = y_top
    node.y_bottom = y_top + node.height

    next_rank = NEXT.get(node.rank)
    children_next = [c for c in node.children if c.rank == next_rank]

    if not children_next:
        node.empty_subblock = {"rank": next_rank, "y_top": y_top, "height": node.height}
        return

    cur = y_top
    for c in children_next:
        assign_y(c, cur)
        cur += c.height


def parse_md_tree(md_path):
    lines = Path(md_path).read_text().splitlines()
    try:
        start = next(i for i, l in enumerate(lines) if l.strip().startswith("```"))
        end = next(i for i in range(start + 1, len(lines)) if lines[i].strip().startswith("```"))
    except StopIteration:
        raise SystemExit("time_divisions_tree.md missing code fence")

    content = lines[start + 1 : end]
    header_idx = next(i for i, l in enumerate(content) if l.strip().startswith("Name"))
    content = content[header_idx + 1 :]

    pattern = re.compile(r"^(?P<indent>(?:│   |    )*)(?:├── |└── )?(?P<name>[^\s].*?)\s{2,}.*$")
    paths = []
    stack = []

    for line in content:
        if not line.strip():
            continue
        m = pattern.match(line)
        if not m:
            parts = re.split(r"\s{2,}", line.strip())
            if not parts:
                continue
            name = parts[0]
            depth = 0
        else:
            indent = m.group("indent") or ""
            depth = len(indent) // 4
            name = m.group("name").strip()

        while stack and stack[-1][0] >= depth:
            stack.pop()
        path = [p[1] for p in stack] + [name]
        paths.append(tuple(path))
        stack.append((depth, name))
    return paths


def collect_paths(roots):
    paths = []

    def walk(n, path):
        cur = path + [n.name]
        paths.append(tuple(cur))
        for c in n.children:
            walk(c, cur)

    for r in roots:
        walk(r, [])
    return paths


def collect_nodes_by_rank(roots, rank):
    matches = []

    def walk(node):
        if node.rank == rank:
            matches.append(node)
        for child in node.children:
            walk(child)

    for root in roots:
        walk(root)
    return matches


def node_path(node):
    parts = []
    cur = node
    while cur is not None:
        parts.append(cur.name)
        cur = cur.parent
    return list(reversed(parts))


def build_palaeo_ecology_prompt(roots, output_path):
    divisions = []
    for node in collect_nodes_by_rank(roots, "age"):
        divisions.append(
            {
                "name": node.name,
                "rank": "stage",
                "path": node_path(node),
            }
        )

    payload = {
        "task": "Generate paleo-ecology data for the geological divisions listed below.",
        "output_file": output_path,
        "requirements": [
            "Return YAML only, with root key paleo_ecology.",
            "Use current peer-reviewed synthesis values where possible.",
            "Return approximate values suitable for an educational deep-time timeline, not high-precision climate modelling.",
            "Use null where evidence is too uncertain rather than inventing precision.",
            "Express all numeric environmental fields as signed deltas from the present global baseline.",
            "Use Ma-aware stage context: values should represent average conditions across the Stage/Age, not a single boundary value.",
            "Use avg_co2_ppm for atmospheric CO2 concentration in ppm.",
            "Include a concise confidence value: high, moderate, low, or very_low.",
            "Include a short note explaining major uncertainty or important palaeo-ecological context.",
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
            "sources": "Short list of source names or DOI-style references used.",
        },
        "yaml_shape": {
            "paleo_ecology": [
                {
                    "rank": "stage",
                    "name": "Example Stage",
                    "path": ["Eon", "Era", "Period", "Epoch", "Stage"],
                    "avg_temp_delta_c": "+0.0",
                    "avg_humidity_delta_percent": "+0.0",
                    "avg_co2_ppm": 400,
                    "sea_level_delta_m": "+0.0",
                    "icehouse_greenhouse_state": "uncertain",
                    "dominant_ecology": "brief ecological summary",
                    "confidence": "low",
                    "note": "brief note",
                    "sources": ["source 1", "source 2"],
                }
            ]
        },
        "divisions": divisions,
    }

    return (
        "# Palaeo-ecology data generation prompt\n\n"
        "Use the following JSON request to generate the contents of `"
        + output_path
        + "`. Return only valid YAML matching the requested `yaml_shape`.\n\n"
        "```json\n"
        + json.dumps(payload, indent=2, ensure_ascii=False)
        + "\n```\n"
    )


def build_palaeo_ecology_template(roots):
    rows = []
    for node in collect_nodes_by_rank(roots, "age"):
        rows.append(
            {
                "rank": "stage",
                "name": node.name,
                "path": node_path(node),
                "avg_temp_delta_c": None,
                "avg_humidity_delta_percent": None,
                "avg_co2_ppm": None,
                "sea_level_delta_m": None,
                "icehouse_greenhouse_state": "uncertain",
                "dominant_ecology": None,
                "confidence": "very_low",
                "note": "Template row; values need source-backed palaeo-ecology estimates.",
                "sources": [],
            }
        )
    return {"paleo_ecology": rows}


def print_tree(roots, show_heights, show_empty):
    def recur(node, prefix, is_last):
        connector = "└── " if is_last else "├── "
        label = node.name
        extra = []
        if show_heights:
            extra.append("h=" + format(node.height, ".1f"))
        if show_empty and node.empty_subblock:
            extra.append("empty")
        if extra:
            label = label + " (" + ", ".join(extra) + ")"
        print(prefix + connector + label)
        new_prefix = prefix + ("    " if is_last else "│   ")
        children = node.children
        for i, child in enumerate(children):
            recur(child, new_prefix, i == len(children) - 1)

    for i, root in enumerate(roots):
        label = root.name
        extra = []
        if show_heights:
            extra.append("h=" + format(root.height, ".1f"))
        if show_empty and root.empty_subblock:
            extra.append("empty")
        if extra:
            label = label + " (" + ", ".join(extra) + ")"
        print(label)
        children = root.children
        for j, child in enumerate(children):
            recur(child, "", j == len(children) - 1)


def main():
    parser = argparse.ArgumentParser(description="Print time divisions tree with computed heights.")
    parser.add_argument("--yaml", default="data/time_divisions.yaml")
    parser.add_argument("--md", default="docs/time_divisions_tree.md")
    parser.add_argument("--min-age-height", type=float, default=16.0)
    parser.add_argument("--line-height", type=float, default=16.0)
    parser.add_argument("--padding", type=float, default=4.0)
    parser.add_argument("--char-width", type=float, default=7.2)
    parser.add_argument("--check-md", action="store_true")
    parser.add_argument("--show-heights", action="store_true")
    parser.add_argument("--show-empty", action="store_true")
    parser.add_argument(
        "--palaeo-ecology-prompt",
        action="store_true",
        help="Write a Markdown ChatGPT prompt for generating stage-level palaeo-ecology YAML data.",
    )
    parser.add_argument(
        "--palaeo-ecology-prompt-output",
        default="docs/palaeo_ecology_prompt.md",
        help="Output path for the generated Markdown palaeo-ecology prompt.",
    )
    parser.add_argument(
        "--write-palaeo-ecology-template",
        action="store_true",
        help="Write a blank stage-level palaeo-ecology YAML template.",
    )
    parser.add_argument(
        "--palaeo-ecology-output",
        default="data/paleo_ecology.yaml",
        help="Output path for the generated palaeo-ecology YAML file or prompt target.",
    )
    args = parser.parse_args()

    roots = build_tree(args.yaml)
    vertical_ranks = {"eon", "era", "period"}
    for r in roots:
        compute_height(
            r,
            args.min_age_height,
            args.line_height,
            args.padding,
            args.char_width,
            vertical_ranks,
        )

    cur = 0.0
    for r in roots:
        assign_y(r, cur)
        cur += r.height

    if args.palaeo_ecology_prompt:
        prompt_path = Path(args.palaeo_ecology_prompt_output)
        prompt_path.parent.mkdir(parents=True, exist_ok=True)
        prompt_text = build_palaeo_ecology_prompt(roots, args.palaeo_ecology_output)
        prompt_path.write_text(prompt_text, encoding="utf-8")
        print("Wrote " + str(prompt_path))
        return

    if args.write_palaeo_ecology_template:
        output_path = Path(args.palaeo_ecology_output)
        output_path.parent.mkdir(parents=True, exist_ok=True)
        template = build_palaeo_ecology_template(roots)
        output_path.write_text(
            yaml.safe_dump(template, sort_keys=False, allow_unicode=True),
            encoding="utf-8",
        )
        print("Wrote " + str(output_path))
        return

    if args.check_md:
        md_paths = set(parse_md_tree(args.md))
        yaml_paths = set(collect_paths(roots))
        only_yaml = sorted(yaml_paths - md_paths)
        only_md = sorted(md_paths - yaml_paths)
        print("Structure check:")
        print("  yaml nodes: " + str(len(yaml_paths)))
        print("  md nodes:   " + str(len(md_paths)))
        print("  only in yaml: " + str(len(only_yaml)))
        print("  only in md:   " + str(len(only_md)))
        if only_yaml[:5]:
            print("  sample only in yaml:")
            for p in only_yaml[:5]:
                print("    -", " > ".join(p))
        if only_md[:5]:
            print("  sample only in md:")
            for p in only_md[:5]:
                print("    -", " > ".join(p))
        print("")

    print_tree(roots, show_heights=args.show_heights, show_empty=args.show_empty)


if __name__ == "__main__":
    main()
