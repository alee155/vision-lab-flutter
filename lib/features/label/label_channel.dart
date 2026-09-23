import 'package:flutter/services.dart';
import 'package:google_ml_kit/google_ml_kit.dart' show InputImage;

/// One label the model attached to the whole image.
class ImageTag {
  const ImageTag({required this.text, required this.confidence, required this.index});

  final String text;

  /// 0..1 for the base model.
  final double confidence;
  final int index;
}

/// Speaks to the ML Kit image-labeler plugin over its method channel.
///
/// Third module, same defect: the published wrapper assigns the platform's
/// `confidence` straight into a non-nullable `double`, so a label whose
/// confidence crosses the channel as an int throws and discards every label in
/// the frame. Parsing here with `num.toDouble()` keeps them.
class ImageLabelerChannel {
  const ImageLabelerChannel(this.id);

  static const _channel = MethodChannel('google_mlkit_image_labeler');

  final String id;

  Future<List<ImageTag>> label({
    required InputImage image,
    required double confidenceThreshold,
  }) async {
    final reply = await _channel.invokeMethod<dynamic>(
      'vision#startImageLabelDetector',
      <String, dynamic>{
        'id': id,
        'imageData': image.toJson(),
        'options': <String, dynamic>{
          'confidenceThreshold': confidenceThreshold,
          'type': 'base',
        },
      },
    );
    if (reply is! List) return const [];

    final tags = <ImageTag>[];
    for (final row in reply) {
      if (row is! Map) continue;
      // The platform sends the label under `text`, not `label`.
      final text = row['text'];
      if (text is! String || text.isEmpty) continue;
      tags.add(
        ImageTag(
          text: text,
          confidence: (row['confidence'] as num?)?.toDouble() ?? 0,
          index: (row['index'] as num?)?.toInt() ?? -1,
        ),
      );
    }
    // The model returns best-first, but a custom model need not, so be sure.
    tags.sort((a, b) => b.confidence.compareTo(a.confidence));
    return tags;
  }

  Future<void> close() => _channel.invokeMethod<void>(
        'vision#closeImageLabelDetector',
        <String, dynamic>{'id': id},
      );
}
