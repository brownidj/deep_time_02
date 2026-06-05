import 'package:flutter/material.dart';
import 'package:deep_time_2/domain/models/geologic_division.dart';
import 'package:deep_time_2/ui/widgets/time_range_format.dart';

class DivisionList extends StatelessWidget {
  const DivisionList({
    super.key,
    required this.divisions,
    required this.selectedDivision,
    required this.onSelected,
  });

  final List<GeologicDivision> divisions;
  final GeologicDivision? selectedDivision;
  final ValueChanged<GeologicDivision> onSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF1E2A2F),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Geological Time',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: ListView.separated(
              itemCount: divisions.length,
              separatorBuilder: (context, index) =>
                  const Divider(height: 1, color: Color(0xFF31444C)),
              itemBuilder: (context, index) {
                final division = divisions[index];
                final selected = division.id == selectedDivision?.id;
                return Material(
                  color: selected
                      ? const Color(0xFF2F3C40)
                      : Colors.transparent,
                  child: ListTile(
                    title: Text(
                      division.name,
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: selected
                            ? FontWeight.w600
                            : FontWeight.w500,
                      ),
                    ),
                    subtitle: Text(
                      '${division.rank.name.toUpperCase()} · '
                      '${formatTimeRange(
                        startMa: division.startMa,
                        endMa: division.endMa,
                        startPrecision: 2,
                        endPrecision: 2,
                        durationPrecision: 2,
                      )}',
                      style: const TextStyle(color: Color(0xFFA4B3B8)),
                    ),
                    onTap: () => onSelected(division),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
