import 'package:flutter/material.dart';
import 'package:deep_time_2/ui/theme/deep_time_palette.dart';

class TimelineHeader extends StatelessWidget {
  const TimelineHeader({
    super.key,
    required this.onSettings,
    required this.scale,
    required this.onScaleChanged,
    required this.minScale,
    required this.maxScale,
  });

  final VoidCallback onSettings;
  final double scale;
  final ValueChanged<double> onScaleChanged;
  final double minScale;
  final double maxScale;

  String _scaleLabel() {
    final offset = minScale - 1.0;
    final displayScale = (scale - offset).clamp(1.0, maxScale - offset);
    return displayScale.toStringAsFixed(1);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Image.asset(
            'assets/logos/desktop_logo.png',
            width: 36,
            height: 36,
            fit: BoxFit.contain,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Deep Time 2',
              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                fontWeight: FontWeight.w800,
                color: DeepTimePalette.panelText,
              ),
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 220,
            child: Row(
              children: [
                Text(
                  'Scale',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: DeepTimePalette.panelText,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Slider(
                    min: minScale,
                    max: maxScale,
                    divisions: 12,
                    value: scale.clamp(minScale, maxScale),
                    label: _scaleLabel(),
                    onChanged: onScaleChanged,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          IconButton(
            tooltip: 'Settings',
            onPressed: onSettings,
            icon: const Icon(Icons.settings),
            color: DeepTimePalette.panelText,
          ),
        ],
      ),
    );
  }
}
