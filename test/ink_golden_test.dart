import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:face_reco/features/ink/ink_channel.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:face_reco/design/palette.dart';
import 'package:face_reco/features/ink/ink_lab.dart';
import 'package:face_reco/features/ink/widgets/ink_sections.dart';

Future<void> _loadPoppins() async {
  final loader = FontLoader('Poppins');
  for (final weight in ['Regular', 'Medium', 'SemiBold', 'Bold']) {
    loader.addFont(rootBundle.load('assets/fonts/Poppins-$weight.ttf'));
  }
  await loader.load();
}

void main() {
  testWidgets('ink sections lay out', (tester) async {
    await _loadPoppins();
    await tester.binding.setSurfaceSize(const Size(390, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final lab = InkLab();
    addTearDown(lab.dispose);

    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(brightness: Brightness.dark, fontFamily: 'Poppins'),
        home: Scaffold(
          backgroundColor: Ground.base,
          body: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: Gap.lg),
            child: InkSections(lab: lab),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 400));

    for (final section in ['Result', 'Ink', 'Model']) {
      expect(find.text(section), findsOneWidget, reason: '$section missing');
    }
    expect(find.text('Nothing read yet'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await expectLater(
      find.byType(InkSections),
      matchesGoldenFile('goldens/ink_sections.png'),
    );
  });

  _channelParsingTests();

  group('InkLab', () {
    test('starts empty and cannot recognise', () {
      final lab = InkLab();
      addTearDown(lab.dispose);
      expect(lab.isEmpty, isTrue);
      expect(lab.canRecognise, isFalse);
      expect(lab.strokeCount, 0);
    });

    test('captures strokes and drops sub-pixel jitter', () {
      final lab = InkLab();
      addTearDown(lab.dispose);

      lab.penDown(const Offset(10, 10));
      lab.penMove(const Offset(10.4, 10.2)); // below the 1.5px threshold
      lab.penMove(const Offset(40, 40));
      lab.penUp();

      expect(lab.strokeCount, 1);
      expect(lab.pointCount, 2);
      expect(lab.isEmpty, isFalse);
    });

    test('undo removes the last stroke, clear removes everything', () {
      final lab = InkLab();
      addTearDown(lab.dispose);

      for (var i = 0; i < 3; i++) {
        lab.penDown(Offset(i * 20, 0));
        lab.penMove(Offset(i * 20 + 30, 30));
        lab.penUp();
      }
      expect(lab.strokeCount, 3);

      lab.undo();
      expect(lab.strokeCount, 2);

      lab.clear();
      expect(lab.isEmpty, isTrue);
      expect(lab.pointCount, 0);
    });
  });
}

// Regression guard for the bug that made recognition look broken: the
// published wrapper assigns the platform's score straight into a double, so an
// int score threw and discarded every candidate. Our parser must not.
void _channelParsingTests() {
  group('InkRecognizerChannel parsing', () {
    const channel = MethodChannel('google_mlkit_digital_ink_recognizer');
    final recognizer = const InkRecognizerChannel('test');

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
    });

    void reply(Object? value) {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (_) async => value);
    }

    test('accepts an int score without losing the candidate', () async {
      reply([
        {'text': 'Ali', 'score': 335},
        {'text': 'Abbas', 'score': 330.122},
      ]);
      final out = await recognizer.recognize(model: 'en-US', strokes: []);
      expect(out.map((c) => c.text), ['Ali', 'Abbas']);
      expect(out.first.score, 335.0);
    });

    test('survives a missing score and a null reply', () async {
      reply([
        {'text': 'Ali'},
      ]);
      expect((await recognizer.recognize(model: 'en-US', strokes: [])).first.score, 0);

      reply(null);
      expect(await recognizer.recognize(model: 'en-US', strokes: []), isEmpty);
    });

    test('skips malformed rows rather than throwing', () async {
      reply([
        'nonsense',
        {'score': 1.0},
        {'text': '', 'score': 1.0},
        {'text': 'Ali', 'score': 2},
      ]);
      final out = await recognizer.recognize(model: 'en-US', strokes: []);
      expect(out.map((c) => c.text), ['Ali']);
    });
  });
}
