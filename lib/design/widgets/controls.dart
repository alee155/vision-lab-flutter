
import 'package:flutter/material.dart';
import 'package:google_ml_kit/google_ml_kit.dart' show Face;

import '../palette.dart';
import '../type.dart';
import 'gauges.dart';
import 'surfaces.dart';

/// Brand-red switch. Deliberately not the Material one — the track, knob and
/// travel are all tuned to the reference language.
class LabSwitch extends StatelessWidget {
  const LabSwitch({
    super.key,
    required this.value,
    this.onChanged,
    this.color = Brand.red,
  });

  final bool value;
  final ValueChanged<bool>? onChanged;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      scale: 0.94,
      onTap: onChanged == null ? null : () => onChanged!(!value),
      child: AnimatedContainer(
        duration: Motion.fast,
        curve: Curves.easeOut,
        width: 48,
        height: 29,
        decoration: BoxDecoration(
          color: value ? color : const Color(0x21FFFFFF),
          borderRadius: BorderRadius.circular(15),
        ),
        alignment: value ? Alignment.centerRight : Alignment.centerLeft,
        padding: const EdgeInsets.all(2.5),
        child: Container(
          width: 24,
          height: 24,
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(color: Color(0x66000000), blurRadius: 3, offset: Offset(0, 1)),
            ],
          ),
        ),
      ),
    );
  }
}

/// Two-or-more-way selector with a sliding red pill.
class LabSegmented<T> extends StatelessWidget {
  const LabSegmented({
    super.key,
    required this.value,
    required this.options,
    required this.onChanged,
    this.color = Brand.red,
  });

  final T value;
  final List<(T, String)> options;
  final ValueChanged<T> onChanged;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final index = options.indexWhere((o) => o.$1 == value);
    return LayoutBuilder(
      builder: (context, constraints) {
        final slot = (constraints.maxWidth - 6) / options.length;
        return Container(
          height: 38,
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: const Color(0xFF1B1B1F),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Stack(
            children: [
              AnimatedPositioned(
                duration: Motion.base,
                curve: Curves.easeOutCubic,
                left: slot * (index < 0 ? 0 : index),
                width: slot,
                top: 0,
                bottom: 0,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(11),
                  ),
                ),
              ),
              Row(
                children: [
                  for (final option in options)
                    Expanded(
                      child: Pressable(
                        scale: 1,
                        onTap: () => onChanged(option.$1),
                        child: Center(
                          child: AnimatedDefaultTextStyle(
                            duration: Motion.fast,
                            style: Typo.rowTitle.copyWith(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600,
                              color: option.$1 == value ? Tone.primary : Tone.tertiary,
                            ),
                            child: Text(option.$2),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Big percentage tile used in the data sheet.
class StatTile extends StatelessWidget {
  const StatTile({
    super.key,
    required this.label,
    required this.value,
    required this.fraction,
    this.color = Brand.red,
    this.available = true,
  });

  final String label;
  final String value;
  final double fraction;
  final Color color;
  final bool available;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 14, 12, 14),
      decoration: BoxDecoration(
        color: Ground.tile,
        borderRadius: BorderRadius.circular(Radii.tile),
        border: Border.all(color: Ground.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: Typo.statKey),
          const SizedBox(height: 7),
          Text(
            value,
            maxLines: 1,
            style: Typo.statValue.copyWith(
              color: available ? Tone.primary : Tone.faint,
            ),
          ),
          const SizedBox(height: 9),
          SegmentMeter(
            value: fraction,
            color: color,
            available: available,
            segments: 8,
          ),
        ],
      ),
    );
  }
}

/// Yaw / pitch / roll as radial gauges.
class PoseStrip extends StatelessWidget {
  const PoseStrip({super.key, required this.yaw, required this.pitch, required this.roll});

  final double? yaw;
  final double? pitch;
  final double? roll;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(6, 14, 6, 14),
      decoration: BoxDecoration(
        color: Ground.tile,
        borderRadius: BorderRadius.circular(Radii.tile),
        border: Border.all(color: Ground.line),
      ),
      child: Row(
        children: [
          Expanded(child: ArcGauge(label: 'Yaw', degrees: yaw, range: 60)),
          Expanded(child: ArcGauge(label: 'Pitch', degrees: pitch, range: 45)),
          Expanded(child: ArcGauge(label: 'Roll', degrees: roll, range: 45)),
        ],
      ),
    );
  }
}

/// Wide secondary control in the sheet footer.
class SheetButton extends StatelessWidget {
  const SheetButton({
    super.key,
    required this.icon,
    required this.label,
    this.onTap,
    this.active = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      child: AnimatedContainer(
        duration: Motion.fast,
        height: 52,
        decoration: BoxDecoration(
          color: active ? Brand.red : Ground.tile,
          borderRadius: BorderRadius.circular(17),
          border: Border.all(color: active ? Colors.transparent : Ground.line),
          boxShadow: active
              ? [
                  BoxShadow(
                    color: Brand.red.withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 17, color: Tone.primary),
            const SizedBox(width: 9),
            Text(label, style: Typo.button.copyWith(fontSize: 14.5)),
          ],
        ),
      ),
    );
  }
}

/// Compact label → value row used throughout the detail sections.
class DetailRow extends StatelessWidget {
  const DetailRow({
    super.key,
    required this.label,
    required this.value,
    this.color,
    this.highlight = false,
  });

  final String label;
  final String value;
  final Color? color;

  /// Briefly tints the value — used when a blink is registered.
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Typo.rowTitle.copyWith(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Tone.secondary,
              ),
            ),
          ),
          const SizedBox(width: Gap.md),
          // Both sides flex: a long value (a picked photo's filename, say)
          // shrinks and ellipsises instead of pushing the row off screen.
          Flexible(
            child: AnimatedDefaultTextStyle(
              duration: Motion.base,
              style: Typo.rowTitle.copyWith(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: highlight ? Brand.amber : (color ?? Tone.primary),
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
              child: Text(
                value,
                textAlign: TextAlign.end,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Small header above a group of detail rows.
class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key, this.trailing});

  final String text;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(Gap.xs + 2, Gap.xl, Gap.xs, Gap.md),
        child: Row(
          children: [
            Expanded(child: Text(text, style: Typo.eyebrow)),
            ?trailing,
          ],
        ),
      );
}

/// Slider row in the app's language: red track, white knob, value on the right.
class LabSlider extends StatelessWidget {
  const LabSlider({
    super.key,
    required this.label,
    required this.subtitle,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
    required this.format,
    this.divisions,
    this.color = Brand.red,
  });

  final String label;
  final String subtitle;
  final double value;
  final double min;
  final double max;
  final int? divisions;
  final ValueChanged<double> onChanged;
  final String Function(double) format;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 13, 16, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: Typo.rowTitle),
                    const SizedBox(height: 3),
                    Text(subtitle, style: Typo.rowSub),
                  ],
                ),
              ),
              const SizedBox(width: Gap.md),
              Text(
                format(value),
                style: Typo.rowTitle.copyWith(
                  fontSize: 14,
                  color: color,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          SliderTheme(
            data: SliderThemeData(
              trackHeight: 5,
              activeTrackColor: color,
              inactiveTrackColor: const Color(0x1FFFFFFF),
              thumbColor: Colors.white,
              overlayColor: color.withValues(alpha: 0.16),
              thumbShape: const RoundSliderThumbShape(
                enabledThumbRadius: 9,
                elevation: 2,
              ),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 18),
              activeTickMarkColor: Colors.transparent,
              inactiveTickMarkColor: Colors.transparent,
              trackShape: const RoundedRectSliderTrackShape(),
              padding: EdgeInsets.zero,
            ),
            child: Slider(
              value: value.clamp(min, max),
              min: min,
              max: max,
              divisions: divisions,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}

/// Numbered section rule: a red index, the title, then a hairline to the margin.
class NumberedHeader extends StatelessWidget {
  const NumberedHeader({
    super.key,
    required this.index,
    required this.title,
    this.trailing,
  });

  final String index;
  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: Gap.xl + 4, bottom: Gap.md + 2),
      child: Row(
        children: [
          Text(index, style: Typo.eyebrow.copyWith(color: Brand.red)),
          const SizedBox(width: Gap.sm),
          Text(
            title,
            style: Typo.rowTitle.copyWith(fontSize: 15, fontWeight: FontWeight.w600),
          ),
          const SizedBox(width: Gap.md),
          const Expanded(child: _Rule()),
          ?trailing,
        ],
      ),
    );
  }
}

class _Rule extends StatelessWidget {
  const _Rule();

  @override
  Widget build(BuildContext context) => Container(
        height: 1,
        margin: const EdgeInsets.only(right: Gap.md),
        color: Ground.line,
      );
}

/// Label → segmented meter → value. The workhorse row of the signals section.
class MeterRow extends StatelessWidget {
  const MeterRow({
    super.key,
    required this.label,
    required this.value,
    required this.display,
    this.flagged = false,
  });

  final String label;

  /// Null when the detector was not asked to produce this signal.
  final double? value;
  final String display;

  /// Draws the meter in amber — a value that means something is up.
  final bool flagged;

  @override
  Widget build(BuildContext context) {
    final color = flagged ? Brand.amber : Brand.red;
    return Row(
      children: [
        SizedBox(
          width: 78,
          child: Text(
            label,
            style: Typo.rowTitle.copyWith(
              fontSize: 13.5,
              fontWeight: FontWeight.w500,
              color: Tone.secondary,
            ),
          ),
        ),
        Expanded(
          child: SegmentMeter(
            value: value ?? 0,
            segments: 14,
            height: 11,
            color: color,
            available: value != null,
          ),
        ),
        SizedBox(
          width: 52,
          child: Text(
            display,
            textAlign: TextAlign.right,
            style: Typo.rowTitle.copyWith(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: value == null ? Tone.faint : (flagged ? Brand.amber : Tone.primary),
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ),
      ],
    );
  }
}

/// Bordered grid of stat cells, divided by hairlines.
class StatGrid extends StatelessWidget {
  const StatGrid({super.key, required this.rows});

  final List<List<Widget>> rows;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Ground.raised,
        borderRadius: BorderRadius.circular(Radii.card),
        border: Border.all(color: Ground.line),
      ),
      child: Column(
        children: [
          for (final (i, row) in rows.indexed)
            DecoratedBox(
              decoration: BoxDecoration(
                border: i == 0
                    ? null
                    : const Border(top: BorderSide(color: Ground.line)),
              ),
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final (j, cell) in row.indexed) ...[
                      if (j > 0)
                        const VerticalDivider(
                          width: 1,
                          thickness: 1,
                          color: Ground.line,
                        ),
                      Expanded(child: cell),
                    ],
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// One cell of [StatGrid]; a trace draws faintly behind the number.
class StatCell extends StatelessWidget {
  const StatCell({
    super.key,
    required this.label,
    required this.value,
    this.unit,
    this.trace,
    this.highlight = false,
  });

  final String label;
  final String value;
  final String? unit;
  final List<double>? trace;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        if (trace != null && trace!.length > 1)
          Positioned.fill(
            top: 30,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 0, 8, 6),
              child: Opacity(
                opacity: 0.45,
                child: TraceChart(samples: trace!, height: 24),
              ),
            ),
          ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(label, style: Typo.statKey),
              const SizedBox(height: Gap.sm),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Flexible(
                    child: AnimatedDefaultTextStyle(
                      duration: Motion.base,
                      style: Typo.statValue.copyWith(
                        fontSize: 21,
                        letterSpacing: -0.7,
                        color: highlight ? Brand.amber : Tone.primary,
                      ),
                      child: Text(value, maxLines: 1),
                    ),
                  ),
                  if (unit != null) ...[
                    const SizedBox(width: 3),
                    Text(unit!, style: Typo.statKey.copyWith(fontSize: 10.5)),
                  ],
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// One line per detected face when the frame holds several.
class FaceRow extends StatelessWidget {
  const FaceRow({
    super.key,
    required this.index,
    required this.face,
    required this.primary,
  });

  final int index;
  final Face face;
  final bool primary;

  @override
  Widget build(BuildContext context) {
    final right = face.rightEyeOpenProbability;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: primary ? Brand.red : Colors.transparent,
              borderRadius: BorderRadius.circular(7),
              border: primary
                  ? null
                  : Border.all(color: Ground.lineStrong, width: 1.5),
            ),
            child: Text(
              '$index',
              style: Typo.tag.copyWith(
                fontSize: 12,
                color: primary ? Colors.white : Tone.tertiary,
              ),
            ),
          ),
          const SizedBox(width: Gap.md),
          Expanded(
            child: Text(
              face.trackingId == null
                  ? 'Face $index'
                  : 'Face $index · id ${face.trackingId}',
              style: Typo.rowTitle.copyWith(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: primary ? Tone.primary : Tone.secondary,
              ),
            ),
          ),
          SizedBox(
            width: 96,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _Mini(label: 'S', value: face.smilingProbability),
                const SizedBox(height: 4),
                _Mini(label: 'L', value: face.leftEyeOpenProbability),
                const SizedBox(height: 4),
                _Mini(
                  label: 'R',
                  value: right,
                  color: (right ?? 1) < 0.25 ? Brand.amber : Brand.red,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Mini extends StatelessWidget {
  const _Mini({required this.label, required this.value, this.color = Brand.red});

  final String label;
  final double? value;
  final Color color;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          SizedBox(
            width: 11,
            child: Text(label, style: Typo.statKey.copyWith(fontSize: 9.5)),
          ),
          Expanded(
            child: SegmentMeter(
              value: value ?? 0,
              segments: 6,
              height: 6,
              color: color,
              available: value != null,
            ),
          ),
          SizedBox(
            width: 26,
            child: Text(
              value == null ? '—' : '${(value! * 100).round()}',
              textAlign: TextAlign.right,
              style: Typo.statKey.copyWith(
                fontSize: 10.5,
                color: Tone.secondary,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
        ],
      );
}

/// One control in the fixed bottom bar.
class DeckButton extends StatelessWidget {
  const DeckButton({
    super.key,
    required this.icon,
    required this.label,
    this.onTap,
    this.active = false,
    this.accent = Brand.red,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool active;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final tint = onTap == null
        ? Tone.faint
        : active
            ? accent
            : Tone.secondary;

    return Expanded(
      child: Pressable(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 3),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: active ? accent.withValues(alpha: 0.14) : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 21, color: tint),
              const SizedBox(height: 5),
              Text(label, style: Typo.statKey.copyWith(fontSize: 11, color: tint)),
            ],
          ),
        ),
      ),
    );
  }
}
