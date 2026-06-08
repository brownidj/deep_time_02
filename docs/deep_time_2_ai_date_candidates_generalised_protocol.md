# Deep Time 2: Generalised AI Date Candidate Resolution Protocol

This document generalises the Alethoalaornithidae date-resolution response into a reusable process for all entries in `ai_date_candidates.yaml`.

The aim is to make each unresolved taxon reviewable, provenance-rich, and scientifically cautious. The key principle is that a proposed `start_ma` should only be supplied when the evidence supports it. Where the evidence only supports a broad formation age, stage range, or uncertain fossil occurrence, the numeric fields should remain `null` until a reviewer accepts a specific minimum age.

---

## 1. Purpose

Many clades and taxonomic families in `ai_date_candidates.yaml` are difficult to date because they may be rare fossil taxa, poorly resolved taxonomic groups, monogeneric families, trace-fossil or egg-fossil families, outdated or disputed names, taxa known only from one formation, taxa with no molecular-clock equivalent, or taxa with only broad stratigraphic information available.

The purpose of the AI fallback process is not to force every entry to have a number. The purpose is to determine whether any defensible `start_ma` can be proposed, and to explain the evidence trail clearly.

---

## 2. Preferred interpretation of `start_ma`

For extinct or fossil-only taxa, `start_ma` should usually mean:

> the oldest defensible fossil occurrence or stratigraphic minimum age currently known for the taxon or its accepted included members.

It should not be interpreted as the true evolutionary origin of the clade unless a formal divergence-time estimate is available.

For living taxa with molecular-clock estimates, `start_ma` may instead represent:

> a published molecular divergence estimate, ideally with uncertainty bounds.

Where both are available, fossil and molecular dates should be stored separately where possible. They should not be silently collapsed into a single number.

---

## 3. Evidence hierarchy

Use the following order of preference when resolving any entry in `ai_date_candidates.yaml`.

### 3.1 Specialist taxonomic literature

First preference should be given to peer-reviewed specialist sources that directly describe, revise, or date the taxon.

Examples include original taxon descriptions, taxonomic revisions, phylogenetic analyses, fossil descriptions, formation-specific palaeontological papers, museum specimen papers, and geochronology papers tied to the fossil-bearing horizon.

These are the strongest sources when they directly connect the taxon to a formation, bed, locality, or dated horizon.

### 3.2 Public fossil databases

Next, check public fossil occurrence databases.

Useful sources include Paleobiology Database, GBIF fossil records where sourced from PBDB, Mindat fossil occurrence pages with caution, and museum databases if publicly accessible.

These can provide occurrence age ranges, but they may not always distinguish between a precise occurrence, a formation-level assignment, and a broad stage-level estimate.

### 3.3 Geochronology of the host formation

If the taxon is clearly known from a named formation but no specimen-level date is available, use dated studies of that formation.

This can support a conservative fossil minimum, but only if the taxon is securely tied to that formation.

For example:

```text
Taxon known from: Jiufotang Formation
Formation age range: approximately 122–118 Ma
Safe conclusion: the taxon has an Early Cretaceous / Aptian fossil occurrence
Unsafe conclusion: the clade originated exactly at 120.3 Ma
```

### 3.4 Molecular-clock databases

For extant taxa, or extinct taxa nested inside clades with living descendants, check molecular-clock resources.

Useful sources include TimeTree, DateLife, major published timetrees, and clade-specific molecular phylogenies.

Molecular dates should be clearly labelled as divergence estimates, not fossil first appearances.

### 3.5 Reputable educational or reference sources

Use these only when stronger sources are unavailable.

Examples include Encyclopaedia Britannica, museum pages, university pages, Natural History Museum pages, and carefully checked Wikipedia pages only as pointers to primary references, not as final authority.

### 3.6 AI literature fallback

Use AI-assisted synthesis only as a last structured fallback.

This is appropriate when the taxon is obscure, direct database results are missing, only scattered references exist, the taxon can be connected to a formation or included genus, and the uncertainty can be stated clearly.

The fallback must always retain source notes and confidence labels.

---

## 4. Decision rules for assigning dates

### 4.1 When to assign `start_ma`

Assign `start_ma` only when there is a defensible oldest occurrence or divergence estimate.

Acceptable cases include:

```text
A taxon is directly reported from a formation with a reasonably constrained age.
A specimen is tied to a dated bed, member, locality, or radiometric horizon.
PBDB gives a usable occurrence age range.
A specialist paper gives a minimum age or age range.
A molecular-clock source gives a divergence estimate.
```

### 4.2 When to leave `start_ma` as `null`

Leave `start_ma` as `null` when:

```text
The taxon is known only vaguely as “Early Cretaceous” or “Late Jurassic” and no tighter source is available.
The family is disputed or has unclear membership.
Only a broad formation age is available but the specimen horizon cannot be verified.
The apparent source is circular, unsourced, or general-reference only.
The date would imply false precision.
The taxon may be invalid, obsolete, or synonymised.
```

### 4.3 When to assign `end_ma`

Assign `end_ma` only if the taxon has a defensible youngest known occurrence or range endpoint.

For many app display cases, `end_ma` may remain `null`, especially if the column only needs a start position.

### 4.4 How to handle ranges

If the evidence gives a range, do not automatically convert it to a single point.

For example:

```yaml
start_ma: 122.0
end_ma: 118.0
```

may be suitable if the aim is to show an occurrence interval.

However, if `start_ma` is intended to represent the oldest known occurrence, then use the older bound:

```yaml
start_ma: 122.0
end_ma: null
```

and explain that this is the older bound of the formation or occurrence interval.

If the available range is too broad or poorly tied to the taxon, leave the numbers `null` and explain the constraint in `date_notes`.

---

## 5. Confidence levels

Use consistent confidence labels.

### High confidence

Use `high` only when the taxon is directly tied to a dated specimen, bed, locality, or well-constrained occurrence; the source is specialist literature or a reliable public database; and the age is not merely inferred from a broad period or epoch.

### Moderate confidence

Use `moderate` when the taxon is securely tied to a named formation, the formation has a well-constrained age range, and the exact specimen horizon is not known but the inference is reasonable.

### Low confidence

Use `low` when the taxon is obscure, disputed, poorly sourced, or known only from broad stratigraphic context; the proposed date is based on formation-level inference; the original source cannot be fully checked; the taxon is monogeneric and the exact occurrence is uncertain; or the date is a conservative placeholder rather than a reviewed value.

### Unresolved

Use `unresolved` or leave confidence `null` when no usable evidence supports a date, the available evidence is too vague or unreliable, or the taxon itself may not be valid.

---

## 6. Recommended `date_resolution_method` values

Use controlled language so the YAML remains searchable and filterable.

Recommended values:

```text
fossil_first_appearance
formation_age_inference
stage_range_inference
molecular_clock_estimate
combined_fossil_and_molecular
taxonomic_proxy
ai_literature_fallback
unresolved
```

Avoid free-text method labels such as:

```text
based on fossils
estimated from records
general Early Cretaceous age
rough guess
```

Those explanations belong in `date_notes`, not in `date_resolution_method`.

---

## 7. Recommended `date_basis` values

`date_basis` should be short and categorical, not a full paragraph.

Recommended values:

```text
fossil_first_appearance
formation_constrained_fossil_occurrence
stage_constrained_fossil_occurrence
molecular_divergence_estimate
combined_fossil_and_molecular_estimate
taxonomic_proxy_estimate
unresolved
```

Long explanatory text should go in `date_notes`.

---

## 8. Generalised YAML template

Use the following structure for each unresolved taxon.

```yaml
taxon_id:
  context:
    common_label: Example taxon
    current_dates:
      date_basis: unresolved
      date_confidence: low
      date_notes: >-
        No usable specialist, PBDB, TimeTree, or reputable educational date found for example_taxon.
      date_resolution_method: unresolved
      divergence_ma: null
      end_ma: null
      start_ma: null
    label: Example taxon
    parent_id: parent_taxon_id
    rank: family

  proposed_date_resolution:
    date_basis: unresolved
    date_confidence: low
    date_notes: >-
      Summarise the best available evidence. State whether the taxon is valid, whether it is
      tied to a particular genus, species, specimen, locality, formation, stage, or molecular
      divergence estimate. If only broad stratigraphic context is available, say so explicitly.
      If the available evidence does not justify a numeric value, explain why the numeric
      fields remain null.
    date_resolution_method: unresolved
    date_sources:
      - source_label: null
        source_type: null
        url: null
        note: null
    divergence_ma: null
    end_ma: null
    start_ma: null

  review:
    decision_note: >-
      Explain the decision in plain language. State whether a numeric date was accepted,
      rejected, or left pending. If left unresolved, list the exact evidence still needed:
      for example, the original description, specimen-level horizon, PBDB occurrence, museum
      catalogue record, or formation geochronology.
    reviewed_at: null
    reviewer: null
    status: pending
```

---

## 9. Template for a successful fossil-based proposal

Use this when a defensible fossil first appearance or formation-constrained minimum age can be proposed.

```yaml
taxon_id:
  proposed_date_resolution:
    date_basis: fossil_first_appearance
    date_confidence: moderate
    date_notes: >-
      The taxon is represented by one or more accepted fossil occurrences from [formation/locality].
      The host unit is dated to approximately [older_bound]–[younger_bound] Ma. Because the
      exact specimen horizon is [known/not known], the proposed start_ma is treated as a
      conservative fossil minimum age, not a true evolutionary origin date.
    date_resolution_method: formation_age_inference
    date_sources:
      - source_label: Author et al. Year. Title.
        source_type: specialist_taxonomic_reference
        url: https://example.org
        note: >-
          Establishes or confirms the taxon and its occurrence in the named formation.
      - source_label: Author et al. Year. Geochronology of the relevant formation.
        source_type: geochronology_reference
        url: https://example.org
        note: >-
          Provides the age constraint used for the formation or fossil-bearing horizon.
    divergence_ma: null
    end_ma: null
    start_ma: 120.3

  review:
    decision_note: >-
      Accepted start_ma as a conservative fossil minimum based on a secure occurrence in a
      dated formation. This value should not be interpreted as a molecular divergence date
      or the true origin of the clade.
    reviewed_at: null
    reviewer: null
    status: pending
```

---

## 10. Template for a molecular-clock proposal

Use this when a usable divergence-time estimate is available.

```yaml
taxon_id:
  proposed_date_resolution:
    date_basis: molecular_divergence_estimate
    date_confidence: moderate
    date_notes: >-
      A molecular-clock estimate is available for the relevant taxon or nearest accepted
      equivalent. The estimate is used as a divergence-time proxy and should be stored
      separately from fossil first appearance data. Where confidence intervals are available,
      they should be retained in auxiliary fields or in the notes.
    date_resolution_method: molecular_clock_estimate
    date_sources:
      - source_label: TimeTree / DateLife / Author et al. Year.
        source_type: molecular_clock_database
        url: https://example.org
        note: >-
          Provides the divergence estimate or source chronogram used for this value.
    divergence_ma: 150.0
    end_ma: null
    start_ma: 150.0

  review:
    decision_note: >-
      Accepted start_ma as a molecular divergence estimate. This should be displayed and
      labelled separately from fossil first-appearance evidence.
    reviewed_at: null
    reviewer: null
    status: pending
```

---

## 11. Template for keeping an entry unresolved

Use this when the evidence does not justify a numeric value.

```yaml
taxon_id:
  proposed_date_resolution:
    date_basis: unresolved
    date_confidence: low
    date_notes: >-
      The taxon appears in [source/context], but no accessible specialist, PBDB, TimeTree,
      or reputable educational source provides a secure occurrence age, specimen horizon,
      formation tie, or molecular divergence estimate. A broad period/stage assignment was
      found, but this is too imprecise to justify a numeric start_ma.
    date_resolution_method: unresolved
    date_sources:
      - source_label: Source label if any
        source_type: general_reference
        url: https://example.org
        note: >-
          Provides only broad context and does not justify a numeric date.
    divergence_ma: null
    end_ma: null
    start_ma: null

  review:
    decision_note: >-
      Kept all numeric fields null. The available evidence does not support a defensible
      start_ma without overstating precision. Next steps: obtain the original taxonomic
      description, verify accepted membership, check PBDB occurrence data, and look for
      formation-level geochronology tied to the fossil-bearing horizon.
    reviewed_at: null
    reviewer: null
    status: pending
```

---

## 12. Generalised Alethoalaornithidae-style wording

The Alethoalaornithidae case is useful as a model for cautious formation-based resolution.

Generalised version:

```yaml
taxon_id:
  proposed_date_resolution:
    date_basis: unresolved
    date_confidence: low
    date_notes: >-
      [Taxon] is reported from [formation/locality/stage], and the relevant host unit has
      published age constraints of approximately [older_bound]–[younger_bound] Ma. However,
      an accessible, specimen-level horizon or direct bed-level association could not be
      verified. These values therefore constrain only a possible fossil occurrence window
      and do not justify a single numeric date for the clade's origin. Treat any
      formation-derived value strictly as a minimum age, not an evolutionary divergence date.
    date_resolution_method: unresolved
    date_sources:
      - source_label: Original taxonomic or descriptive source
        source_type: specialist_taxonomic_reference
        url: https://example.org
        note: >-
          Establishes or reports the taxon from the relevant region or formation.
      - source_label: Bibliographic or database confirmation
        source_type: taxonomic_database
        url: https://example.org
        note: >-
          Confirms the taxon, included genus/species, or bibliographic record.
      - source_label: Geochronology source for the host formation
        source_type: geochronology_reference
        url: https://example.org
        note: >-
          Provides age constraints for the formation or fossil-bearing unit.
    divergence_ma: null
    end_ma: null
    start_ma: null

  review:
    decision_note: >-
      Kept all numeric fields null. Although [Taxon] is supported by [taxonomic evidence],
      no accessible, bed-level stratigraphic tie was found for the relevant specimen or
      occurrence beyond [formation/stage]. The host unit is bracketed by published ages of
      approximately [older_bound]–[younger_bound] Ma, but selecting a single value would
      overstate precision. Next steps: obtain the original description, verify the exact
      locality and horizon, check museum or PBDB occurrence records, and then propose a
      calibrated minimum age if a dated horizon can be tied to the fossil.
    reviewed_at: null
    reviewer: null
    status: pending
```

---

## 13. Recommended review statuses

Use consistent status values.

```text
pending
ai_proposed
accepted
accepted_with_caution
rejected
unresolved
needs_primary_source
needs_taxonomic_review
```

Suggested meanings:

```text
pending
  Awaiting manual review.

ai_proposed
  AI has proposed a resolution, but it has not been reviewed.

accepted
  Reviewer accepts the proposed numeric value.

accepted_with_caution
  Reviewer accepts the value as a display minimum only.

rejected
  Reviewer rejects the proposed value.

unresolved
  No value should be used at present.

needs_primary_source
  Original description or primary literature must be checked.

needs_taxonomic_review
  The taxon may be invalid, synonymised, obsolete, or misclassified.
```

---

## 14. Recommended app display language

When the app uses these values, the UI should avoid presenting them as exact origin dates unless they are true divergence estimates.

Suggested display labels:

```text
Fossil minimum: 120.3 Ma
Formation-constrained: approximately 122–118 Ma
Molecular estimate: 150 Ma
Unresolved: no reliable date yet
Proxy estimate: based on nearest dated relative
```

Suggested caution text:

```text
This is a fossil minimum age, not the true origin of the group.
```

```text
This value is inferred from the age of the host formation.
```

```text
This taxon is not currently dateable from available public sources.
```

---

## 15. Practical workflow for each YAML entry

For each entry in `ai_date_candidates.yaml`:

1. Confirm the taxon spelling and current accepted status.
2. Identify included genus/species/specimen where possible.
3. Search specialist taxonomic literature.
4. Search PBDB or other public fossil occurrence databases.
5. Search for host formation, locality, stage, or member.
6. Search for geochronology of the relevant formation.
7. Search TimeTree or DateLife only where molecular-clock dating is plausible.
8. Decide whether the evidence supports a numeric fossil minimum, a numeric molecular divergence estimate, a broad range only, or no usable date.
9. Fill `date_sources` with all useful sources.
10. Write `date_notes` explaining the evidence and uncertainty.
11. Write `review.decision_note` explaining the decision.
12. Leave numeric fields `null` if a number would overstate precision.

---

## 16. Recommended rule for Deep Time 2

For the Cladistic view, only align clades that have a usable `start_ma`.

For the Taxonomy view, do not require every taxon to have `start_ma`. Taxonomy can be displayed hierarchically without forcing a dated origin.

This avoids the central problem:

```text
Clades need defensible dates to align with geological time.
Taxonomy needs stable hierarchy first; dates are useful but optional.
```

Therefore, unresolved taxa should remain in the taxonomy database, but should not be time-aligned unless a defensible fossil or molecular date exists.

---

## 17. Summary

The general rule is:

> Use numbers only where the evidence supports numbers. Use notes where the evidence only supports context.

For `ai_date_candidates.yaml`, a cautious `null` with a clear explanation is better than a precise-looking but unsupported `start_ma`.

The best entries will separate:

```text
What is the taxon?
Is it valid?
What fossil or molecular evidence exists?
What age does that evidence support?
Is that age a first appearance, formation inference, proxy, or divergence estimate?
How confident are we?
Should the app align it to geological time?
```
