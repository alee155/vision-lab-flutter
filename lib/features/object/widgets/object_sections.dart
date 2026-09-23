import 'package:flutter/material.dart';

import '../../../design/palette.dart';
import '../../../design/type.dart';
import '../../../design/widgets/controls.dart';
import '../../../design/widgets/gauges.dart';
import '../../../design/widgets/surfaces.dart';
import '../object_channel.dart';
import '../object_lab.dart';

/// Numbered readout sections below the viewport.
class ObjectSections extends StatelessWidget {
  const ObjectSections({super.key, required this.lab});

  final ObjectLab lab;

  static String _clock(Duration d) =>
      '${d.inMinutes.toString().padLeft(2, '0')}:'
      '${(d.inSeconds % 60).toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final frame = lab.frame;
    final things = frame.things;
    final primary = frame.primary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── 01 Objects ────────────────────────────────────────────────────
        NumberedHeader(
          index: '01',
          title: 'Objects',
          trailing: things.isEmpty ? null : Tag('${things.length}'),
        ),
        if (lab.error != null)
          _ErrorPanel(message: lab.error!)
        else if (things.isEmpty)
          const _Empty()
        else
          LabCard(margin: EdgeInsets.zero, children: [
            for (final (i, thing) in things.indexed)
              _ThingRow(
                index: i + 1,
                thing: thing,
                primary: identical(thing, primary),
                classify: lab.classify,
              ),
          ]),

        if (lab.classify) const _VocabularyNote(),

        // ── 02 Session ────────────────────────────────────────────────────
        const NumberedHeader(index: '02', title: 'Session'),
        StatGrid(rows: [
          [
            StatCell(label: 'In frame', value: '${lab.objectCount}'),
            StatCell(label: 'Most at once', value: '${lab.peakObjects}'),
            StatCell(label: 'Unique ids', value: '${lab.uniqueIds}'),
          ],
          [
            StatCell(label: 'Frames', value: '${lab.framesProcessed}'),
            StatCell(
              label: 'Latency',
              value: lab.latencyMs == 0 ? '—' : lab.latencyMs.toStringAsFixed(1),
              unit: 'ms',
              trace: lab.latencyTrace,
            ),
            StatCell(
              label: 'Throughput',
              value: lab.fps == 0 ? '—' : lab.fps.toStringAsFixed(0),
              unit: 'fps',
            ),
          ],
        ]),

        // ── 03 Source ─────────────────────────────────────────────────────
        const NumberedHeader(index: '03', title: 'Source'),
        LabCard(margin: EdgeInsets.zero, children: [
          DetailRow(
            label: 'Input',
            value: lab.isStill
                ? (lab.stillName ?? 'Photo')
                : (lab.camera.lens.name == 'front' ? 'Front camera' : 'Rear camera'),
          ),
          DetailRow(
            label: 'Resolution',
            value: frame.sourceSize.isEmpty
                ? '—'
                : '${frame.sourceSize.width.toInt()} × ${frame.sourceSize.height.toInt()}',
          ),
          DetailRow(label: 'Detection mode', value: lab.mode),
          DetailRow(label: 'Classification', value: lab.classify ? 'On' : 'Off'),
          DetailRow(label: 'Multiple objects', value: lab.multiple ? 'On' : 'Off'),
          DetailRow(label: 'Running for', value: _clock(lab.uptime)),
        ]),
      ],
    );
  }
}

/// One detected object, with its classifier labels.
class _ThingRow extends StatelessWidget {
  const _ThingRow({
    required this.index,
    required this.thing,
    required this.primary,
    required this.classify,
  });

  final int index;
  final DetectedThing thing;
  final bool primary;
  final bool classify;

  @override
  Widget build(BuildContext context) {
    final box = thing.boundingBox;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 24,
                height: 24,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: primary ? Brand.amber : Colors.transparent,
                  borderRadius: BorderRadius.circular(7),
                  border: primary
                      ? null
                      : Border.all(color: Ground.lineStrong, width: 1.5),
                ),
                child: Text(
                  '$index',
                  style: Typo.tag.copyWith(
                    fontSize: 12,
                    color: primary ? const Color(0xFF17181A) : Tone.tertiary,
                  ),
                ),
              ),
              const SizedBox(width: Gap.md),
              Expanded(
                child: Row(
                  children: [
                    Flexible(
                      child: Text(
                        thing.top?.text ?? (classify ? 'Unclassified' : 'Object'),
                        overflow: TextOverflow.ellipsis,
                        style: Typo.rowTitle.copyWith(
                          fontSize: 15,
                          color: primary ? Tone.primary : Tone.secondary,
                        ),
                      ),
                    ),
                    if ((thing.top?.confidence ?? 1) < 0.5) ...[
                      const SizedBox(width: Gap.sm),
                      const Tag('low'),
                    ],
                  ],
                ),
              ),
              Text(
                thing.trackingId == null ? 'no id' : 'id ${thing.trackingId}',
                style: Typo.statKey.copyWith(fontSize: 11.5),
              ),
            ],
          ),
          const SizedBox(height: Gap.md),
          for (final label in thing.labels.take(3)) ...[
            Row(
              children: [
                SizedBox(
                  width: 96,
                  child: Text(
                    label.text,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Typo.rowSub.copyWith(color: Tone.secondary),
                  ),
                ),
                Expanded(
                  child: SegmentMeter(
                    value: label.confidence,
                    segments: 10,
                    height: 7,
                    color: Brand.amber,
                  ),
                ),
                SizedBox(
                  width: 42,
                  child: Text(
                    '${(label.confidence * 100).round()}%',
                    textAlign: TextAlign.right,
                    style: Typo.statKey.copyWith(fontSize: 11.5, color: Tone.secondary),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 5),
          ],
          Text(
            '${box.left.round()}, ${box.top.round()}  ·  '
            '${box.width.round()} × ${box.height.round()}',
            style: Typo.statKey.copyWith(fontSize: 11),
          ),
        ],
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty();

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 18),
        decoration: BoxDecoration(
          color: Ground.raised,
          borderRadius: BorderRadius.circular(Radii.card),
          border: Border.all(color: Ground.line),
        ),
        child: Column(
          children: [
            const Icon(Icons.search_off_rounded, size: 26, color: Tone.faint),
            const SizedBox(height: Gap.md),
            Text(
              'Nothing detected',
              style: Typo.rowTitle.copyWith(fontSize: 14, color: Tone.secondary),
            ),
            const SizedBox(height: 4),
            Text(
              'Point the camera at a distinct object — the base model finds '
              'prominent things, not every item in a scene.',
              textAlign: TextAlign.center,
              style: Typo.body.copyWith(fontSize: 12.5),
            ),
          ],
        ),
      );
}

class _ErrorPanel extends StatelessWidget {
  const _ErrorPanel({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Brand.amber.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(Radii.card),
          border: Border.all(color: Brand.amber.withValues(alpha: 0.35)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.error_outline_rounded, size: 19, color: Brand.amber),
            const SizedBox(width: Gap.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Detection failed',
                    style: Typo.rowTitle.copyWith(fontSize: 14, color: Brand.amber),
                  ),
                  const SizedBox(height: 4),
                  SelectableText(message, style: Typo.body.copyWith(fontSize: 12.5)),
                ],
              ),
            ),
          ],
        ),
      );
}

/// The base classifier's vocabulary is five coarse buckets, and everything else
/// is forced into the nearest one. Saying so where the labels appear is the
/// difference between a result that looks broken and one that is understood.
class _VocabularyNote extends StatelessWidget {
  const _VocabularyNote();

  static const _categories = [
    'Home good',
    'Fashion good',
    'Food',
    'Place',
    'Plant',
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: Gap.md),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Ground.raised,
        borderRadius: BorderRadius.circular(Radii.card),
        border: Border.all(color: Ground.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.info_outline_rounded, size: 17, color: Tone.tertiary),
              const SizedBox(width: Gap.sm),
              Text(
                'The classifier knows five things',
                style: Typo.rowTitle.copyWith(fontSize: 13.5, color: Tone.secondary),
              ),
            ],
          ),
          const SizedBox(height: Gap.md),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [for (final c in _categories) Tag(c)],
          ),
          const SizedBox(height: Gap.md),
          Text(
            'Anything outside these is forced into the nearest one — an animal '
            'will not come back as an animal. Object detection finds and tracks '
            'things; to name them, use Image Labeling.',
            style: Typo.body.copyWith(fontSize: 12.5),
          ),
        ],
      ),
    );
  }
}
