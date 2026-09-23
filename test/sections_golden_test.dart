import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:face_reco/design/palette.dart';
import 'package:face_reco/features/face/face_pipeline.dart';
import 'package:face_reco/features/face/widgets/face_sections.dart';

/// Renders the readout sections with nothing detected, so every section, its
/// empty state and the overall layout can be reviewed without a device.
Future<void> _loadPoppins() async {
  final loader = FontLoader('Poppins');
  for (final weight in ['Regular', 'Medium', 'SemiBold', 'Bold']) {
    loader.addFont(rootBundle.load('assets/fonts/Poppins-$weight.ttf'));
  }
  await loader.load();
}

void main() {
  testWidgets('face sections lay out', (tester) async {
    await _loadPoppins();
    await tester.binding.setSurfaceSize(const Size(390, 1250));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final lab = FaceLab();
    addTearDown(lab.dispose);

    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(brightness: Brightness.dark, fontFamily: 'Poppins'),
        home: Scaffold(
          backgroundColor: Ground.base,
          body: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: Gap.lg),
            child: FaceSections(lab: lab),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 400));

    for (final section in ['Signals', 'Head pose', 'Session', 'Detection', 'Source']) {
      expect(find.text(section), findsOneWidget, reason: '$section missing');
    }
    expect(tester.takeException(), isNull);

    await expectLater(
      find.byType(FaceSections),
      matchesGoldenFile('goldens/face_sections.png'),
    );
  });
}
