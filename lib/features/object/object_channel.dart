import 'package:flutter/services.dart';
import 'package:google_ml_kit/google_ml_kit.dart' show InputImage;

/// A label the classifier attached to a detected object.
class ThingLabel {
  const ThingLabel({required this.text, required this.confidence, required this.index});

  final String text;

  /// By convention 0..1, though the range depends on the classifier.
  final double confidence;
  final int index;
}

/// One tracked object in a frame.
class DetectedThing {
  const DetectedThing({
    required this.boundingBox,
    required this.labels,
    required this.trackingId,
  });

  final Rect boundingBox;
  final List<ThingLabel> labels;
  final int? trackingId;

  ThingLabel? get top => labels.isEmpty ? null : labels.first;
  double get area => boundingBox.width * boundingBox.height;
}

/// Speaks to the ML Kit object-detector plugin over its method channel.
///
/// Same reason as the ink module: the published wrapper assigns the platform's
/// `confidence` straight into a non-nullable `double`, so a label whose
/// confidence crosses the channel as an int throws mid-loop and discards every
/// object in the frame. On a live stream that fails every frame, not one.
/// Parsing here with `num.toDouble()` keeps the results.
class ObjectDetectorChannel {
  const ObjectDetectorChannel(this.id);

  static const _channel = MethodChannel('google_mlkit_object_detector');

  final String id;

  Future<List<DetectedThing>> detect({
    required InputImage image,
    required Map<String, dynamic> options,
  }) async {
    final reply = await _channel.invokeMethod<dynamic>(
      'vision#startObjectDetector',
      <String, dynamic>{
        'id': id,
        'imageData': image.toJson(),
        'options': options,
      },
    );
    if (reply is! List) return const [];

    final things = <DetectedThing>[];
    for (final row in reply) {
      if (row is! Map) continue;
      final rect = row['rect'];
      if (rect is! Map) continue;
      things.add(
        DetectedThing(
          boundingBox: Rect.fromLTRB(
            _d(rect['left']),
            _d(rect['top']),
            _d(rect['right']),
            _d(rect['bottom']),
          ),
          trackingId: (row['trackingId'] as num?)?.toInt(),
          labels: _labels(row['labels']),
        ),
      );
    }
    return things;
  }

  static List<ThingLabel> _labels(Object? raw) {
    if (raw is! List) return const [];
    final labels = <ThingLabel>[];
    for (final row in raw) {
      if (row is! Map) continue;
      final text = row['text'];
      if (text is! String || text.isEmpty) continue;
      labels.add(
        ThingLabel(
          text: text,
          confidence: (row['confidence'] as num?)?.toDouble() ?? 0,
          index: (row['index'] as num?)?.toInt() ?? -1,
        ),
      );
    }
    return labels;
  }

  static double _d(Object? v) => (v as num?)?.toDouble() ?? 0;

  Future<void> close() => _channel.invokeMethod<void>(
        'vision#closeObjectDetector',
        <String, dynamic>{'id': id},
      );
}
