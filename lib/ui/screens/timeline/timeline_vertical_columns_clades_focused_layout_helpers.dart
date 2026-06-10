part of 'timeline_vertical_columns.dart';

bool _isDescendantOfRoot({
  required Clade clade,
  required String rootCladeId,
  required Map<String, Clade> allById,
}) {
  var current = clade.parentId == null ? null : allById[clade.parentId!];
  final visited = <String>{clade.id};
  while (current != null && visited.add(current.id)) {
    if (current.id == rootCladeId) {
      return true;
    }
    final parentId = current.parentId;
    current = parentId == null ? null : allById[parentId];
  }
  return false;
}

int _compareFocusedClades(Clade a, Clade b) {
  final branchPriorityA = a.branchPriority ?? 1 << 20;
  final branchPriorityB = b.branchPriority ?? 1 << 20;
  final branchPriorityCompare = branchPriorityA.compareTo(branchPriorityB);
  if (branchPriorityCompare != 0) {
    return branchPriorityCompare;
  }
  final startCompare = b.startMa.compareTo(a.startMa);
  if (startCompare != 0) {
    return startCompare;
  }
  final displayPriorityCompare = a.displayPriority.compareTo(b.displayPriority);
  if (displayPriorityCompare != 0) {
    return displayPriorityCompare;
  }
  return a.label.compareTo(b.label);
}

(double, double) _focusedEffectiveBounds({
  required Clade clade,
  required Map<String, Clade> allById,
}) {
  var start = clade.startMa;
  var end = clade.endMa;
  if (start > end && (start - end).abs() > 0.0001) {
    return (start, end);
  }
  final visited = <String>{clade.id};
  var cursor = clade;
  while (cursor.parentId != null) {
    final parent = allById[cursor.parentId!];
    if (parent == null || !visited.add(parent.id)) {
      break;
    }
    if (parent.startMa > parent.endMa &&
        (parent.startMa - parent.endMa).abs() > 0.0001) {
      return (parent.startMa, parent.endMa);
    }
    cursor = parent;
  }
  return (start, end);
}
