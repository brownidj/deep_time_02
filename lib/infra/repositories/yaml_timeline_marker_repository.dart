import 'package:flutter/services.dart';
import 'package:deep_time_2/domain/models/timeline_marker_catalog.dart';
import 'package:deep_time_2/domain/repositories/timeline_marker_repository.dart';
import 'package:yaml/yaml.dart';

class YamlTimelineMarkerRepository implements TimelineMarkerRepository {
  YamlTimelineMarkerRepository({required this.assetPath});

  final String assetPath;

  @override
  Future<TimelineMarkerCatalog> fetchMarkers() async {
    final yamlText = await rootBundle.loadString(assetPath);
    final document = loadYaml(yamlText) as YamlMap;
    final events = _readEvents(document['events']);
    final extinctions = _readExtinctions(document['extinctions']);
    return TimelineMarkerCatalog(events: events, extinctions: extinctions);
  }

  List<TimelineEventDefinition> _readEvents(Object? value) {
    if (value is! YamlList) {
      return const [];
    }
    return value.whereType<YamlMap>().map((event) {
      final label = _requireString(event, 'label');
      final shortLabel = _requireString(event, 'short_label');
      final type = _requireString(event, 'type');
      final kind = _parseEventKind(type);
      final startMa = _readDouble(event['start_ma']);
      final endMa = _readDouble(event['end_ma']);
      final atMa = _readDouble(event['at_ma']);
      final explanation = _readString(event['explanation']);
      return TimelineEventDefinition(
        label: label,
        shortLabel: shortLabel,
        kind: kind,
        explanation: explanation,
        startMa: startMa,
        endMa: endMa,
        atMa: atMa,
      );
    }).toList();
  }

  List<ExtinctionDefinition> _readExtinctions(Object? value) {
    if (value is! YamlList) {
      return const [];
    }
    return value.whereType<YamlMap>().map((extinction) {
      final label = _requireString(extinction, 'label');
      final shortLabel = _requireString(extinction, 'short_label');
      final isMajor = _readBool(extinction['is_major']) ?? false;
      final anchorMap = extinction['anchor'];
      if (anchorMap is! YamlMap) {
        throw StateError('Missing anchor for extinction "$label".');
      }
      final anchorType = _requireString(anchorMap, 'type');
      final anchor = _parseAnchor(anchorType, anchorMap);
      final explanation = _readString(extinction['explanation']);
      return ExtinctionDefinition(
        label: label,
        shortLabel: shortLabel,
        isMajor: isMajor,
        anchor: anchor,
        explanation: explanation,
      );
    }).toList();
  }

  TimelineEventKind _parseEventKind(String value) {
    switch (value.trim().toLowerCase()) {
      case 'bar':
        return TimelineEventKind.bar;
      case 'point':
        return TimelineEventKind.point;
    }
    throw StateError('Unknown event type "$value".');
  }

  ExtinctionAnchor _parseAnchor(String value, YamlMap anchor) {
    switch (value.trim().toLowerCase()) {
      case 'period':
        return ExtinctionAnchor(
          type: ExtinctionAnchorType.period,
          label: _requireString(anchor, 'label'),
        );
      case 'stage':
        return ExtinctionAnchor(
          type: ExtinctionAnchorType.stage,
          label: _requireString(anchor, 'label'),
        );
      case 'ma':
        return ExtinctionAnchor(
          type: ExtinctionAnchorType.ma,
          ma: _requireDouble(anchor, 'ma'),
        );
    }
    throw StateError('Unknown anchor type "$value".');
  }

  String _requireString(YamlMap map, String key) {
    final value = map[key];
    if (value is String && value.trim().isNotEmpty) {
      return value;
    }
    throw StateError('Missing required string "$key".');
  }

  String? _readString(Object? value) {
    if (value is String) {
      final trimmed = value.trim();
      return trimmed.isEmpty ? null : trimmed;
    }
    return null;
  }

  double _requireDouble(YamlMap map, String key) {
    final value = _readDouble(map[key]);
    if (value == null) {
      throw StateError('Missing required number "$key".');
    }
    return value;
  }

  double? _readDouble(Object? value) {
    if (value is num) {
      return value.toDouble();
    }
    if (value is String) {
      return double.tryParse(value);
    }
    return null;
  }

  bool? _readBool(Object? value) {
    if (value is bool) {
      return value;
    }
    if (value is String) {
      switch (value.trim().toLowerCase()) {
        case 'true':
          return true;
        case 'false':
          return false;
      }
    }
    return null;
  }
}
