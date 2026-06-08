#!/usr/bin/env python3
"""Update clade date candidates in data/ai_date_candidates.yaml using OpenAI.

This script traverses the candidate YAML, asks OpenAI with web search enabled to
propose source-backed date resolutions, and writes the results back in-place.
It preserves the workflow state by keeping review.status as "pending".
"""

from __future__ import annotations

import argparse
import json
import os
import sys
import time
from copy import deepcopy
from pathlib import Path
from typing import Any
from urllib.parse import urlparse

try:
    import yaml
except ImportError:
    print("Missing dependency: PyYAML")
    print("Install it with:")
    print("  python3 -m pip install PyYAML")
    sys.exit(1)

try:
    from openai import OpenAI
except ImportError:
    print("Missing dependency: openai")
    print("Install it with:")
    print("  python3 -m pip install openai")
    sys.exit(1)


PROJECT_ROOT = Path(__file__).resolve().parents[1]
CANDIDATES_PATH = PROJECT_ROOT / "data" / "ai_date_candidates.yaml"
DEFAULT_MODEL = "gpt-5"
DEFAULT_REVIEW_STATUS = "pending"
DEFAULT_BATCH_LIMIT = 2
REQUIRED_PROPOSAL_KEYS = (
    "date_basis",
    "date_confidence",
    "date_notes",
    "date_resolution_method",
    "date_sources",
    "divergence_ma",
    "end_ma",
    "start_ma",
)
ALLOWED_DATE_BASIS = {
    "fossil_first_appearance",
    "fossil_range",
    "molecular_estimate",
    "secondary_literature_estimate",
    "formation_age_inference",
    "unresolved",
}
ALLOWED_DATE_CONFIDENCE = {"high", "moderate", "low", None}
PRIMARY_SOURCE_TYPES = {
    "specialist_taxonomic_reference",
    "geochronology_reference",
    "literature",
    "specialist_descriptive_reference",
}
SUPPORT_SOURCE_TYPES = {
    "taxonomic_database",
    "general_reference",
}
DISALLOWED_PRIMARY_DOMAINS = {
    "mindat.org",
    "wikipedia.org",
    "en.wikipedia.org",
}


class DeepTimeYamlDumper(yaml.SafeDumper):
    pass


def str_representer(dumper: yaml.SafeDumper, data: str) -> yaml.ScalarNode:
    if "\n" in data or len(data) > 90:
        return dumper.represent_scalar("tag:yaml.org,2002:str", data, style=">")
    return dumper.represent_scalar("tag:yaml.org,2002:str", data)


DeepTimeYamlDumper.add_representer(str, str_representer)


def load_yaml(path: Path) -> dict[str, Any]:
    if not path.exists():
        raise FileNotFoundError(f"Could not find {path}")
    with path.open("r", encoding="utf-8") as handle:
        data = yaml.safe_load(handle)
    if data is None:
        return {}
    if not isinstance(data, dict):
        raise ValueError(f"Expected top-level YAML mapping in {path}")
    return data


def write_yaml(path: Path, data: dict[str, Any]) -> None:
    with path.open("w", encoding="utf-8") as handle:
        yaml.dump(
            data,
            handle,
            Dumper=DeepTimeYamlDumper,
            sort_keys=False,
            allow_unicode=True,
            default_flow_style=False,
            width=88,
        )

def candidate_has_proposal(candidate: dict[str, Any]) -> bool:
    proposed = candidate.get("proposed_date_resolution", {})
    if not isinstance(proposed, dict):
        return False
    for key in REQUIRED_PROPOSAL_KEYS:
        value = proposed.get(key)
        if key == "date_sources":
            if isinstance(value, list) and any(
                isinstance(item, dict)
                and any(v not in (None, "") for v in item.values())
                for item in value
            ):
                return True
            continue
        if value not in (None, ""):
            return True
    return False


def candidate_matches_status(candidate: dict[str, Any], review_status: str) -> bool:
    review = candidate.get("review", {})
    if not isinstance(review, dict):
        return review_status == DEFAULT_REVIEW_STATUS
    return review.get("status") == review_status


def choose_targets(
    data: dict[str, Any],
    clade_ids: list[str],
    limit: int | None,
    overwrite: bool,
    review_status: str,
) -> list[str]:
    ids = clade_ids or list(data.keys())
    chosen: list[str] = []
    for clade_id in ids:
        candidate = data.get(clade_id)
        if not isinstance(candidate, dict):
            continue
        if not overwrite:
            if not candidate_matches_status(candidate, review_status):
                continue
            if candidate_has_proposal(candidate):
                continue
        chosen.append(clade_id)
        if limit is not None and len(chosen) >= limit:
            break
    return chosen


def strip_code_fences(text: str) -> str:
    lines = text.strip().splitlines()
    if lines and lines[0].strip().startswith("```"):
        lines = lines[1:]
    if lines and lines[-1].strip() == "```":
        lines = lines[:-1]
    return "\n".join(lines).strip()


def normalize_sources(value: Any) -> list[dict[str, Any]]:
    if not isinstance(value, list):
        return []
    normalized: list[dict[str, Any]] = []
    for item in value:
        if not isinstance(item, dict):
            continue
        normalized.append(
            {
                "source_label": item.get("source_label"),
                "source_type": item.get("source_type"),
                "url": item.get("url"),
                "note": item.get("note"),
            }
        )
    return normalized


def normalize_payload(payload: dict[str, Any]) -> dict[str, Any]:
    proposal = payload.get("proposed_date_resolution")
    if not isinstance(proposal, dict):
        raise ValueError("Missing proposed_date_resolution mapping.")
    normalized_proposal = {
        "date_basis": proposal.get("date_basis"),
        "date_confidence": proposal.get("date_confidence"),
        "date_notes": proposal.get("date_notes"),
        "date_resolution_method": proposal.get("date_resolution_method"),
        "date_sources": normalize_sources(proposal.get("date_sources")),
        "divergence_ma": proposal.get("divergence_ma"),
        "end_ma": proposal.get("end_ma"),
        "start_ma": proposal.get("start_ma"),
    }
    review = payload.get("review")
    normalized_review = {
        "decision_note": review.get("decision_note") if isinstance(review, dict) else None,
        "reviewed_at": None,
        "reviewer": None,
        "status": DEFAULT_REVIEW_STATUS,
    }
    return {
        "proposed_date_resolution": normalized_proposal,
        "review": normalized_review,
    }


def parse_response_yaml(text: str) -> dict[str, Any]:
    parsed = yaml.safe_load(strip_code_fences(text))
    if not isinstance(parsed, dict):
        raise ValueError("Expected top-level YAML mapping from model.")
    if "proposed_date_resolution" not in parsed and "review" not in parsed:
        if len(parsed) != 1:
            raise ValueError(
                "Expected either a flat payload or a single top-level clade key in model output."
            )
        only_value = next(iter(parsed.values()))
        if not isinstance(only_value, dict):
            raise ValueError("Single top-level clade key must map to a YAML mapping.")
        parsed = only_value
    return normalize_payload(parsed)


def build_prompt(clade_id: str, candidate: dict[str, Any], *, retry_note: str | None = None) -> str:
    example_yaml = """
alethoalaornithidae:
  proposed_date_resolution:
    date_basis: fossil_first_appearance
    date_confidence: low
    date_notes: >
      Alethoalaornithidae was erected for an enantiornithine bird from the
      Lower Cretaceous of western Liaoning. The included taxon
      Alethoalaornis agitornis is associated with the Jiufotang Formation /
      late Jehol Biota, commonly dated around 120 Ma. This should be treated
      as a fossil-occurrence/formation-derived minimum age, not a true
      molecular or phylogenetic origin estimate.
    date_resolution_method: ai_literature_fallback
    date_sources:
      - source_label: "Li et al. 2007, Acta Palaeontologica Sinica 46(3):365-372"
        source_type: specialist_taxonomic_reference
        url: "https://bionames.org/references/98036aadaaaf4a71c68d4968ed3798ec"
        note: "Original family-level reference; gives Lower Cretaceous of western Liaoning."
      - source_label: "GBIF: Alethoalaornis agitornis"
        source_type: taxonomic_database
        url: "https://www.gbif.org/species/4966922"
        note: "Lists Alethoalaornis agitornis in Alethoalaornithidae; source shown as PBDB."
      - source_label: "He et al. 2004, Jiufotang Formation timing"
        source_type: geochronology_reference
        url: "https://agupubs.onlinelibrary.wiley.com/doi/full/10.1029/2004GL019790"
        note: "Reports Jiufotang deposits dated to 120.3 ± 0.7 Ma."
      - source_label: "Yu et al. 2021, Jiufotang geochronology"
        source_type: geochronology_reference
        url: "https://agris.fao.org/search/en/providers/122535/records/65dfc15d63b8185d9caeac25"
        note: "Places late Jehol/Jiufotang interval around ~123–119 Ma."
    divergence_ma: null
    end_ma: null
    start_ma: 120.3
  review:
    decision_note: >
      Candidate start_ma accepted only as a low-confidence fossil/formation
      age. It should not be interpreted as the evolutionary origin of
      Alethoalaornithidae.
    reviewed_at: null
    reviewer: null
    status: pending
""".strip()

    task_payload = {
        "target_top_level_key": clade_id,
        "target_entry_only": {clade_id: candidate},
        "output_shape": {
            clade_id: {
                "proposed_date_resolution": {
                    "date_basis": "fossil_first_appearance|fossil_range|molecular_estimate|secondary_literature_estimate|formation_age_inference|unresolved",
                    "date_confidence": "high|moderate|low|null",
                    "date_notes": "string|null",
                    "date_resolution_method": "specialist_literature|database_lookup|formation_age_inference|molecular_clock_estimate|ai_literature_fallback|unresolved",
                    "date_sources": [
                        {
                            "source_label": "string|null",
                            "source_type": "specialist_taxonomic_reference|specialist_descriptive_reference|taxonomic_database|geochronology_reference|molecular_clock_reference|literature|general_reference|null",
                            "url": "string|null",
                            "note": "string|null",
                        }
                    ],
                    "divergence_ma": "number|null",
                    "end_ma": "number|null",
                    "start_ma": "number|null",
                },
                "review": {
                    "decision_note": "string|null",
                    "reviewed_at": None,
                    "reviewer": None,
                    "status": DEFAULT_REVIEW_STATUS,
                },
            }
        },
    }
    if retry_note:
        task_payload["retry_feedback"] = retry_note

    return (
        "You are curating clade date candidates for the Deep Time 2 app.\n\n"
        "The script processes data/ai_date_candidates.yaml in batches of 2, but this request is for one specific entry only.\n\n"
        "Your task is to generate a source-backed YAML update for the target entry in the same style, structure, level of detail, and caution as this example:\n\n"
        f"{example_yaml}\n\n"
        "Important instructions:\n\n"
        "1. Use web search. Do not rely only on memory.\n"
        f"2. Use {clade_id} as the top-level YAML key in your output.\n"
        "3. Do not output any other entries.\n"
        "4. Return YAML only. Do not include commentary before or after the YAML.\n"
        "5. Do not include a trailing comma after status: pending.\n\n"
        "Research strategy:\n\n"
        "- Search the exact taxon name.\n"
        "- Search likely included genera, species, type species, synonyms, and spelling variants.\n"
        "- Search for the original taxonomic description.\n"
        "- Search fossil databases such as PBDB and GBIF.\n"
        "- Search for the fossil-bearing formation, locality, or biota.\n"
        "- Search for geochronology of that formation, locality, or biota.\n"
        "- Use molecular-clock evidence only if a specific molecular-clock source exists.\n"
        "- Prefer specialist taxonomic papers and formation geochronology papers over general websites.\n"
        "- Do not use Wikipedia, Mindat, blogs, or unspecialised summary pages as the main basis for a numerical date if stronger sources are available.\n\n"
        "Evidence rules:\n\n"
        "- If the taxon is known from fossils, treat the date as a fossil minimum age.\n"
        "- If the taxon is known from a formation, use the formation age only as a cautious formation-derived minimum.\n"
        "- If the fossil is tied to a dated bed or radiometric horizon, confidence may be moderate or high.\n"
        "- If the date is inferred only from a formation, biota, or broad stratigraphic unit, confidence should usually be low.\n"
        "- Do not invent molecular estimates.\n"
        "- Leave divergence_ma null unless a source explicitly gives a divergence or molecular-clock estimate.\n"
        "- Leave end_ma null unless a real fossil range endpoint is supported.\n"
        "- If no defensible date can be found, set date_basis: unresolved, set numerical fields to null, and explain why.\n\n"
        "Quality target:\n\n"
        "The output should look like a careful research note converted into YAML. It should include enough source detail that a human reviewer can verify the proposed date later.\n\n"
        f"Target payload:\n```json\n{json.dumps(task_payload, indent=2)}\n```"
    )


def call_openai(api_key: str, model: str, prompt: str) -> str:
    client = OpenAI(api_key=api_key)
    response = client.responses.create(
        model=model,
        tools=[{"type": "web_search"}],
        input=prompt,
    )
    text = getattr(response, "output_text", None)
    if not text:
        raise RuntimeError("No text output found in OpenAI response.")
    return text.strip()


def apply_update(candidate: dict[str, Any], update: dict[str, Any]) -> None:
    candidate["proposed_date_resolution"] = deepcopy(update["proposed_date_resolution"])
    candidate["review"] = deepcopy(update["review"])


def _source_domain(source: dict[str, Any]) -> str | None:
    url = source.get("url")
    if not isinstance(url, str) or not url:
        return None
    hostname = urlparse(url).hostname
    return hostname.lower() if hostname else None


def _is_null_resolution(proposal: dict[str, Any]) -> bool:
    return (
        proposal.get("start_ma") is None
        and proposal.get("end_ma") is None
        and proposal.get("divergence_ma") is None
    )


def validate_update(update: dict[str, Any]) -> tuple[bool, str | None]:
    proposal = update["proposed_date_resolution"]
    sources = proposal.get("date_sources") or []
    basis = proposal.get("date_basis")
    confidence = proposal.get("date_confidence")

    if basis not in ALLOWED_DATE_BASIS:
        return False, (
            "date_basis must be one of: fossil_first_appearance, fossil_range, "
            "molecular_estimate, secondary_literature_estimate, formation_age_inference, unresolved."
        )

    if confidence not in ALLOWED_DATE_CONFIDENCE:
        return False, "date_confidence must be high, moderate, low, or null."

    if isinstance(basis, str) and len(basis) > 40:
        return False, "date_basis must be a short classifier, not explanatory prose."

    primary_sources = [
        source
        for source in sources
        if isinstance(source, dict) and source.get("source_type") in PRIMARY_SOURCE_TYPES
    ]
    support_sources = [
        source
        for source in sources
        if isinstance(source, dict) and source.get("source_type") in SUPPORT_SOURCE_TYPES
    ]

    if _is_null_resolution(proposal):
        if basis != "unresolved":
            return False, "Null numerical resolution should normally use date_basis='unresolved'."
        if not proposal.get("date_notes"):
            return False, "Null resolution must include a substantive explanation in date_notes."
        return True, None

    if not primary_sources:
        return False, (
            "Numerical resolution rejected: no primary specialist/literature/geochronology source "
            "was provided."
        )

    for source in primary_sources:
        domain = _source_domain(source)
        if domain in DISALLOWED_PRIMARY_DOMAINS:
            return False, f"Primary source domain {domain} is too generic."

    if len(sources) < 2:
        return False, "Numerical resolution rejected: fewer than 2 supporting sources were provided."

    if proposal.get("divergence_ma") is not None:
        basis_text = str(proposal.get("date_basis") or "").lower()
        method = str(proposal.get("date_resolution_method") or "").lower()
        if "fossil" in basis_text or "fossil" in method:
            return False, (
                "divergence_ma should usually remain null when the proposal is based on fossil "
                "minimum-age evidence."
            )

    if basis in {"fossil_first_appearance", "formation_age_inference"}:
        if proposal.get("start_ma") is None:
            return False, f"{basis} should usually provide start_ma when a numerical resolution is claimed."
        if proposal.get("divergence_ma") is not None:
            return False, f"{basis} should not set divergence_ma without explicit divergence evidence."

    return True, None


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--candidates",
        type=Path,
        default=CANDIDATES_PATH,
        help="Path to ai_date_candidates.yaml.",
    )
    parser.add_argument(
        "--clade-id",
        action="append",
        default=[],
        help="Restrict processing to specific clade id(s). Repeatable.",
    )
    parser.add_argument(
        "--limit",
        type=int,
        default=DEFAULT_BATCH_LIMIT,
        help="Maximum number of entries to process.",
    )
    parser.add_argument(
        "--overwrite",
        action="store_true",
        help="Overwrite entries even if a proposal already exists.",
    )
    parser.add_argument(
        "--review-status",
        default=DEFAULT_REVIEW_STATUS,
        help="Only process entries with this review status unless --overwrite is set.",
    )
    parser.add_argument(
        "--model",
        default=DEFAULT_MODEL,
        help="OpenAI model to use.",
    )
    parser.add_argument(
        "--delay-seconds",
        type=float,
        default=0.0,
        help="Optional sleep between successful updates.",
    )
    parser.add_argument(
        "--max-attempts",
        type=int,
        default=3,
        help="Maximum OpenAI attempts per entry before giving up.",
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Show which entries would be processed without updating YAML.",
    )
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    api_key = os.getenv("OPENAI_API_KEY")
    if not args.dry_run and not api_key:
        raise SystemExit("OPENAI_API_KEY is not set.")

    data = load_yaml(args.candidates)
    target_ids = choose_targets(
        data=data,
        clade_ids=args.clade_id,
        limit=args.limit,
        overwrite=args.overwrite,
        review_status=args.review_status,
    )

    print(f"Candidates file: {args.candidates}")
    print(f"Eligible entries: {len(target_ids)}")
    if args.dry_run:
        for clade_id in target_ids:
            print(clade_id)
        return 0

    updated: list[str] = []
    failed: list[tuple[str, str]] = []

    for index, clade_id in enumerate(target_ids, start=1):
        print(f"[{index}/{len(target_ids)}] Updating {clade_id}...", file=sys.stderr)
        candidate = data.get(clade_id)
        if not isinstance(candidate, dict):
            failed.append((clade_id, "candidate missing or invalid"))
            continue
        try:
            retry_note = None
            update = None
            for attempt in range(1, args.max_attempts + 1):
                prompt = build_prompt(clade_id, candidate, retry_note=retry_note)
                response_text = call_openai(api_key, args.model, prompt)
                candidate_update = parse_response_yaml(response_text)
                valid, feedback = validate_update(candidate_update)
                if valid:
                    update = candidate_update
                    break
                retry_note = (
                    f"Previous attempt {attempt} was rejected. Reason: {feedback} "
                    "Find stronger data and return a stricter source-backed answer."
                )
            if update is None:
                raise RuntimeError(retry_note or "Unable to produce a valid update.")
            apply_update(candidate, update)
            write_yaml(args.candidates, data)
            updated.append(clade_id)
            if args.delay_seconds > 0:
                time.sleep(args.delay_seconds)
        except Exception as error:
            failed.append((clade_id, str(error)))

    print(f"Updated: {len(updated)}")
    print(f"Failed: {len(failed)}")
    if failed:
        print("Failures:")
        for clade_id, message in failed:
            print(f"  - {clade_id}: {message}")
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
