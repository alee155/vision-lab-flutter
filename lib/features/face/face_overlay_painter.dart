import 'dart:math' as math;

import 'package:flutter/rendering.dart';
import 'package:google_ml_kit/google_ml_kit.dart';

import '../../core/geometry/frame_mapper.dart';
import '../../design/palette.dart';
import 'face_config.dart';
import 'face_frame.dart';

/// Draws detections in the app's own language: rounded corner brackets rather
/// than a hard rectangle, a thin crimson mesh, white landmark nodes, and a soft
/// bloom behind the subject that ties the overlay to the rest of the UI.
class FaceOverlayPainter extends CustomPainter {
  const FaceOverlayPainter({required this.frame, required this.config});

  final FaceFrame frame;
  final FaceConfig config;

  static const _closed = <FaceContourType>{
    FaceContourType.face,
    FaceContourType.leftEye,
    FaceContourType.rightEye,
  };

  @override
  void paint(Canvas canvas, Size size) {
    if (frame.sourceSize.isEmpty || frame.faces.isEmpty) return;

    final mapper = FrameMapper(
      source: frame.sourceSize,
      canvas: size,
      fit: frame.fit,
      mirror: frame.mirrored,
    );

    final primary = frame.primary;
    for (final face in frame.faces) {
      final box = mapper.rect(face.boundingBox);
      if (box.isEmpty) continue;
      final isPrimary = identical(face, primary);

      if (isPrimary) _bloom(canvas, box);
      if (config.drawMesh) _mesh(canvas, mapper, face, isPrimary);
      if (config.drawLandmarks) _landmarks(canvas, mapper, face, isPrimary);
      _brackets(canvas, box, isPrimary);
    }
  }

  /// A red halo behind the subject — the same bloom the rest of the app uses,
  /// anchored to something real.
  void _bloom(Canvas canvas, Rect box) {
    final rect = Rect.fromCenter(
      center: box.center,
      width: box.width * 2.6,
      height: box.height * 2.2,
    );
    canvas.drawOval(
      rect,
      Paint()
        ..shader = RadialGradient(
          colors: [
            Brand.red.withValues(alpha: 0.16),
            Brand.red.withValues(alpha: 0.05),
            Brand.red.withValues(alpha: 0),
          ],
          stops: const [0, 0.55, 1],
        ).createShader(rect),
    );
  }

  void _mesh(Canvas canvas, FrameMapper mapper, Face face, bool primary) {
    final stroke = Paint()
      ..color = Brand.redLift.withValues(alpha: primary ? 0.85 : 0.4)
      ..strokeWidth = 1.3
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round;
    final outline = Paint.from(stroke)
      ..color = Brand.redLift.withValues(alpha: primary ? 0.32 : 0.16);

    for (final entry in face.contours.entries) {
      final points = entry.value?.points;
      if (points == null || points.length < 2) continue;
      final path = Path();
      for (var i = 0; i < points.length; i++) {
        final p = mapper.point(points[i].x.toDouble(), points[i].y.toDouble());
        i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
      }
      if (_closed.contains(entry.key)) path.close();
      canvas.drawPath(path, entry.key == FaceContourType.face ? outline : stroke);
    }
  }

  void _landmarks(Canvas canvas, FrameMapper mapper, Face face, bool primary) {
    final core = Paint()..color = const Color(0xFFFFFFFF).withValues(alpha: primary ? 1 : 0.5);
    for (final landmark in face.landmarks.values) {
      if (landmark == null) continue;
      final p = mapper.point(
        landmark.position.x.toDouble(),
        landmark.position.y.toDouble(),
      );
      canvas.drawCircle(p, 2.6, core);
    }
  }

  /// Four rounded corner brackets. Radius and stroke match the card language,
  /// so the overlay belongs to the same product as the rest of the screen.
  void _brackets(Canvas canvas, Rect box, bool primary) {
    final pad = box.shortestSide * 0.06;
    final r = Rect.fromLTRB(
      box.left - pad,
      box.top - pad,
      box.right + pad,
      box.bottom + pad,
    );
    final arm = math.min(r.shortestSide * 0.26, 34.0);
    const radius = 10.0;

    final paint = Paint()
      ..color = primary ? Brand.red : const Color(0x66FFFFFF)
      ..strokeWidth = primary ? 2.8 : 1.6
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path()
      ..moveTo(r.left, r.top + arm)
      ..lineTo(r.left, r.top + radius)
      ..arcToPoint(Offset(r.left + radius, r.top), radius: const Radius.circular(radius))
      ..lineTo(r.left + arm, r.top)
      ..moveTo(r.right - arm, r.top)
      ..lineTo(r.right - radius, r.top)
      ..arcToPoint(Offset(r.right, r.top + radius), radius: const Radius.circular(radius))
      ..lineTo(r.right, r.top + arm)
      ..moveTo(r.right, r.bottom - arm)
      ..lineTo(r.right, r.bottom - radius)
      ..arcToPoint(Offset(r.right - radius, r.bottom), radius: const Radius.circular(radius))
      ..lineTo(r.right - arm, r.bottom)
      ..moveTo(r.left + arm, r.bottom)
      ..lineTo(r.left + radius, r.bottom)
      ..arcToPoint(Offset(r.left, r.bottom - radius), radius: const Radius.circular(radius))
      ..lineTo(r.left, r.bottom - arm);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(FaceOverlayPainter old) =>
      !identical(old.frame, frame) || !identical(old.config, config);
}
