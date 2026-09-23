import 'dart:math' as math;

import 'package:flutter/rendering.dart';

import '../../core/geometry/frame_mapper.dart';
import '../../design/palette.dart';
import 'object_channel.dart';
import 'object_lab.dart';

/// Draws tracked objects: rounded corner brackets matching the card language,
/// with a label chip carrying the classifier's answer.
class ObjectOverlayPainter extends CustomPainter {
  const ObjectOverlayPainter({required this.frame});

  final ObjectFrame frame;

  @override
  void paint(Canvas canvas, Size size) {
    if (frame.sourceSize.isEmpty || frame.things.isEmpty) return;

    final mapper = FrameMapper(
      source: frame.sourceSize,
      canvas: size,
      fit: frame.fit,
      mirror: frame.mirrored,
    );

    final primary = frame.primary;
    for (final thing in frame.things) {
      final box = mapper.rect(thing.boundingBox);
      if (box.isEmpty) continue;
      final isPrimary = identical(thing, primary);
      final color = isPrimary ? Brand.amber : const Color(0x8CFFFFFF);

      if (isPrimary) _bloom(canvas, box);
      _brackets(canvas, box, color, isPrimary);
      _chip(canvas, thing, box, color, isPrimary);
    }
  }

  void _bloom(Canvas canvas, Rect box) {
    final rect = Rect.fromCenter(
      center: box.center,
      width: box.width * 2.1,
      height: box.height * 2.1,
    );
    canvas.drawOval(
      rect,
      Paint()
        ..shader = RadialGradient(
          colors: [
            Brand.amber.withValues(alpha: 0.14),
            Brand.amber.withValues(alpha: 0),
          ],
          stops: const [0, 1],
        ).createShader(rect),
    );
  }

  void _brackets(Canvas canvas, Rect r, Color color, bool primary) {
    final arm = math.min(r.shortestSide * 0.26, 38.0);
    const radius = 12.0;
    final paint = Paint()
      ..color = color
      ..strokeWidth = primary ? 3 : 1.8
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

  /// Label chip above the box: the classifier's best guess, or the tracking id
  /// when classification is off — never an empty tag.
  void _chip(Canvas canvas, DetectedThing thing, Rect box, Color color, bool primary) {
    final label = thing.top;
    final text = label != null
        ? '${label.text}  ${(label.confidence * 100).round()}%'
        : (thing.trackingId != null ? 'ID ${thing.trackingId}' : 'Object');

    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 11.5,
          fontWeight: FontWeight.w600,
          color: primary ? const Color(0xFF17181A) : const Color(0xFFFFFFFF),
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: math.max(box.width * 1.4, 120));

    final chip = Rect.fromLTWH(
      box.left,
      box.top - painter.height - 12,
      painter.width + 18,
      painter.height + 10,
    );
    if (chip.top < 0) return;

    canvas.drawRRect(
      RRect.fromRectAndRadius(chip, const Radius.circular(9)),
      Paint()..color = primary ? Brand.amber : const Color(0xCC121215),
    );
    painter.paint(canvas, Offset(chip.left + 9, chip.top + 5));
  }

  @override
  bool shouldRepaint(ObjectOverlayPainter old) => !identical(old.frame, frame);
}


