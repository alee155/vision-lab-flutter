import 'package:flutter/material.dart';

import '../../../design/palette.dart';
import '../../../design/type.dart';
import '../../../design/widgets/controls.dart';
import '../../../design/widgets/surfaces.dart';
import '../ink_lab.dart';

/// Numbered readout sections below the writing canvas.
class InkSections extends StatelessWidget {
  const InkSections({super.key, required this.lab});

  final InkLab lab;

  @override
  Widget build(BuildContext context) {
    final others = lab.candidates.skip(1).take(5).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── 01 Result ─────────────────────────────────────────────────────
        NumberedHeader(
          index: '01',
          title: 'Result',
          trailing: lab.recognising ? const Tag('Reading') : null,
        ),
        _Headline(lab: lab),

        if (lab.recognitionError != null) ...[
          const SizedBox(height: Gap.md),
          Container(
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
                const Icon(Icons.error_outline_rounded,
                    size: 19, color: Brand.amber),
                const SizedBox(width: Gap.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Recognition failed',
                        style: Typo.rowTitle.copyWith(
                            fontSize: 14, color: Brand.amber),
                      ),
                      const SizedBox(height: 4),
                      SelectableText(
                        lab.recognitionError!,
                        style: Typo.body.copyWith(fontSize: 12.5),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],

        if (others.isNotEmpty) ...[
          const SizedBox(height: Gap.md),
          LabCard(margin: EdgeInsets.zero, children: [
            for (final (i, c) in others.indexed)
              _CandidateRow(rank: i + 2, text: c.text, score: c.score),
          ]),
        ],

        // ── 02 Ink ────────────────────────────────────────────────────────
        const NumberedHeader(index: '02', title: 'Ink'),
        StatGrid(rows: [
          [
            StatCell(label: 'Strokes', value: '${lab.strokeCount}'),
            StatCell(label: 'Points', value: '${lab.pointCount}'),
            StatCell(
              label: 'Pen down',
              value: lab.writingMs == 0
                  ? '—'
                  : (lab.writingMs / 1000).toStringAsFixed(1),
              unit: 's',
            ),
          ],
        ]),

        // ── 03 Model ──────────────────────────────────────────────────────
        const NumberedHeader(index: '03', title: 'Model'),
        LabCard(margin: EdgeInsets.zero, children: [
          DetailRow(label: 'Language', value: lab.language.name),
          DetailRow(label: 'Tag', value: lab.language.tag),
          DetailRow(
            label: 'Status',
            value: switch (lab.state) {
              ModelState.ready => 'On device',
              ModelState.missing => 'Not downloaded',
              ModelState.downloading => 'Downloading',
              ModelState.checking => 'Checking',
              ModelState.failed => 'Failed',
            },
            color: switch (lab.state) {
              ModelState.ready => Brand.emerald,
              ModelState.failed => Brand.amber,
              _ => Tone.primary,
            },
          ),
          if (lab.state == ModelState.downloading)
            DetailRow(
              label: 'Downloading for',
              value: '${lab.downloadElapsed.inMinutes}:'
                  '${(lab.downloadElapsed.inSeconds % 60).toString().padLeft(2, '0')}',
              color: Brand.amber,
            ),
          DetailRow(
            label: 'Recognition time',
            value: lab.latencyMs == 0
                ? '—'
                : '${lab.latencyMs.toStringAsFixed(0)} ms',
          ),
          DetailRow(label: 'Candidates', value: '${lab.candidates.length}'),
        ]),
      ],
    );
  }
}

/// The top candidate, given the room it deserves.
class _Headline extends StatelessWidget {
  const _Headline({required this.lab});

  final InkLab lab;

  @override
  Widget build(BuildContext context) {
    final best = lab.best;
    final waiting = lab.isEmpty || best == null;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 20),
      decoration: BoxDecoration(
        color: Ground.raised,
        borderRadius: BorderRadius.circular(Radii.card),
        border: Border.all(
          color: best == null ? Ground.line : Brand.red.withValues(alpha: 0.45),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            waiting ? 'Nothing read yet' : 'Best match',
            style: Typo.statKey,
          ),
          const SizedBox(height: Gap.sm),
          AnimatedSwitcher(
            duration: Motion.base,
            child: Text(
              waiting ? '—' : best.text,
              key: ValueKey(lab.revision),
              style: Typo.display.copyWith(
                fontSize: 34,
                color: waiting ? Tone.faint : Tone.primary,
              ),
            ),
          ),
          if (best != null) ...[
            const SizedBox(height: Gap.md + 2),
            Row(
              children: [
                Text(
                  'Score ${best.score.toStringAsFixed(3)}',
                  style: Typo.rowTitle.copyWith(fontSize: 13.5, color: Brand.red),
                ),
                const SizedBox(width: Gap.sm),
                Text(
                  '· lower is a better match',
                  style: Typo.statKey.copyWith(fontSize: 11.5),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}


class _CandidateRow extends StatelessWidget {
  const _CandidateRow({
    required this.rank,
    required this.text,
    required this.score,
  });

  final int rank;
  final String text;
  final double score;

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
            Text(
              score.toStringAsFixed(3),
              style: Typo.statKey.copyWith(fontSize: 12, color: Tone.secondary),
            ),
          ],
        ),
      );
}
