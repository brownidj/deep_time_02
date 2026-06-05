import 'package:flutter/material.dart';
import 'package:deep_time_2/domain/models/clade.dart';
import 'package:deep_time_2/ui/theme/deep_time_palette.dart';

class CladeBar extends StatelessWidget {
  const CladeBar({
    super.key,
    required this.clade,
    required this.width,
    required this.height,
    required this.isDimmed,
    required this.isHighlighted,
  });

  final Clade clade;
  final double width;
  final double height;
  final bool isDimmed;
  final bool isHighlighted;

  static const Color baseColor = Color(0xFF4DB6AC);
  static const Color highlightColor = Color(0xFFFFD978);
  static const Color textColor = DeepTimePalette.darkLabel;

  @override
  Widget build(BuildContext context) {
    final color = isHighlighted ? highlightColor : baseColor;
    final opacity = isDimmed ? 0.35 : 1.0;
    final labelStyle = Theme.of(context).textTheme.labelSmall?.copyWith(
      color: textColor,
      fontWeight: FontWeight.w600,
    );
    return Opacity(
      opacity: opacity,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(height / 2),
          border: Border.all(color: DeepTimePalette.frameBorder),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8),
        alignment: Alignment.centerLeft,
        child: Text(
          clade.label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: labelStyle,
        ),
      ),
    );
  }
}
