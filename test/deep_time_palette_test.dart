import 'dart:ui' show Color;
import 'package:flutter_test/flutter_test.dart';
import 'package:deep_time_2/domain/models/timeline_palette.dart';
import 'package:deep_time_2/ui/theme/deep_time_palette.dart';

void main() {
  TimelinePalette buildPalette() {
    final phanerozoic = divisionColorKey(
      name: 'Phanerozoic',
      rank: 'eon',
      parentKey: null,
    );
    final mesozoic = divisionColorKey(
      name: 'Mesozoic',
      rank: 'era',
      parentKey: phanerozoic,
    );
    final jurassic = divisionColorKey(
      name: 'Jurassic',
      rank: 'period',
      parentKey: mesozoic,
    );
    final mississippian = divisionColorKey(
      name: 'Mississippian',
      rank: 'epoch',
      parentKey: divisionColorKey(
        name: 'Carboniferous',
        rank: 'period',
        parentKey: divisionColorKey(
          name: 'Paleozoic',
          rank: 'era',
          parentKey: phanerozoic,
        ),
      ),
    );
    return TimelinePalette(
      divisionColors: {
        phanerozoic: 0xFF8EC7DC,
        mesozoic: 0xFF69B1CF,
        jurassic: 0xFF56A7CD,
        mississippian: 0xFF9BB08F,
      },
    );
  }

  test('palette anchors map to expected era transition colors', () {
    final palette = DeepTimePalette(buildPalette());
    expect(
      palette.colorForKey(
        divisionColorKey(name: 'Phanerozoic', rank: 'eon', parentKey: null),
      ),
      const Color(0xFF8EC7DC),
    );
    expect(
      palette.colorForKey(
        divisionColorKey(
          name: 'Mesozoic',
          rank: 'era',
          parentKey: divisionColorKey(
            name: 'Phanerozoic',
            rank: 'eon',
            parentKey: null,
          ),
        ),
      ),
      const Color(0xFF69B1CF),
    );
    expect(
      palette.colorForKey(
        divisionColorKey(
          name: 'Jurassic',
          rank: 'period',
          parentKey: divisionColorKey(
            name: 'Mesozoic',
            rank: 'era',
            parentKey: divisionColorKey(
              name: 'Phanerozoic',
              rank: 'eon',
              parentKey: null,
            ),
          ),
        ),
      ),
      const Color(0xFF56A7CD),
    );
    expect(
      palette.colorForKey(
        divisionColorKey(
          name: 'Mississippian',
          rank: 'epoch',
          parentKey: divisionColorKey(
            name: 'Carboniferous',
            rank: 'period',
            parentKey: divisionColorKey(
              name: 'Paleozoic',
              rank: 'era',
              parentKey: divisionColorKey(
                name: 'Phanerozoic',
                rank: 'eon',
                parentKey: null,
              ),
            ),
          ),
        ),
      ),
      const Color(0xFF9BB08F),
    );
  });
}
