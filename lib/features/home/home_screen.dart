import 'package:flutter/material.dart';

import '../../design/palette.dart';
import '../../design/type.dart';
import '../../design/widgets/surfaces.dart';
import '../../modules/model_catalog.dart';

/// The deck. One model is featured; the rest wait their turn.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  static void _open(BuildContext context, VisionModel model) {
    final builder = model.builder;
    if (builder == null) return;
    Navigator.of(context).push(MaterialPageRoute<void>(builder: builder));
  }

  @override
  Widget build(BuildContext context) {
    final featured = modelCatalog.first;
    final rest = modelCatalog.skip(1).toList();

    return Scaffold(
      backgroundColor: Ground.base,
      body: Stack(
        children: [
          const Bloom(),
          SafeArea(
            bottom: false,
            child: ListView(
              padding: const EdgeInsets.only(bottom: Gap.xxl),
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(Gap.lg + 2, Gap.sm, Gap.lg, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Google ML Kit · on device', style: Typo.eyebrow),
                      SizedBox(height: 6),
                      Text('Vision Lab', style: Typo.display),
                    ],
                  ),
                ),
                const SizedBox(height: Gap.xl),
                _Feature(
                  model: featured,
                  onOpen: () => _open(context, featured),
                ),
                const Padding(
                  padding: EdgeInsets.fromLTRB(Gap.lg + 2, Gap.xl + 2, Gap.lg, Gap.md),
                  child: Text('More models', style: Typo.eyebrow),
                ),
                LabCard(
                  children: [
                    for (final m in rest)
                      LabRow(
                        leading: IconPlate(icon: m.icon, color: m.accent),
                        title: m.name,
                        subtitle: m.summary,
                        enabled: m.ready,
                        onTap: m.ready ? () => _open(context, m) : null,
                        trailing: m.ready
                            ? const Icon(Icons.chevron_right_rounded,
                                size: 22, color: Tone.faint)
                            : const Tag('Soon'),
                      ),
                  ],
                ),
                const SizedBox(height: Gap.xl),
                const LabCard(
                  children: [
                    LabRow(
                      leading: IconPlate(icon: Icons.lock_rounded, color: Tone.secondary),
                      title: 'Private by design',
                      subtitle:
                          'Frames are processed locally and never leave this device.',
                      height: 78,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The featured model gets the whole treatment: its own bloom, line-art
/// artwork bleeding off the edge, and the primary action.
class _Feature extends StatelessWidget {
  const _Feature({required this.model, required this.onOpen});

  final VisionModel model;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 246,
      margin: const EdgeInsets.symmetric(horizontal: Gap.lg),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2A0C0A), Color(0xFF160809), Color(0xFF111113)],
          stops: [0, 0.48, 1],
        ),
        borderRadius: BorderRadius.circular(Radii.feature),
        border: Border.all(color: Ground.line),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned(
            right: -70,
            top: -60,
            width: 300,
            height: 300,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: [
                    model.accent.withValues(alpha: 0.55),
                    model.accent.withValues(alpha: 0),
                  ],
                  stops: const [0, 0.7],
                ),
              ),
            ),
          ),
          Positioned(
            right: -24,
            bottom: -14,
            child: CustomPaint(
              size: const Size(190, 200),
              painter: _FaceArtPainter(model.accent),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Model ${model.index}',
                  style: Typo.eyebrow.copyWith(color: Tone.secondary),
                ),
                const SizedBox(height: 5),
                Text(model.shortName, style: Typo.featureTitle),
                const Spacer(),
                PrimaryPill(label: 'Open', color: model.accent, onTap: onOpen),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Abstract wireframe face — the app's own mark rather than a stock glyph.
class _FaceArtPainter extends CustomPainter {
  const _FaceArtPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final stroke = Paint()
      ..color = Brand.redLift.withValues(alpha: 0.9)
      ..strokeWidth = 1.15
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final faint = Paint.from(stroke)..color = Brand.redLift.withValues(alpha: 0.42);

    canvas.drawOval(Rect.fromCenter(center: c, width: 104, height: 130), stroke);
    canvas.drawOval(Rect.fromCenter(center: c, width: 76, height: 104), faint);

    final p = Path()
      ..moveTo(c.dx - 35, c.dy - 22)
      ..cubicTo(c.dx - 28, c.dy - 28, c.dx - 14, c.dy - 29, c.dx - 5, c.dy - 24)
      ..moveTo(c.dx + 5, c.dy - 26)
      ..cubicTo(c.dx + 14, c.dy - 31, c.dx + 28, c.dy - 30, c.dx + 35, c.dy - 22)
      ..moveTo(c.dx - 33, c.dy - 5)
      ..cubicTo(c.dx - 26, c.dy + 1, c.dx - 13, c.dy + 1, c.dx - 6, c.dy - 5)
      ..moveTo(c.dx + 8, c.dy - 5)
      ..cubicTo(c.dx + 15, c.dy - 13, c.dx + 29, c.dy - 13, c.dx + 36, c.dy - 5)
      ..moveTo(c.dx + 2, c.dy - 16)
      ..lineTo(c.dx - 1, c.dy + 20)
      ..moveTo(c.dx - 16, c.dy + 26)
      ..cubicTo(c.dx - 9, c.dy + 20, c.dx + 9, c.dy + 20, c.dx + 17, c.dy + 26)
      ..moveTo(c.dx - 16, c.dy + 26)
      ..cubicTo(c.dx - 8, c.dy + 37, c.dx + 9, c.dy + 37, c.dx + 17, c.dy + 26);
    canvas.drawPath(p, stroke);

    // Cross hairs, clipped to suggest a wider frame beyond the card.
    final hair = Paint()
      ..color = Brand.redLift.withValues(alpha: 0.45)
      ..strokeWidth = 1.15;
    canvas.drawLine(Offset(c.dx - 52, c.dy), Offset(c.dx - 66, c.dy), hair);
    canvas.drawLine(Offset(c.dx + 52, c.dy), Offset(c.dx + 66, c.dy), hair);
    canvas.drawLine(Offset(c.dx, c.dy - 65), Offset(c.dx, c.dy - 78), hair);
    canvas.drawLine(Offset(c.dx, c.dy + 65), Offset(c.dx, c.dy + 78), hair);

    final dot = Paint()..color = Colors.white.withValues(alpha: 0.95);
    for (final o in [
      Offset(c.dx - 23, c.dy - 12), Offset(c.dx + 23, c.dy - 13),
      Offset(c.dx, c.dy + 20), Offset(c.dx - 16, c.dy + 26),
      Offset(c.dx + 17, c.dy + 26), Offset(c.dx - 29, c.dy + 12),
      Offset(c.dx + 29, c.dy + 11),
    ]) {
      canvas.drawCircle(o, 2.4, dot);
    }
  }

  @override
  bool shouldRepaint(_FaceArtPainter old) => old.color != color;
}
