import 'package:flutter/material.dart';

import '../../../design/palette.dart';
import '../../../design/type.dart';
import '../../../design/widgets/controls.dart';
import '../../../design/widgets/gauges.dart';
import '../../../design/widgets/surfaces.dart';
import '../label_lab.dart';

/// Numbered readout sections below the viewport.
class LabelSections extends StatelessWidget {
  const LabelSections({super.key, required this.lab});

  final LabelLab lab;

  static String _clock(Duration d) =>
      '${d.inMinutes.toString().padLeft(2, '0')}:'
      '${(d.inSeconds % 60).toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final frame = lab.frame;
    final tags = frame.tags;
    final seen = lab.vocabularySeen;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── 01 Labels ─────────────────────────────────────────────────────
        NumberedHeader(
          index: '01',
          title: 'Labels',
          trailing: tags.isEmpty ? null : Tag('${tags.length}'),
        ),
        _Headline(lab: lab),

        if (tags.length > 1) ...[
          const SizedBox(height: Gap.md),
          LabCard(margin: EdgeInsets.zero, children: [
            for (final (i, tag) in tags.skip(1).indexed)
              _TagRow(rank: i + 2, text: tag.text, confidence: tag.confidence),
          ]),
        ],

        // ── 02 Session ────────────────────────────────────────────────────
        const NumberedHeader(index: '02', title: 'Session'),
        StatGrid(rows: [
          [
            StatCell(label: 'In frame', value: '${lab.tagCount}'),
            StatCell(label: 'Most at once', value: '${lab.peakTags}'),
            StatCell(label: 'Distinct seen', value: '${seen.length}'),
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

        // ── 03 Everything seen ────────────────────────────────────────────
        if (seen.isNotEmpty) ...[
          NumberedHeader(
            index: '03',
            title: 'Seen this session',
            trailing: Tag('${seen.length}'),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Ground.raised,
              borderRadius: BorderRadius.circular(Radii.card),
              border: Border.all(color: Ground.line),
            ),
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [for (final s in seen) Tag(s)],
            ),
          ),
        ],

        // ── 04 Source ─────────────────────────────────────────────────────
        NumberedHeader(index: seen.isEmpty ? '03' : '04', title: 'Source'),
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
          DetailRow(
            label: 'Confidence floor',
            value: '${(lab.threshold * 100).round()}%',
          ),
          DetailRow(label: 'Vocabulary', value: '~400 concepts'),
          DetailRow(label: 'Running for', value: _clock(lab.uptime)),
        ]),
      ],
    );
  }
}

/// The top label, given the room it deserves.
class _Headline extends StatelessWidget {
  const _Headline({required this.lab});

  final LabelLab lab;

  @override
  Widget build(BuildContext context) {
    if (lab.error != null) {
      return Container(
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
              child: SelectableText(
                lab.error!,
                style: Typo.body.copyWith(fontSize: 12.5),
              ),
            ),
          ],
        ),
      );
    }

    final best = lab.frame.best;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 20),
      decoration: BoxDecoration(
        color: Ground.raised,
        borderRadius: BorderRadius.circular(Radii.card),
        border: Border.all(
          color: best == null ? Ground.line : Brand.emerald.withValues(alpha: 0.45),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(best == null ? 'Nothing above the floor' : 'Most likely',
              style: Typo.statKey),
          const SizedBox(height: Gap.sm),
          // No crossfade here: on a live feed this value changes several
          // times a second, so an animation would only ever show mush — and
          // a repeated value collided with its own outgoing key.
          Text(
            best?.text ?? '—',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Typo.display.copyWith(
              fontSize: 32,
              color: best == null ? Tone.faint : Tone.primary,
            ),
          ),
          if (best != null) ...[
            const SizedBox(height: Gap.md + 2),
            Row(
              children: [
                Expanded(
                  child: SegmentMeter(
                    value: best.confidence,
                    segments: 16,
                    color: Brand.emerald,
                  ),
                ),
                const SizedBox(width: Gap.md),
                Text(
                  '${(best.confidence * 100).round()}%',
                  style: Typo.rowTitle.copyWith(fontSize: 14, color: Brand.emerald),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _TagRow extends StatelessWidget {
  const _TagRow({required this.rank, required this.text, required this.confidence});

  final int rank;
  final String text;
  final double confidence;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        child: Row(
          children: [
            SizedBox(
              width: 22,
              child: Text('$rank', style: Typo.statKey.copyWith(fontSize: 12)),
            ),
            Expanded(
              child: Text(
                text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Typo.rowTitle.copyWith(fontSize: 15),
              ),
            ),
            const SizedBox(width: Gap.md),
            SizedBox(
              width: 76,
              child: SegmentMeter(
                value: confidence,
                segments: 8,
                height: 7,
                color: Brand.emerald,
              ),
            ),
            SizedBox(
              width: 42,
              child: Text(
                '${(confidence * 100).round()}%',
                textAlign: TextAlign.right,
                style: Typo.statKey.copyWith(fontSize: 11.5, color: Tone.secondary),
              ),
            ),
          ],
        ),
      );
}
