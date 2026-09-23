import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:face_reco/design/palette.dart';
import 'package:face_reco/design/widgets/controls.dart';
import 'package:face_reco/design/widgets/gauges.dart';

/// Renders the live instruments to a golden so their geometry can be reviewed
/// without launching the app.
Future<void> _loadPoppins() async {
  final loader = FontLoader('Poppins');
  for (final weight in ['Regular', 'Medium', 'SemiBold', 'Bold']) {
    loader.addFont(rootBundle.load('assets/fonts/Poppins-$weight.ttf'));
  }
  await loader.load();
}

void main() {
  testWidgets('instruments render', (tester) async {
    await _loadPoppins();
    await tester.binding.setSurfaceSize(const Size(390, 520));

    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(brightness: Brightness.dark, fontFamily: 'Poppins'),
        home: Scaffold(
          backgroundColor: Ground.sheet,
          body: Padding(
            padding: const EdgeInsets.all(Gap.lg),
            child: Column(
              children: [
                Row(
                  children: [
                    const Expanded(child: StatTile(
                      label: 'Smile', value: '94%', fraction: 0.94)),
                    const SizedBox(width: Gap.sm + 2),
                    const Expanded(child: StatTile(
                      label: 'Left eye', value: '98%', fraction: 0.98)),
                    const SizedBox(width: Gap.sm + 2),
                    Expanded(child: StatTile(
                      label: 'Right eye', value: '11%', fraction: 0.11,
                      color: Brand.amber)),
                  ],
                ),
                const SizedBox(height: Gap.md + 2),
                const PoseStrip(yaw: -12.4, pitch: 3.1, roll: 0.8),
                const SizedBox(height: Gap.md + 2),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Ground.raised,
                    borderRadius: BorderRadius.circular(Radii.card),
                    border: Border.all(color: Ground.line),
                  ),
                  child: TraceChart(
                    samples: [
                      22, 25, 24, 31, 27, 23, 22, 26, 34, 29, 24, 23,
                      21, 25, 28, 41, 33, 27, 25, 24, 23, 26, 30, 27,
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle(const Duration(seconds: 1));
    await expectLater(
      find.byType(Scaffold),
      matchesGoldenFile('goldens/instruments.png'),
    );
  });
}
