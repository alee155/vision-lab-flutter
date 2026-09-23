import 'dart:ui' as ui;

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import '../camera/vision_camera.dart';
import '../../design/palette.dart';
import '../../design/type.dart';
import '../../design/widgets/surfaces.dart';

/// The viewport as a contained panel: a window onto the input, the detection
/// overlay, and two strips describing what the detector is actually being fed.
///
/// Feature-agnostic — the module supplies its painter and its nouns.
class VisionViewport extends StatelessWidget {
  const VisionViewport({
    super.key,
    required this.camera,
    this.painter,
    required this.sourceSize,
    required this.isStill,
    required this.still,
    required this.latencyMs,
    required this.count,
    required this.noun,
    required this.accent,
    this.aspectRatio = 3 / 4,
  });

  final VisionCamera camera;
  /// Null for a module with nothing to draw over the frame.
  final CustomPainter? painter;
  final Size sourceSize;
  final bool isStill;
  final ui.Image? still;
  final double latencyMs;
  final int count;

  /// Singular noun for the bottom strip: "face", "object".
  final String noun;
  final Color accent;
  final double aspectRatio;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: aspectRatio,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF0C0C0F),
          borderRadius: BorderRadius.circular(Radii.card),
          border: Border.all(color: Ground.line),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            _source(context),
            if (painter != null)
              RepaintBoundary(child: CustomPaint(painter: painter)),
            _topStrip(),
            _bottomStrip(),
          ],
        ),
      ),
    );
  }

  Widget _source(BuildContext context) {
    if (isStill) return RawImage(image: still, fit: BoxFit.contain);

    final controller = camera.controller;
    final preview = camera.previewSize;
    if (controller != null && controller.value.isInitialized && !preview.isEmpty) {
      // Cover-fitting a box of exactly the upright preview size is what keeps
      // FrameMapper's maths aligned with the pixels on screen.
      return FittedBox(
        fit: BoxFit.cover,
        clipBehavior: Clip.hardEdge,
        child: SizedBox(
          width: preview.width,
          height: preview.height,
          child: CameraPreview(controller, key: ObjectKey(controller)),
        ),
      );
    }
    return _RigState(camera: camera);
  }

  Widget _topStrip() {
    final paused = camera.status == RigStatus.paused;
    final live = !isStill && camera.isRunning;
    final size = sourceSize;

    final (label, color) = isStill
        ? ('Photo', Brand.violet)
        : paused
            ? ('Hold', Brand.amber)
            : live
                ? ('Live', accent)
                : ('Standby', Tone.faint);

    return Positioned(
      left: Gap.md,
      right: Gap.md,
      top: Gap.md,
      child: IgnorePointer(
        child: Row(
          children: [
            _Badge(label: label, color: color, pulse: live),
            const Spacer(),
            if (!size.isEmpty)
              _Chip('${size.width.toInt()}×${size.height.toInt()}'),
            if (!isStill) ...[
              const SizedBox(width: 6),
              _Chip(camera.lens == CameraLensDirection.front ? 'Front' : 'Rear'),
            ],
          ],
        ),
      ),
    );
  }

  Widget _bottomStrip() {
    final n = count;
    return Positioned(
      left: Gap.md,
      right: Gap.md,
      bottom: Gap.md,
      child: IgnorePointer(
        child: Row(
          children: [
            _Chip(
              n == 0 ? 'No $noun' : (n == 1 ? '1 $noun' : '$n ${noun}s'),
              color: n == 0 ? Tone.faint : accent,
            ),
            const Spacer(),
            if (latencyMs > 0) _Chip('${latencyMs.toStringAsFixed(1)} ms'),
          ],
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label, required this.color, required this.pulse});

  final String label;
  final Color color;
  final bool pulse;

  @override
  Widget build(BuildContext context) => Container(
        height: 26,
        padding: const EdgeInsets.only(left: 8, right: 10),
        decoration: BoxDecoration(
          color: const Color(0xB80A0A0C),
          borderRadius: BorderRadius.circular(9),
          border: Border.all(color: color.withValues(alpha: 0.45)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                boxShadow: pulse
                    ? [BoxShadow(color: color.withValues(alpha: 0.9), blurRadius: 7)]
                    : null,
              ),
            ),
            const SizedBox(width: 7),
            Text(label, style: Typo.tag.copyWith(color: color, fontSize: 11)),
          ],
        ),
      );
}

class _Chip extends StatelessWidget {
  const _Chip(this.text, {this.color = Tone.secondary});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        height: 26,
        padding: const EdgeInsets.symmetric(horizontal: 9),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: const Color(0xB80A0A0C),
          borderRadius: BorderRadius.circular(9),
        ),
        child: Text(text, style: Typo.tag.copyWith(color: color, fontSize: 11)),
      );
}

/// Shown whenever the rig is not delivering frames.
class _RigState extends StatelessWidget {
  const _RigState({required this.camera});

  final VisionCamera camera;

  @override
  Widget build(BuildContext context) {
    final status = camera.status;
    final (title, body, action) = switch (status) {
      RigStatus.opening => ('Starting camera', 'One moment.', null),
      RigStatus.denied => (
          'Camera access needed',
          'Enable camera access for Vision Lab in Settings, then try again.',
          'Try again',
        ),
      RigStatus.unavailable => ('No camera found', camera.detail ?? '', null),
      RigStatus.failed => ('Camera error', camera.detail ?? '', 'Retry'),
      _ => ('Camera paused', 'Resume the feed to run detection.', 'Start'),
    };

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              status == RigStatus.denied || status == RigStatus.failed
                  ? Icons.videocam_off_rounded
                  : Icons.videocam_rounded,
              size: 30,
              color: Tone.faint,
            ),
            const SizedBox(height: Gap.md),
            Text(title, style: Typo.navTitle, textAlign: TextAlign.center),
            const SizedBox(height: 6),
            Text(body, style: Typo.body, textAlign: TextAlign.center),
            if (action != null) ...[
              const SizedBox(height: Gap.lg),
              PrimaryPill(
                label: action,
                icon: Icons.refresh_rounded,
                onTap: () => camera.start(prefer: camera.lens),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
