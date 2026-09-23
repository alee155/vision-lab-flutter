import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../palette.dart';
import '../type.dart';

/// Segmented probability meter. Discrete cells make small movements in a live
/// signal legible in a way a smooth bar never does.
class SegmentMeter extends StatelessWidget {
  const SegmentMeter({
    super.key,
    required this.value,
    this.segments = 12,
    this.color = Brand.red,
    this.height = 10,
    this.available = true,
  });

  final double value;
  final int segments;
  final Color color;
  final double height;
  final bool available;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: TweenAnimationBuilder<double>(
        tween: Tween(end: available ? value.clamp(0.0, 1.0) : 0.0),
        duration: Motion.fast,
        curve: Curves.easeOut,
        builder: (context, t, _) => CustomPaint(
          painter: _SegmentPainter(value: t, segments: segments, color: color),
        ),
      ),
    );
  }
}

class _SegmentPainter extends CustomPainter {
  _SegmentPainter({required this.value, required this.segments, required this.color});

  final double value;
  final int segments;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    const gap = 2.5;
    final cell = (size.width - gap * (segments - 1)) / segments;
    if (cell <= 0) return;
    final lit = value * segments;
    final radius = Radius.circular(math.min(cell, size.height) / 2.6);

    for (var i = 0; i < segments; i++) {
      final coverage = (lit - i).clamp(0.0, 1.0);
      final paint = Paint()
        ..color = coverage == 0
            ? const Color(0x17FFFFFF)
            : Color.lerp(const Color(0x17FFFFFF), color, coverage)!;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(i * (cell + gap), 0, cell, size.height),
          radius,
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_SegmentPainter old) =>
      old.value != value || old.color != color || old.segments != segments;
}

/// Radial gauge for a signed angle. The arc grows out from top-centre, so the
/// direction of a head turn is readable before you read the number.
class ArcGauge extends StatelessWidget {
  const ArcGauge({
    super.key,
    required this.label,
    required this.degrees,
    this.range = 45,
    this.color = Brand.red,
  });

  final String label;
  final double? degrees;
  final double range;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final has = degrees != null;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AspectRatio(
          aspectRatio: 1.24,
          child: TweenAnimationBuilder<double>(
            tween: Tween(end: (degrees ?? 0).clamp(-range, range)),
            duration: Motion.fast,
            curve: Curves.easeOut,
            builder: (context, v, _) => CustomPaint(
              painter: _ArcPainter(value: v, range: range, color: color, active: has),
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    has
                        ? '${v < 0 ? '−' : '+'}${v.abs().toStringAsFixed(1)}°'
                        : '—',
                    style: Typo.poseValue.copyWith(
                      fontSize: 16,
                      color: has ? Tone.primary : Tone.faint,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(label, style: Typo.statKey),
      ],
    );
  }
}

class _ArcPainter extends CustomPainter {
  _ArcPainter({
    required this.value,
    required this.range,
    required this.color,
    required this.active,
  });

  final double value;
  final double range;
  final Color color;
  final bool active;

  static const _sweep = 220 * math.pi / 180;
  static const _start = 160 * math.pi / 180;
  static const _zero = _start + _sweep / 2;

  @override
  void paint(Canvas canvas, Size size) {
    final radius = math.min(size.width / 2, size.height / 1.55) - 6;
    final center = Offset(size.width / 2, size.height / 2 + radius * 0.22);
    final rect = Rect.fromCircle(center: center, radius: radius);

    canvas.drawArc(
      rect,
      _start,
      _sweep,
      false,
      Paint()
        ..color = const Color(0x22FFFFFF)
        ..strokeWidth = 5
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke,
    );

    // Centre tick marks the zero position the arc grows away from.
    canvas.drawLine(
      center + Offset(math.cos(_zero), math.sin(_zero)) * (radius - 9),
      center + Offset(math.cos(_zero), math.sin(_zero)) * (radius + 5),
      Paint()
        ..color = const Color(0x40FFFFFF)
        ..strokeWidth = 1.5
        ..strokeCap = StrokeCap.round,
    );

    if (!active) return;

    final angle = _start + _sweep * ((value + range) / (range * 2));
    canvas.drawArc(
      rect,
      math.min(_zero, angle),
      (angle - _zero).abs(),
      false,
      Paint()
        ..color = color
        ..strokeWidth = 5
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke,
    );

    final tip = center + Offset(math.cos(angle), math.sin(angle)) * radius;
    canvas.drawCircle(tip, 4.5, Paint()..color = color);
    canvas.drawCircle(tip, 2, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(_ArcPainter old) =>
      old.value != value || old.active != active || old.color != color;
}

/// Rolling latency trace with a soft fill beneath the line.
class TraceChart extends StatelessWidget {
  const TraceChart({
    super.key,
    required this.samples,
    this.capacity = 48,
    this.color = Brand.red,
    this.height = 64,
  });

  final List<double> samples;
  final int capacity;
  final Color color;
  final double height;

  @override
  Widget build(BuildContext context) => SizedBox(
        height: height,
        width: double.infinity,
        child: CustomPaint(
          painter: _TracePainter(samples: samples, capacity: capacity, color: color),
        ),
      );
}

class _TracePainter extends CustomPainter {
  _TracePainter({required this.samples, required this.capacity, required this.color});

  final List<double> samples;
  final int capacity;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    // Baseline grid reads as a chart even while the trace is still filling.
    final grid = Paint()..color = const Color(0x0DFFFFFF)..strokeWidth = 1;
    for (var i = 1; i < 3; i++) {
      final y = size.height * i / 3;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }
    if (samples.length < 2) return;

    final peak = samples.reduce(math.max).clamp(1.0, double.infinity);
    final span = math.max(samples.length - 1, 1);
    double xAt(int i) => size.width * (i / span);
    double yAt(int i) =>
        size.height * (1 - (samples[i] / peak).clamp(0.0, 1.0) * 0.86) - 2;

    final line = Path()..moveTo(xAt(0), yAt(0));
    for (var i = 1; i < samples.length; i++) {
      line.lineTo(xAt(i), yAt(i));
    }

    final last = samples.length - 1;
    final fill = Path.from(line)
      ..lineTo(xAt(last), size.height)
      ..lineTo(xAt(0), size.height)
      ..close();
    canvas.drawPath(
      fill,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [color.withValues(alpha: 0.28), color.withValues(alpha: 0)],
        ).createShader(Offset.zero & size),
    );

    canvas.drawPath(
      line,
      Paint()
        ..color = color
        ..strokeWidth = 1.8
        ..style = PaintingStyle.stroke
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round,
    );

    final head = Offset(xAt(last), yAt(last));
    canvas.drawCircle(head, 5, Paint()..color = color.withValues(alpha: 0.28));
    canvas.drawCircle(head, 2.6, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_TracePainter old) => true;
}
