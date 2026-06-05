import 'package:deep_time_2/domain/models/clade_display_group.dart';

abstract class CladeDisplayGroupRepository {
  Future<List<CladeDisplayGroup>> fetchDisplayGroups();
}
