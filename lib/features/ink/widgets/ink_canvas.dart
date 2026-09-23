import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../../design/palette.dart';
import '../../../design/type.dart';
import '../../../design/widgets/surfaces.dart';
import '../ink_lab.dart';

/// The writing surface: a ruled panel that captures strokes and draws them
/// back in the brand red.
class InkCanvas extends StatelessWidget {
  const InkCanvas({super.key, required this.lab});

  final InkLab lab;

  @override
  Widget build(BuildContext context) {
    final blocked = lab.state != ModelState.ready;

    return AspectRatio(
      aspectRatio: 1,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF0C0C0F),
          borderRadius: BorderRadius.circular(Radii.card),
          border: Border.all(color: Ground.line),
        ),
        clipBehavior: Clip.antiAlias,
        child: LayoutBuilder(
          builder: (context, constraints) {
            lab.setCanvasSize(constraints.biggest);
            return Stack(
              fit: StackFit.expand,
              children: [
                const _Ruling(),
                RepaintBoundary(
                  child: CustomPaint(painter: _InkPainter(lab)),
                ),
                if (lab.isEmpty && !blocked)
                  IgnorePointer(
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.gesture_rounded, size: 30, color: Tone.faint),
                          const SizedBox(height: Gap.md),
                          Text(
                            lab.language.note ?? 'Write here',
                            style: Typo.body.copyWith(color: Tone.faint),
                          ),
                        ],
                      ),
                    ),
                  ),
                if (blocked) _ModelGate(lab: lab),
                if (!blocked)
                  // Two layers, each doing one job. The eager recogniser claims
                  // the pointer the instant it lands, so the enclosing ListView
                  // never gets to interpret a stroke as a scroll. The Listener
                  // then reads raw pointer events, which yield every sample —
                  // a gesture recogniser would hand back a coarser path.
                  RawGestureDetector(
                    behavior: HitTestBehavior.opaque,
                    gestures: {
                      EagerGestureRecognizer:
                          GestureRecognizerFactoryWithHandlers<EagerGestureRecognizer>(
                        EagerGestureRecognizer.new,
                        (_) {},
                      ),
                    },
                    child: Listener(
                      behavior: HitTestBehavior.opaque,
                      onPointerDown: (e) => lab.penDown(e.localPosition),
                      onPointerMove: (e) => lab.penMove(e.localPosition),
                      onPointerUp: (_) => lab.penUp(),
                      onPointerCancel: (_) => lab.penUp(),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Faint ruling so the panel reads as something you write on.
class _Ruling extends StatelessWidget {
  const _Ruling();

  @override
  Widget build(BuildContext context) =>
      const IgnorePointer(child: CustomPaint(painter: _RulingPainter()));
}

class _RulingPainter extends CustomPainter {
  const _RulingPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0x0AFFFFFF)..strokeWidth = 1;
    for (var y = size.height / 4; y < size.height; y += size.height / 4) {
      canvas.drawLine(Offset(20, y), Offset(size.width - 20, y), paint);
    }
    // A stronger baseline marks where writing is expected to sit.
    canvas.drawLine(
      Offset(20, size.height * 0.75),
      Offset(size.width - 20, size.height * 0.75),
      Paint()..color = const Color(0x1AE23A2E)..strokeWidth = 1.2,
    );
  }

  @override
  bool shouldRepaint(_RulingPainter old) => false;
}

class _InkPainter extends CustomPainter {
  _InkPainter(this.lab) : super(repaint: lab);

  final InkLab lab;

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = Paint()
      ..color = Brand.red
      ..strokeWidth = 3.6
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final glow = Paint()
      ..color = Brand.red.withValues(alpha: 0.30)
      ..strokeWidth = 9
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);

    for (final pen in [...lab.strokes, if (lab.active != null) lab.active!]) {
      if (pen.points.isEmpty) continue;
      if (pen.points.length == 1) {
        canvas.drawCircle(pen.points.first, 2.1, Paint()..color = Brand.red);
        continue;
      }
      // Quadratic segments through midpoints keep fast strokes smooth.
      final path = Path()..moveTo(pen.points.first.dx, pen.points.first.dy);
      for (var i = 1; i < pen.points.length - 1; i++) {
        final mid = (pen.points[i] + pen.points[i + 1]) / 2;
        path.quadraticBezierTo(
          pen.points[i].dx, pen.points[i].dy, mid.dx, mid.dy);
      }
      path.lineTo(pen.points.last.dx, pen.points.last.dy);
      canvas.drawPath(path, glow);
      canvas.drawPath(path, stroke);
    }
  }

  @override
  bool shouldRepaint(_InkPainter old) => false;
}

/// Covers the canvas until the language model is on the device.
class _ModelGate extends StatelessWidget {
  const _ModelGate({required this.lab});

  final InkLab lab;

  static String _clock(Duration d) =>
      '${d.inMinutes}:${(d.inSeconds % 60).toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final downloading = lab.state == ModelState.downloading;
    final checking = lab.state == ModelState.checking;

    final (title, body, action) = switch (lab.state) {
      ModelState.checking => (
          'Checking for the model',
          'Looking for ${lab.language.name} on this device.',
          null,
        ),
      ModelState.downloading => (
          'Downloading ${lab.language.name}',
          'ML Kit does not report download progress, so there is no percentage '
              'to show — only the time it has been running.',
          null,
        ),
      ModelState.failed => (
          'Download failed',
          lab.detail ?? 'Check your connection and try again.',
          'Retry',
        ),
      _ => (
          '${lab.language.name} model needed',
          'Handwriting models are not bundled with the app. Downloading it once '
              'lets recognition run offline from then on.',
          'Download',
        ),
    };

    return Container(
      color: const Color(0xE60C0C0F),
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            switch (lab.state) {
              ModelState.failed => Icons.cloud_off_rounded,
              ModelState.downloading => Icons.cloud_sync_rounded,
              ModelState.checking => Icons.search_rounded,
              _ => Icons.cloud_download_rounded,
            },
            size: 30,
            color: downloading ? Brand.red : Tone.secondary,
          ),
          const SizedBox(height: Gap.lg),
          Text(title, style: Typo.navTitle, textAlign: TextAlign.center),
          const SizedBox(height: 6),
          Text(body, style: Typo.body, textAlign: TextAlign.center),

          if (downloading || checking) ...[
            const SizedBox(height: Gap.xl),
            // Indeterminate on purpose: a bar that implied a percentage would
            // be inventing information the platform never gave us.
            ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: const LinearProgressIndicator(
                minHeight: 5,
                backgroundColor: Color(0x1FFFFFFF),
                valueColor: AlwaysStoppedAnimation(Brand.red),
              ),
            ),
          ],
          if (downloading) ...[
            const SizedBox(height: Gap.md),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Elapsed ${_clock(lab.downloadElapsed)}',
                  style: Typo.statKey.copyWith(color: Tone.secondary),
                ),
                const SizedBox(width: Gap.sm),
                Text('·', style: Typo.statKey),
                const SizedBox(width: Gap.sm),
                Text(lab.language.tag, style: Typo.statKey),
              ],
            ),
          ],

          if (action != null) ...[
            const SizedBox(height: Gap.xl),
            PrimaryPill(
              label: action,
              icon: Icons.arrow_downward_rounded,
              onTap: lab.downloadModel,
            ),
            const SizedBox(height: Gap.md),
            Text(
              'Needs a connection once. A few megabytes.',
              style: Typo.statKey.copyWith(color: Tone.faint),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}
