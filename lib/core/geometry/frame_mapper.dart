import 'dart:math' as math;

import 'package:flutter/painting.dart';
import 'package:google_ml_kit/google_ml_kit.dart' show InputImageRotation;

/// Maps ML Kit detection coordinates (which live in the *upright* source image
/// space) onto the widget canvas the preview is painted into.
///
/// Every overlay in this app goes through here. Getting it wrong is the single
/// most common reason ML Kit demos show boxes that drift off the subject.
class FrameMapper {
  const FrameMapper._({
    required this.scale,
    required this.dx,
    required this.dy,
    required this.canvasWidth,
    required this.mirror,
  });

  final double scale;
  final double dx;
  final double dy;
  final double canvasWidth;
  final bool mirror;

  static const identity = FrameMapper._(
    scale: 1,
    dx: 0,
    dy: 0,
    canvasWidth: 0,
    mirror: false,
  );

  /// [source] must already be upright — see [uprightSize]. [fit] should match
  /// the fit used to lay out the preview itself, or the overlay will drift.
  factory FrameMapper({
    required Size source,
    required Size canvas,
    required BoxFit fit,
    bool mirror = false,
  }) {
    if (source.isEmpty || canvas.isEmpty) return identity;
    final sx = canvas.width / source.width;
    final sy = canvas.height / source.height;
    final scale = fit == BoxFit.cover ? math.max(sx, sy) : math.min(sx, sy);
    return FrameMapper._(
      scale: scale,
      dx: (canvas.width - source.width * scale) / 2,
      dy: (canvas.height - source.height * scale) / 2,
      canvasWidth: canvas.width,
      mirror: mirror,
    );
  }

  Offset point(double x, double y) {
    final px = x * scale + dx;
    return Offset(mirror ? canvasWidth - px : px, y * scale + dy);
  }

  /// [Rect.fromPoints] normalises the corners, so a mirrored rect stays valid.
  Rect rect(Rect r) => Rect.fromPoints(
        point(r.left, r.top),
        point(r.right, r.bottom),
      );

  double length(double v) => v * scale;
}

/// Normalises a raw buffer size to the orientation ML Kit reports results in.
///
/// Android delivers a landscape sensor buffer plus a 90°/270° rotation, so the
/// upright frame is the transposed size. iOS delivers an already-upright buffer
/// while still reporting a 90° sensor orientation — hence the shape check
/// rather than a blind transpose.
///
/// Assumes a portrait-locked UI, which [SensoriumApp] enforces.
Size uprightSize(Size raw, InputImageRotation rotation) {
  final quarterTurn = rotation == InputImageRotation.rotation90deg ||
      rotation == InputImageRotation.rotation270deg;
  if (!quarterTurn || raw.height >= raw.width) return raw;
  return Size(raw.height, raw.width);
}
