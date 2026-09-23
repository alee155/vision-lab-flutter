import 'package:flutter/material.dart';
import 'package:google_ml_kit/google_ml_kit.dart' show FaceDetectorMode;

import '../../../design/palette.dart';
import '../../../design/type.dart';
import '../../../design/widgets/controls.dart';
import '../../../design/widgets/surfaces.dart';
import '../face_pipeline.dart';
import '../latency_ledger.dart';

/// Settings, with the measured price of every computed option. A cost only
/// appears once both sides of the comparison have actually been timed.
class SettingsSheet extends StatelessWidget {
  const SettingsSheet({super.key, required this.lab});

  final FaceLab lab;

  static Future<void> show(BuildContext context, FaceLab lab) => showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        barrierColor: const Color(0xB8060607),
        builder: (_) => ListenableBuilder(
          listenable: lab,
          builder: (context, _) => SettingsSheet(lab: lab),
        ),
      );

  String _cost(int bit) {
    final ms = lab.ledger.costOf(lab.config.optionKey, bit);
    return ms == null ? '—' : '+${ms.toStringAsFixed(ms >= 10 ? 0 : 1)} ms';
  }

  @override
  Widget build(BuildContext context) {
    final config = lab.config;
    return Container(
      constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.86),
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
                padding: const EdgeInsets.fromLTRB(0, 0, 0, Gap.xxl),
                children: [
                  const _Label('Accuracy'),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: Gap.lg),
                    child: LabSegmented<FaceDetectorMode>(
                      value: config.mode,
                      options: const [
                        (FaceDetectorMode.fast, 'Fast'),
                        (FaceDetectorMode.accurate, 'Accurate'),
                      ],
                      onChanged: (v) => lab.updateConfig(config.copyWith(mode: v)),
                    ),
                  ),
                  const _Label('Detection'),
                  LabCard(children: [
                    LabSlider(
                      label: 'Minimum face size',
                      subtitle: 'Share of the frame width a face must fill',
                      value: config.minFaceSize,
                      min: 0.05,
                      max: 0.50,
                      divisions: 9,
                      format: (v) => '${(v * 100).round()}%',
                      onChanged: (v) =>
                          lab.updateConfig(config.copyWith(minFaceSize: v)),
                    ),
                  ]),
                  const _Label('What the model returns'),
                  LabCard(children: [
                    _toggle('Contours', '133 outline points', config.contours,
                        _cost(OptionBit.contours),
                        (v) => lab.updateConfig(config.copyWith(contours: v))),
                    _toggle('Landmarks', 'Eyes, nose, mouth, ears', config.landmarks,
                        _cost(OptionBit.landmarks),
                        (v) => lab.updateConfig(config.copyWith(landmarks: v))),
                    _toggle('Expression', 'Smile and eye-open scores', config.classification,
                        _cost(OptionBit.classification),
                        (v) => lab.updateConfig(config.copyWith(classification: v))),
                    _toggle('Tracking', 'Stable ids across frames', config.tracking,
                        _cost(OptionBit.tracking),
                        (v) => lab.updateConfig(config.copyWith(tracking: v))),
                  ]),
                  const Padding(
                    padding: EdgeInsets.fromLTRB(Gap.lg + 4, Gap.md, Gap.lg + 4, 0),
                    child: Text(
                      'Costs are measured on this device. Toggle an option to '
                      'time it against the current setup.',
                      style: Typo.body,
                    ),
                  ),
                  const _Label('Overlay'),
                  LabCard(children: [
                    _toggle('Mesh', 'Draw contours over the face', config.drawMesh, '',
                        (v) => lab.updateConfig(config.copyWith(drawMesh: v))),
                    _toggle('Landmark points', 'Show the ten key points',
                        config.drawLandmarks, '',
                        (v) => lab.updateConfig(config.copyWith(drawLandmarks: v))),
                    _toggle('Mirror', 'Flip the front camera overlay', lab.mirrored, '',
                        (v) => lab.updateConfig(config.copyWith(mirrorOverlay: v))),
                  ]),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _toggle(String title, String sub, bool value, String cost,
          ValueChanged<bool> onChanged) =>
      LabRow(
        title: title,
        subtitle: sub,
        onTap: () => onChanged(!value),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (cost.isNotEmpty) ...[
              Text(cost, style: Typo.rowSub.copyWith(fontSize: 12.5)),
              const SizedBox(width: Gap.md),
            ],
            LabSwitch(value: value, onChanged: onChanged),
          ],
        ),
      );
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
