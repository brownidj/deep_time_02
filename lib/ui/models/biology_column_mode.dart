enum BiologyColumnMode { cladistic, taxonomic }

extension BiologyColumnModeMeta on BiologyColumnMode {
  String get id {
    switch (this) {
      case BiologyColumnMode.cladistic:
        return 'cladistic';
      case BiologyColumnMode.taxonomic:
        return 'taxonomic';
    }
  }

  String get label {
    switch (this) {
      case BiologyColumnMode.cladistic:
        return 'Clades';
      case BiologyColumnMode.taxonomic:
        return 'Taxonomy';
    }
  }
}

BiologyColumnMode parseBiologyColumnMode(String? value) {
  switch (value) {
    case 'taxonomic':
      return BiologyColumnMode.taxonomic;
    case 'cladistic':
    default:
      return BiologyColumnMode.cladistic;
  }
}
