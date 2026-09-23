import 'package:flutter/material.dart';

import '../../../design/palette.dart';
import '../../../design/type.dart';
import '../../../design/widgets/surfaces.dart';
import '../ink_lab.dart';
import '../ink_language.dart';

/// Language picker. Each entry is a separate downloadable model, so the sheet
/// says which ones are already on the device.
class LanguageSheet extends StatelessWidget {
  const LanguageSheet({super.key, required this.lab});

  final InkLab lab;

  static Future<void> show(BuildContext context, InkLab lab) => showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        barrierColor: const Color(0xB8060607),
        builder: (_) => ListenableBuilder(
          listenable: lab,
          builder: (context, _) => LanguageSheet(lab: lab),
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
                  Expanded(child: Text('Language', style: Typo.sheetTitle)),
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
                  LabCard(children: [
                    for (final lang in inkLanguages)
                      LabRow(
                        title: lang.name,
                        subtitle: lang.note ?? lang.tag,
                        onTap: () {
                          lab.setLanguage(lang);
                          Navigator.of(context).pop();
                        },
                        trailing: lang == lab.language
                            ? const Icon(Icons.check_rounded,
                                size: 20, color: Brand.red)
                            : null,
                      ),
                  ]),
                  const Padding(
                    padding: EdgeInsets.fromLTRB(Gap.lg + 4, Gap.lg, Gap.lg + 4, 0),
                    child: Text(
                      'Each language is a separate download of a few megabytes. '
                      'Once it is on the device, recognition runs offline.',
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
