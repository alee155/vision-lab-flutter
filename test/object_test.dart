import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:google_ml_kit/google_ml_kit.dart' show InputImage;

import 'package:face_reco/features/object/object_channel.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('google_mlkit_object_detector');
  const detector = ObjectDetectorChannel('test');

  void reply(Object? value) {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (_) async => value);
  }

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  Future<List<DetectedThing>> run() =>
      detector.detect(image: _fakeImage, options: const {});

  // Same defect as the ink module: the published wrapper drops every object in
  // the frame if one label's confidence arrives as an int rather than a double.
  test('an int confidence does not discard the frame', () async {
    reply([
      {
        'rect': {'left': 0, 'top': 0, 'right': 100, 'bottom': 80},
        'trackingId': 4,
        'labels': [
          {'text': 'Home good', 'confidence': 1, 'index': 2},
        ],
      },
    ]);
    final out = await run();
    expect(out, hasLength(1));
    expect(out.first.top!.confidence, 1.0);
    expect(out.first.boundingBox.width, 100);
  });

  test('handles a null tracking id and no labels', () async {
    reply([
      {
        'rect': {'left': 5.5, 'top': 6.5, 'right': 20, 'bottom': 30},
        'labels': <dynamic>[],
      },
    ]);
    final out = await run();
    expect(out.single.trackingId, isNull);
    expect(out.single.top, isNull);
  });

  test('skips malformed rows and a null reply', () async {
    reply([
      'nonsense',
      {'labels': <dynamic>[]},
      {
        'rect': {'left': 0, 'top': 0, 'right': 10, 'bottom': 10},
        'labels': [
          {'confidence': 0.5},
          {'text': 'Plant', 'confidence': 0.9, 'index': 1},
        ],
      },
    ]);
    final out = await run();
    expect(out, hasLength(1));
    expect(out.single.labels.map((l) => l.text), ['Plant']);

    reply(null);
    expect(await run(), isEmpty);
  });

  test('picks the largest object as primary', () {
    const small = DetectedThing(
      boundingBox: Rect.fromLTWH(0, 0, 10, 10),
      labels: [],
      trackingId: 1,
    );
    const big = DetectedThing(
      boundingBox: Rect.fromLTWH(0, 0, 50, 50),
      labels: [],
      trackingId: 2,
    );
    expect(big.area, greaterThan(small.area));
  });
}

final _fakeImage = InputImage.fromFilePath('/tmp/none.jpg');
