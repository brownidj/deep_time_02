import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:deep_time_2/domain/models/geologic_division.dart';
import 'package:deep_time_2/domain/models/geologic_rank.dart';
import 'package:deep_time_2/ui/widgets/division_list.dart';

void main() {
  testWidgets('DivisionList renders divisions', (WidgetTester tester) async {
    final divisions = [
      const GeologicDivision(
        id: 1,
        name: 'Cenozoic',
        rank: GeologicRank.era,
        startMa: 66.0,
        endMa: 0.0,
        parentId: null,
      ),
      const GeologicDivision(
        id: 2,
        name: 'Mesozoic',
        rank: GeologicRank.era,
        startMa: 252.17,
        endMa: 66.0,
        parentId: null,
      ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: DivisionList(
          divisions: divisions,
          selectedDivision: divisions.first,
          onSelected: (_) {},
        ),
      ),
    );

    expect(find.text('Geological Time'), findsOneWidget);
    expect(find.text('Cenozoic'), findsOneWidget);
    expect(find.text('Mesozoic'), findsOneWidget);
  });
}
