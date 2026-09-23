import 'package:flutter/material.dart';

import '../../../design/palette.dart';
import '../../../design/type.dart';
import '../../../design/widgets/controls.dart';
import '../../../design/widgets/surfaces.dart';
import '../label_lab.dart';

/// Image labeler settings. The only knob the base model has is the confidence
/// floor, so the sheet spends its space explaining what that floor does.
class LabelSettingsSheet extends StatelessWidget {
  const LabelSettingsSheet({super.key, required this.lab});

  final LabelLab lab;

  static Future<void> show(BuildContext context, LabelLab lab) =>
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        barrierColor: const Color(0xB8060607),
        builder: (_) => ListenableBuilder(
          listenable: lab,
          builder: (context, _) => LabelSettingsSheet(lab: lab),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.8),
      decoration: const BoxDecoration(
        color: Ground.sheet,
        borderRadius: BorderRadius.vertical(top: Radius.circular(Radii.sheet)),
        border: Border(top: BorderSide(color: Ground.lineStrong)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 38,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0x2EFFFFFF),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(Gap.lg + 2, Gap.sm, Gap.lg, Gap.lg),
              child: Row(
                children: [
                  Expanded(child: Text('Settings', style: Typo.sheetTitle)),
                  CircleButton(
                    icon: Icons.close_rounded,
                    size: 34,
                    onTap: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            Flexible(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(0, 0, 0, Gap.xl),
                children: [
                  const _Label('Confidence floor'),
                  LabCard(children: [
                    LabSlider(
                      label: 'Minimum confidence',
                      subtitle: 'Labels below this are not returned at all',
                      value: lab.threshold,
                      min: 0.1,
                      max: 0.9,
                      divisions: 16,
                      color: Brand.emerald,
                      format: (v) => '${(v * 100).round()}%',
                      onChanged: lab.setThreshold,
                    ),
                  ]),
                  const Padding(
                    padding: EdgeInsets.fromLTRB(Gap.lg + 4, Gap.md, Gap.lg + 4, 0),
                    child: Text(
                      'Lower it to see what the model is hesitating over — the '
                      'near-misses are usually more revealing than the winner. '
                      'Raise it for a feed that only reports what it is sure of.',
                      style: Typo.body,
                    ),
                  ),
                  const _Label('Model'),
                  const LabCard(children: [
                    DetailRow(label: 'Type', value: 'Base'),
                    DetailRow(label: 'Vocabulary', value: '~400 concepts'),
                    DetailRow(label: 'Bundled', value: 'Yes'),
                  ]),
                  const Padding(
                    padding: EdgeInsets.fromLTRB(Gap.lg + 4, Gap.md, Gap.lg + 4, 0),
                    child: Text(
                      'The base model covers everyday concepts — animals, food, '
                      'plants, vehicles, activities. It labels the whole image '
                      'rather than locating anything in it, which is what makes '
                      'it the right tool for "what am I looking at?".',
                      style: Typo.body,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(Gap.lg + 4, Gap.xl, Gap.lg, Gap.md),
        child: Text(text, style: Typo.eyebrow),
      );
}
