import 'package:flutter/material.dart';

import '../../design/palette.dart';
import '../../design/type.dart';
import '../../design/widgets/controls.dart';
import '../../design/widgets/surfaces.dart';
import 'ink_lab.dart';
import 'widgets/ink_canvas.dart';
import 'widgets/ink_sections.dart';
import 'widgets/language_sheet.dart';

/// Model 03 — digital ink recognition.
class InkScreen extends StatefulWidget {
  const InkScreen({super.key});

  @override
  State<InkScreen> createState() => _InkScreenState();
}

class _InkScreenState extends State<InkScreen> {
  final InkLab _lab = InkLab();

  @override
  void initState() {
    super.initState();
    _lab.boot();
  }

  @override
  void dispose() {
    _lab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Ground.base,
      body: Stack(
        children: [
          const Bloom(height: 420, top: -210, intensity: 0.75),
          SafeArea(
            bottom: false,
            child: ListenableBuilder(
              listenable: _lab,
              builder: (context, _) => Column(
                children: [
                  _header(),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(
                          Gap.lg, Gap.md, Gap.lg, Gap.xxl),
                      children: [
                        InkCanvas(lab: _lab),
                        InkSections(lab: _lab),
                      ],
                    ),
                  ),
                  _controlBar(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _header() {
    final (label, color) = switch (_lab.state) {
      ModelState.ready =>
        (_lab.recognising ? 'Reading' : 'Ready', Brand.violet),
      ModelState.downloading => ('Downloading', Brand.amber),
      ModelState.checking => ('Checking', Tone.faint),
      ModelState.missing => ('No model', Tone.faint),
      ModelState.failed => ('Error', Brand.amber),
    };

    return Padding(
      padding: const EdgeInsets.fromLTRB(Gap.lg, Gap.sm, Gap.lg, Gap.md),
      child: Row(
        children: [
          CircleButton(
            icon: Icons.arrow_back_rounded,
            onTap: () => Navigator.of(context).maybePop(),
          ),
          const SizedBox(width: Gap.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Model 03', style: Typo.eyebrow.copyWith(fontSize: 11)),
                const SizedBox(height: 2),
                Text('Digital Ink', style: Typo.navTitle),
              ],
            ),
          ),
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: _lab.state == ModelState.ready
                  ? [BoxShadow(color: color.withValues(alpha: 0.9), blurRadius: 8)]
                  : null,
            ),
          ),
          const SizedBox(width: Gap.sm),
          Text(label, style: Typo.tag.copyWith(color: color, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _controlBar() {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: Ground.sheet,
        border: Border(top: BorderSide(color: Ground.line)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: Gap.sm, vertical: Gap.sm),
          child: Row(
            children: [
              DeckButton(
                icon: Icons.undo_rounded,
                label: 'Undo',
                onTap: _lab.strokes.isEmpty ? null : _lab.undo,
              ),
              DeckButton(
                icon: Icons.clear_all_rounded,
                label: 'Clear',
                onTap: _lab.isEmpty ? null : _lab.clear,
              ),
              DeckButton(
                icon: Icons.auto_awesome_rounded,
                label: 'Read',
                active: _lab.recognising,
                onTap: _lab.canRecognise ? _lab.recognise : null,
                // A disabled button here reads as "broken"; the label says why.
              ),
              DeckButton(
                icon: Icons.translate_rounded,
                label: _lab.language.name,
                onTap: () => LanguageSheet.show(context, _lab),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
