import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_ml_kit/google_ml_kit.dart' show InputImage;

import 'package:face_reco/features/label/label_channel.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('google_mlkit_image_labeler');
  const labeler = ImageLabelerChannel('test');
  final image = InputImage.fromFilePath('/tmp/none.jpg');

  void reply(Object? value) {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (_) async => value);
  }

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  Future<List<ImageTag>> run() =>
      labeler.label(image: image, confidenceThreshold: 0.5);

  // The third module with the same underlying defect: an int confidence in the
  // published wrapper throws and discards every label in the frame.
  test('an int confidence does not discard the labels', () async {
    reply([
      {'text': 'Cat', 'confidence': 1, 'index': 100},
      {'text': 'Whiskers', 'confidence': 0.71, 'index': 101},
    ]);
    final out = await run();
    expect(out.map((t) => t.text), ['Cat', 'Whiskers']);
    expect(out.first.confidence, 1.0);
  });

  test('sorts best first even if the platform does not', () async {
    reply([
      {'text': 'Fur', 'confidence': 0.4, 'index': 1},
      {'text': 'Cat', 'confidence': 0.9, 'index': 2},
      {'text': 'Pet', 'confidence': 0.6, 'index': 3},
    ]);
    expect((await run()).map((t) => t.text), ['Cat', 'Pet', 'Fur']);
  });

  test('skips malformed rows, survives a null reply', () async {
    reply([
      'nonsense',
      {'confidence': 0.9},
      {'text': '', 'confidence': 0.9},
      {'text': 'Cat', 'confidence': 0.9},
    ]);
    final out = await run();
    expect(out.map((t) => t.text), ['Cat']);
    expect(out.single.index, -1);

    reply(null);
    expect(await run(), isEmpty);
  });
}
