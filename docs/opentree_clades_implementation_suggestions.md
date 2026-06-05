# OpenTree Clades Implementation Suggestions

Good reference doc. It aligns with the current architecture, and most of it can be added incrementally without runtime API coupling.

## What Already Matches

- Curated runtime data model is already in place: [clade.dart](/Users/david/AndroidStudioProjects/flutter/Deep_Time/lib/domain/models/clade.dart), [yaml_clade_repository.dart](/Users/david/AndroidStudioProjects/flutter/Deep_Time/lib/infra/repositories/yaml_clade_repository.dart).
- UI already uses priority/group/view filtering patterns: [timeline_vertical_columns_clades_helpers.dart](/Users/david/AndroidStudioProjects/flutter/Deep_Time/lib/ui/screens/timeline/timeline_vertical_columns_clades_helpers.dart), [clade_view_mode.dart](/Users/david/AndroidStudioProjects/flutter/Deep_Time/lib/ui/models/clade_view_mode.dart).

## How To Implement The Reference Features

1. **Extend clade schema (non-breaking)**
- Add optional fields first:
  - `scientific_label`, `opentree_name`, `ott_id`
  - `branch_priority`, `cladistic_role`, `include_in_main_tree`, `collapsed_by_default`
  - nested `opentree` object (`matched_name`, `rank`, `flags`, `lineage_ids`, `checked_at`)
- Keep existing required fields unchanged to avoid breaking current app loading.
- Update parser/model to read these as nullable/optional.

2. **Add build-time OpenTree integration script**
- Create `scripts/update_clades_from_opentree.py` with modes:
  - `resolve`: TNRS name->OTT, write cache
  - `validate`: compare `parent_id` chain vs OpenTree lineage
  - `subtree`: induced subtree sanity-check for selected visible clades
  - `report`: write `docs/clades_opentree_report.md`
- Write cache to `data/clades_opentree_cache.yaml`.
- Do **not** auto-rewrite `data/clades.yaml` unless explicit `--write`.

3. **Define mismatch policy**
- Add explicit rules in script/report:
  - “Missing intermediate clades” = warning, not failure.
  - True contradiction (child outside claimed ancestor lineage) = error.
- This matches the simplified educational tree approach.

4. **Wire zoom/display strategy into filtering**
- The current code already filters by visible time and groups.
- Add `min_zoom_level` and `display_priority` gating based on current timeline scale in `_filterVisibleClades(...)`.
- Optionally add `collapsed_by_default` behavior in clade tree layout for dense spans.

5. **Support common-name vs scientific-name display**
- Keep `label` as UI default.
- Add `scientific_label` and a display mode toggle (e.g. “Common / Scientific / Both”).
- Tooltip/modal can show both.

6. **Add validation tests**
- Schema parse tests for new optional fields.
- Parent lineage validation unit tests from cached OpenTree responses.
- UI filtering tests for zoom thresholds and `include_in_main_tree`.

## Recommended Implementation Order

1. Schema + parser + tests  
2. OpenTree script + cache + report generation  
3. Zoom/priority filtering in UI  
4. Label-mode toggle and collapsed behavior

This keeps runtime stable while improving taxonomic defensibility at build-time, exactly as the reference recommends.
