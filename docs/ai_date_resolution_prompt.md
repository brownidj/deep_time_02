# AI Date Resolution Prompt

Use the JSON payload below as context. Return YAML only, with top-level keys as clade ids.

```json
{
  "task": "Resolve clade dates with provenance and confidence.",
  "rules": [
    "Do not overwrite curated values; propose candidates only.",
    "Use hierarchy: specialist, PBDB, TimeTree, reputable educational, generalised fallback, proxy.",
    "Differentiate fossil first appearance vs molecular divergence.",
    "Mark low-confidence values clearly."
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
          "note": "string"
        }
      ],
      "date_notes": "string"
    }
  },
  "clades": [
    {
      "id": "alethoalaornithidae",
      "scientific_label": "Alethoalaornithidae",
      "common_label": "Alethoalaornithidae",
      "rank": "family",
      "parent_id": "dinosauria",
      "current_start_ma": null,
      "current_end_ma": null,
      "current_divergence_ma": null,
      "current_method": "unresolved"
    },
    {
      "id": "archaeoceratopsidae",
      "scientific_label": "Archaeoceratopsidae",
      "common_label": "Archaeoceratopsidae",
      "rank": "family",
      "parent_id": "dinosauria",
      "current_start_ma": null,
      "current_end_ma": null,
      "current_divergence_ma": null,
      "current_method": "unresolved"
    },
    {
      "id": "arriagadoolithidae",
      "scientific_label": "Arriagadoolithidae",
      "common_label": "Arriagadoolithidae",
      "rank": "family",
      "parent_id": "dinosauria",
      "current_start_ma": null,
      "current_end_ma": null,
      "current_divergence_ma": null,
      "current_method": "unresolved"
    },
    {
      "id": "balochisauridae",
      "scientific_label": "Balochisauridae",
      "common_label": "Balochisauridae",
      "rank": "family",
      "parent_id": "dinosauria",
      "current_start_ma": null,
      "current_end_ma": null,
      "current_divergence_ma": null,
      "current_method": "unresolved"
    },
    {
      "id": "bohaiornithidae",
      "scientific_label": "Bohaiornithidae",
      "common_label": "Bohaiornithidae",
      "rank": "family",
      "parent_id": "dinosauria",
      "current_start_ma": null,
      "current_end_ma": null,
      "current_divergence_ma": null,
      "current_method": "unresolved"
    },
    {
      "id": "brodavidae",
      "scientific_label": "Brodavidae",
      "common_label": "Brodavidae",
      "rank": "family",
      "parent_id": "dinosauria",
      "current_start_ma": null,
      "current_end_ma": null,
      "current_divergence_ma": null,
      "current_method": "unresolved"
    },
    {
      "id": "caudipterygidae",
      "scientific_label": "Caudipterygidae",
      "common_label": "Caudipterygidae",
      "rank": "family",
      "parent_id": "dinosauria",
      "current_start_ma": null,
      "current_end_ma": null,
      "current_divergence_ma": null,
      "current_method": "unresolved"
    },
    {
      "id": "eoenantiornithidae",
      "scientific_label": "Eoenantiornithidae",
      "common_label": "Eoenantiornithidae",
      "rank": "family",
      "parent_id": "dinosauria",
      "current_start_ma": null,
      "current_end_ma": null,
      "current_divergence_ma": null,
      "current_method": "unresolved"
    },
    {
      "id": "guaibasauridae",
      "scientific_label": "Guaibasauridae",
      "common_label": "Guaibasauridae",
      "rank": "family",
      "parent_id": "dinosauria",
      "current_start_ma": null,
      "current_end_ma": null,
      "current_divergence_ma": null,
      "current_method": "unresolved"
    },
    {
      "id": "hesperornidae",
      "scientific_label": "Hesperornidae",
      "common_label": "Hesperornidae",
      "rank": "family",
      "parent_id": "dinosauria",
      "current_start_ma": null,
      "current_end_ma": null,
      "current_divergence_ma": null,
      "current_method": "unresolved"
    },
    {
      "id": "heterostrigidae",
      "scientific_label": "Heterostrigidae",
      "common_label": "Heterostrigidae",
      "rank": "family",
      "parent_id": "dinosauria",
      "current_start_ma": null,
      "current_end_ma": null,
      "current_divergence_ma": null,
      "current_method": "unresolved"
    },
    {
      "id": "hongshanornithidae",
      "scientific_label": "Hongshanornithidae",
      "common_label": "Hongshanornithidae",
      "rank": "family",
      "parent_id": "dinosauria",
      "current_start_ma": null,
      "current_end_ma": null,
      "current_divergence_ma": null,
      "current_method": "unresolved"
    },
    {
      "id": "huanghetitanidae",
      "scientific_label": "Huanghetitanidae",
      "common_label": "Huanghetitanidae",
      "rank": "family",
      "parent_id": "dinosauria",
      "current_start_ma": null,
      "current_end_ma": null,
      "current_divergence_ma": null,
      "current_method": "unresolved"
    },
    {
      "id": "ignotornidae",
      "scientific_label": "Ignotornidae",
      "common_label": "Ignotornidae",
      "rank": "family",
      "parent_id": "dinosauria",
      "current_start_ma": null,
      "current_end_ma": null,
      "current_divergence_ma": null,
      "current_method": "unresolved"
    },
    {
      "id": "mamenchisauridae",
      "scientific_label": "Mamenchisauridae",
      "common_label": "Mamenchisauridae",
      "rank": "family",
      "parent_id": "dinosauria",
      "current_start_ma": null,
      "current_end_ma": null,
      "current_divergence_ma": null,
      "current_method": "unresolved"
    },
    {
      "id": "messelasturidae",
      "scientific_label": "Messelasturidae",
      "common_label": "Messelasturidae",
      "rank": "family",
      "parent_id": "dinosauria",
      "current_start_ma": null,
      "current_end_ma": null,
      "current_divergence_ma": null,
      "current_method": "unresolved"
    },
    {
      "id": "metriacanthosauridae",
      "scientific_label": "Metriacanthosauridae",
      "common_label": "Metriacanthosauridae",
      "rank": "family",
      "parent_id": "dinosauria",
      "current_start_ma": null,
      "current_end_ma": null,
      "current_divergence_ma": null,
      "current_method": "unresolved"
    },
    {
      "id": "montanoolithidae",
      "scientific_label": "Montanoolithidae",
      "common_label": "Montanoolithidae",
      "rank": "family",
      "parent_id": "dinosauria",
      "current_start_ma": null,
      "current_end_ma": null,
      "current_divergence_ma": null,
      "current_method": "unresolved"
    },
    {
      "id": "moyenisauropodidae",
      "scientific_label": "Moyenisauropodidae",
      "common_label": "Moyenisauropodidae",
      "rank": "family",
      "parent_id": "dinosauria",
      "current_start_ma": null,
      "current_end_ma": null,
      "current_divergence_ma": null,
      "current_method": "unresolved"
    },
    {
      "id": "mystiornithidae",
      "scientific_label": "Mystiornithidae",
      "common_label": "Mystiornithidae",
      "rank": "family",
      "parent_id": "dinosauria",
      "current_start_ma": null,
      "current_end_ma": null,
      "current_divergence_ma": null,
      "current_method": "unresolved"
    },
    {
      "id": "omnivoropterygidae",
      "scientific_label": "Omnivoropterygidae",
      "common_label": "Omnivoropterygidae",
      "rank": "family",
      "parent_id": "dinosauria",
      "current_start_ma": null,
      "current_end_ma": null,
      "current_divergence_ma": null,
      "current_method": "unresolved"
    },
    {
      "id": "ornithomimipodidae",
      "scientific_label": "Ornithomimipodidae",
      "common_label": "Ornithomimipodidae",
      "rank": "family",
      "parent_id": "dinosauria",
      "current_start_ma": null,
      "current_end_ma": null,
      "current_divergence_ma": null,
      "current_method": "unresolved"
    },
    {
      "id": "ovaloolithidae",
      "scientific_label": "Ovaloolithidae",
      "common_label": "Ovaloolithidae",
      "rank": "family",
      "parent_id": "dinosauria",
      "current_start_ma": null,
      "current_end_ma": null,
      "current_divergence_ma": null,
      "current_method": "unresolved"
    },
    {
      "id": "pachycorioolithidae",
      "scientific_label": "Pachycorioolithidae",
      "common_label": "Pachycorioolithidae",
      "rank": "family",
      "parent_id": "dinosauria",
      "current_start_ma": null,
      "current_end_ma": null,
      "current_divergence_ma": null,
      "current_method": "unresolved"
    },
    {
      "id": "pakisauridae",
      "scientific_label": "Pakisauridae",
      "common_label": "Pakisauridae",
      "rank": "family",
      "parent_id": "dinosauria",
      "current_start_ma": null,
      "current_end_ma": null,
      "current_divergence_ma": null,
      "current_method": "unresolved"
    },
    {
      "id": "parvicursoridae",
      "scientific_label": "Parvicursoridae",
      "common_label": "Parvicursoridae",
      "rank": "family",
      "parent_id": "dinosauria",
      "current_start_ma": null,
      "current_end_ma": null,
      "current_divergence_ma": null,
      "current_method": "unresolved"
    },
    {
      "id": "parvigruidae",
      "scientific_label": "Parvigruidae",
      "common_label": "Parvigruidae",
      "rank": "family",
      "parent_id": "dinosauria",
      "current_start_ma": null,
      "current_end_ma": null,
      "current_divergence_ma": null,
      "current_method": "unresolved"
    },
    {
      "id": "pengornithidae",
      "scientific_label": "Pengornithidae",
      "common_label": "Pengornithidae",
      "rank": "family",
      "parent_id": "dinosauria",
      "current_start_ma": null,
      "current_end_ma": null,
      "current_divergence_ma": null,
      "current_method": "unresolved"
    },
    {
      "id": "piatnitzkysauridae",
      "scientific_label": "Piatnitzkysauridae",
      "common_label": "Piatnitzkysauridae",
      "rank": "family",
      "parent_id": "dinosauria",
      "current_start_ma": null,
      "current_end_ma": null,
      "current_divergence_ma": null,
      "current_method": "unresolved"
    },
    {
      "id": "polyclonoolithidae",
      "scientific_label": "Polyclonoolithidae",
      "common_label": "Polyclonoolithidae",
      "rank": "family",
      "parent_id": "dinosauria",
      "current_start_ma": null,
      "current_end_ma": null,
      "current_divergence_ma": null,
      "current_method": "unresolved"
    },
    {
      "id": "proceratosauridae",
      "scientific_label": "Proceratosauridae",
      "common_label": "Proceratosauridae",
      "rank": "family",
      "parent_id": "dinosauria",
      "current_start_ma": null,
      "current_end_ma": null,
      "current_divergence_ma": null,
      "current_method": "unresolved"
    },
    {
      "id": "protoplotidae",
      "scientific_label": "Protoplotidae",
      "common_label": "Protoplotidae",
      "rank": "family",
      "parent_id": "dinosauria",
      "current_start_ma": null,
      "current_end_ma": null,
      "current_divergence_ma": null,
      "current_method": "unresolved"
    },
    {
      "id": "psilopteridae",
      "scientific_label": "Psilopteridae",
      "common_label": "Psilopteridae",
      "rank": "family",
      "parent_id": "dinosauria",
      "current_start_ma": null,
      "current_end_ma": null,
      "current_divergence_ma": null,
      "current_method": "unresolved"
    },
    {
      "id": "qianshanornithidae",
      "scientific_label": "Qianshanornithidae",
      "common_label": "Qianshanornithidae",
      "rank": "family",
      "parent_id": "dinosauria",
      "current_start_ma": null,
      "current_end_ma": null,
      "current_divergence_ma": null,
      "current_method": "unresolved"
    },
    {
      "id": "rhegminornithidae",
      "scientific_label": "Rhegminornithidae",
      "common_label": "Rhegminornithidae",
      "rank": "family",
      "parent_id": "dinosauria",
      "current_start_ma": null,
      "current_end_ma": null,
      "current_divergence_ma": null,
      "current_method": "unresolved"
    },
    {
      "id": "saltasauridae",
      "scientific_label": "Saltasauridae",
      "common_label": "Saltasauridae",
      "rank": "family",
      "parent_id": "dinosauria",
      "current_start_ma": null,
      "current_end_ma": null,
      "current_divergence_ma": null,
      "current_method": "unresolved"
    },
    {
      "id": "sauropodidae",
      "scientific_label": "Sauropodidae",
      "common_label": "Sauropodidae",
      "rank": "family",
      "parent_id": "dinosauria",
      "current_start_ma": null,
      "current_end_ma": null,
      "current_divergence_ma": null,
      "current_method": "unresolved"
    }
  ]
}
```
