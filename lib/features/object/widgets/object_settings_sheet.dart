import 'package:flutter/material.dart';

import '../../../design/palette.dart';
import '../../../design/type.dart';
import '../../../design/widgets/controls.dart';
import '../../../design/widgets/surfaces.dart';
import '../object_lab.dart';

/// Object detector settings. The detection mode is deliberately not a switch —
/// ML Kit's stream and single modes are for live and static input respectively,
/// so the source decides and the sheet explains it.
class ObjectSettingsSheet extends StatelessWidget {
  const ObjectSettingsSheet({super.key, required this.lab});

  final ObjectLab lab;

  static Future<void> show(BuildContext context, ObjectLab lab) =>
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        barrierColor: const Color(0xB8060607),
        builder: (_) => ListenableBuilder(
          listenable: lab,
          builder: (context, _) => ObjectSettingsSheet(lab: lab),
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
                  const _Label('Detector'),
                  LabCard(children: [
                    LabRow(
                      title: 'Classify objects',
                      subtitle: 'Adds a coarse category label to each object',
                      onTap: () => lab.setClassify(!lab.classify),
                      trailing: LabSwitch(
                        value: lab.classify,
                        color: Brand.amber,
                        onChanged: lab.setClassify,
                      ),
                    ),
                    LabRow(
                      title: 'Multiple objects',
                      subtitle: 'Off detects only the most prominent object',
                      onTap: () => lab.setMultiple(!lab.multiple),
                      trailing: LabSwitch(
                        value: lab.multiple,
                        color: Brand.amber,
                        onChanged: lab.setMultiple,
                      ),
                    ),
                  ]),
                  const Padding(
                    padding: EdgeInsets.fromLTRB(Gap.lg + 4, Gap.md, Gap.lg + 4, 0),
                    child: Text(
                      'The base model recognises five broad categories — fashion '
                      'goods, food, home goods, places and plants. Anything else '
                      'is still tracked, just not named.',
                      style: Typo.body,
                    ),
                  ),
                  const _Label('Mode'),
                  LabCard(children: [
                    DetailRow(label: 'Current', value: lab.mode),
                    const DetailRow(label: 'Live camera', value: 'stream'),
                    const DetailRow(label: 'Photo', value: 'single'),
                  ]),
                  const Padding(
                    padding: EdgeInsets.fromLTRB(Gap.lg + 4, Gap.md, Gap.lg + 4, 0),
                    child: Text(
                      'Stream mode tracks objects across frames and keeps their '
                      'ids stable; single mode is slower and more thorough, and '
                      'assigns no ids. The source picks the right one.',
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
