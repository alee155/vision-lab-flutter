import 'package:flutter/painting.dart';
import 'package:google_ml_kit/google_ml_kit.dart';

enum FrameSource { live, still }

/// One completed detection pass, paired with everything the overlay needs to
/// place it on screen. Immutable so the painter can cheaply diff frames.
class FaceFrame {
  const FaceFrame({
    required this.faces,
    required this.sourceSize,
    required this.latencyMs,
    required this.mirrored,
    required this.source,
  });

  static const empty = FaceFrame(
    faces: [],
    sourceSize: Size.zero,
    latencyMs: 0,
    mirrored: false,
    source: FrameSource.live,
  );

  final List<Face> faces;

  /// Upright size of the image the coordinates belong to.
  final Size sourceSize;
  final double latencyMs;
  final bool mirrored;
  final FrameSource source;

  Face? get primary {
    if (faces.isEmpty) return null;
    // The largest face is the subject; everything behind it is background.
    return faces.reduce((a, b) {
      final areaA = a.boundingBox.width * a.boundingBox.height;
      final areaB = b.boundingBox.width * b.boundingBox.height;
      return areaB > areaA ? b : a;
    });
  }

  BoxFit get fit => source == FrameSource.live ? BoxFit.cover : BoxFit.contain;
}
