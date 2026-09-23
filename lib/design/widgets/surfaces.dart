import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../palette.dart';
import '../type.dart';

/// The crimson bloom behind a screen's hero. Deliberately one ellipse that
/// resolves fully to black before any content starts — stacked washes are what
/// make this kind of background look cheap.
class Bloom extends StatelessWidget {
  const Bloom({
    super.key,
    this.color = Brand.red,
    this.height = 520,
    this.top = -160,
    this.intensity = 1,
  });

  final Color color;
  final double height;
  final double top;

  /// 0..1. Driven by live detection on the face screen, so the glow means
  /// something rather than just sitting there.
  final double intensity;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: top,
      left: -40,
      right: -40,
      height: height,
      child: IgnorePointer(
        child: TweenAnimationBuilder<double>(
          tween: Tween(end: intensity.clamp(0.0, 1.0)),
          duration: Motion.slow,
          curve: Curves.easeOut,
          builder: (context, t, _) => DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.center,
                radius: 0.5,
                colors: [
                  color.withValues(alpha: 0.80 * t),
                  color.withValues(alpha: 0.42 * t),
                  color.withValues(alpha: 0.14 * t),
                  Ground.base.withValues(alpha: 0),
                ],
                stops: const [0, 0.34, 0.58, 0.80],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Grouped container. Rows inside separate themselves with a top hairline.
class LabCard extends StatelessWidget {
  const LabCard({
    super.key,
    required this.children,
    this.margin = const EdgeInsets.symmetric(horizontal: Gap.lg),
    this.radius = Radii.card,
    this.color = Ground.raised,
  });

  final List<Widget> children;
  final EdgeInsetsGeometry margin;
  final double radius;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: Ground.line),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final (i, child) in children.indexed)
            DecoratedBox(
              decoration: BoxDecoration(
                border: i == 0
                    ? null
                    : const Border(top: BorderSide(color: Ground.line)),
              ),
              child: child,
            ),
        ],
      ),
    );
  }
}

/// Tinted rounded-square icon plate. The per-model hue lives here.
class IconPlate extends StatelessWidget {
  const IconPlate({
    super.key,
    required this.icon,
    required this.color,
    this.size = 38,
  });

  final IconData icon;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(Radii.chip),
      ),
      child: Icon(icon, size: size * 0.55, color: color),
    );
  }
}

/// Standard list row: plate, title, optional subtitle, trailing widget.
class LabRow extends StatelessWidget {
  const LabRow({
    super.key,
    this.leading,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.height = 70,
    this.enabled = true,
  });

  final Widget? leading;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final double height;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      child: Container(
        constraints: BoxConstraints(minHeight: height),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            if (leading != null) ...[leading!, const SizedBox(width: 14)],
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Typo.rowTitle.copyWith(
                      color: enabled ? Tone.primary : Tone.tertiary,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 3),
                    Text(subtitle!, style: Typo.rowSub),
                  ],
                ],
              ),
            ),
            if (trailing != null) ...[const SizedBox(width: 12), trailing!],
          ],
        ),
      ),
    );
  }
}

class Tag extends StatelessWidget {
  const Tag(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        decoration: BoxDecoration(
          color: Ground.veil,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(text, style: Typo.tag),
      );
}

/// Press feedback without Material ink — the whole app avoids ripples.
class Pressable extends StatefulWidget {
  const Pressable({
    super.key,
    required this.child,
    this.onTap,
    this.scale = 0.975,
  });

  final Widget child;
  final VoidCallback? onTap;
  final double scale;

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    if (widget.onTap == null) return widget.child;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setState(() => _down = true),
      onTapUp: (_) => setState(() => _down = false),
      onTapCancel: () => setState(() => _down = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _down ? widget.scale : 1,
        duration: Motion.fast,
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}

/// Translucent round control that floats over the camera.
class CircleButton extends StatelessWidget {
  const CircleButton({
    super.key,
    required this.icon,
    this.onTap,
    this.size = 40,
  });

  final IconData icon;
  final VoidCallback? onTap;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      scale: 0.92,
      child: ClipOval(
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: const Color(0x1FFFFFFF),
              shape: BoxShape.circle,
              border: Border.all(color: Ground.lineStrong),
            ),
            child: Icon(icon, size: size * 0.45, color: Tone.primary),
          ),
        ),
      ),
    );
  }
}

/// Primary action: red pill with a lighter circular affordance on the end.
class PrimaryPill extends StatelessWidget {
  const PrimaryPill({
    super.key,
    required this.label,
    this.icon = Icons.arrow_forward,
    this.color = Brand.red,
    this.onTap,
  });

  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      child: Container(
        height: 46,
        padding: const EdgeInsets.only(left: 18, right: 8),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(23),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.36),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label, style: Typo.button),
            const SizedBox(width: 9),
            Container(
              width: 30,
              height: 30,
              decoration: const BoxDecoration(
                color: Color(0x38FFFFFF),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 15, color: Tone.primary),
            ),
          ],
        ),
      ),
    );
  }
}

/// Live status chip that floats at the foot of the camera stage.
class LiveChip extends StatelessWidget {
  const LiveChip({
    super.key,
    required this.label,
    this.color = Brand.red,
    this.pulse = true,
  });

  final String label;
  final Color color;
  final bool pulse;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: 15),
          decoration: BoxDecoration(
            color: const Color(0x99101012),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Ground.lineStrong),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _Dot(color: color, pulse: pulse),
              const SizedBox(width: 9),
              Text(label, style: Typo.chip),
            ],
          ),
        ),
      ),
    );
  }
}

class _Dot extends StatefulWidget {
  const _Dot({required this.color, required this.pulse});

  final Color color;
  final bool pulse;

  @override
  State<_Dot> createState() => _DotState();
}

class _DotState extends State<_Dot> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1500),
  );

  @override
  void initState() {
    super.initState();
    if (widget.pulse) _c.repeat();
  }

  @override
  void didUpdateWidget(_Dot old) {
    super.didUpdateWidget(old);
    if (widget.pulse && !_c.isAnimating) {
      _c.repeat();
    } else if (!widget.pulse && _c.isAnimating) {
      _c
        ..stop()
        ..value = 0;
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SizedBox(
        width: 8,
        height: 8,
        child: AnimatedBuilder(
          animation: _c,
          builder: (context, _) => CustomPaint(
            painter: _DotPainter(widget.color, widget.pulse ? _c.value : -1),
          ),
        ),
      );
}

class _DotPainter extends CustomPainter {
  _DotPainter(this.color, this.t);

  final Color color;
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    if (t >= 0) {
      final e = Curves.easeOut.transform(t);
      canvas.drawCircle(
        c,
        3.5 + e * 6,
        Paint()..color = color.withValues(alpha: (1 - e) * 0.45),
      );
    }
    canvas.drawCircle(c, 3.5, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_DotPainter old) => old.t != t;
}

/// Kept here so callers don't import dart:ui directly for the blur filters.

