import 'package:flutter/material.dart';

import '../../core/camera/vision_camera.dart';
import '../../core/vision/vision_viewport.dart';
import '../../design/palette.dart';
import '../../design/type.dart';
import '../../design/widgets/controls.dart';
import '../../design/widgets/surfaces.dart';
import 'label_lab.dart';
import 'widgets/label_sections.dart';
import 'widgets/label_settings_sheet.dart';

/// Model 04 — image labeling.
class LabelScreen extends StatefulWidget {
  const LabelScreen({super.key});

  @override
  State<LabelScreen> createState() => _LabelScreenState();
}

class _LabelScreenState extends State<LabelScreen> with WidgetsBindingObserver {
  final LabelLab _lab = LabelLab();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _lab.boot();
  }

  /// Camera hardware has to be released when the app backgrounds, or Android
  /// hands it to the next app and the session never recovers.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_lab.isStill) return;
    switch (state) {
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
      case AppLifecycleState.detached:
        _lab.camera.suspend();
      case AppLifecycleState.resumed:
        _lab.camera.start(prefer: _lab.camera.lens);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _lab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Ground.base,
      body: Stack(
        children: [
          const Bloom(
            color: Brand.emerald,
            height: 420,
            top: -210,
            intensity: 0.5,
          ),
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
                        VisionViewport(
                          camera: _lab.camera,
                          // Labeling describes the whole frame, so nothing is
                          // drawn over it.
                          sourceSize: _lab.frame.sourceSize,
                          isStill: _lab.isStill,
                          still: _lab.still,
                          latencyMs: _lab.latencyMs,
                          count: _lab.tagCount,
                          noun: 'label',
                          accent: Brand.emerald,
                        ),
                        LabelSections(lab: _lab),
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
    final (label, color) = switch (_lab.camera.status) {
      RigStatus.running => (_lab.isStill ? 'Photo' : 'Live', Brand.emerald),
      RigStatus.paused => ('Hold', Brand.amber),
      RigStatus.opening => ('Opening', Brand.violet),
      RigStatus.denied ||
      RigStatus.failed ||
      RigStatus.unavailable => ('Error', Brand.amber),
      RigStatus.idle => (_lab.isStill ? 'Photo' : 'Idle', Tone.faint),
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
                Text('Model 04', style: Typo.eyebrow.copyWith(fontSize: 11)),
                const SizedBox(height: 2),
                Text('Image Labeling', style: Typo.navTitle),
              ],
            ),
          ),
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: _lab.camera.isRunning
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
    final camera = _lab.camera;
    final held = camera.status == RigStatus.paused;

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
                icon: Icons.cameraswitch_rounded,
                label: 'Lens',
                accent: Brand.emerald,
                onTap: camera.hasMultipleLenses && !_lab.isStill
                    ? _lab.switchLens
                    : null,
              ),
              DeckButton(
                icon: held ? Icons.play_arrow_rounded : Icons.pause_rounded,
                label: held ? 'Resume' : 'Hold',
                accent: Brand.emerald,
                active: held,
                onTap: (camera.isRunning || held) && !_lab.isStill
                    ? _lab.togglePause
                    : null,
              ),
              DeckButton(
                icon: _lab.isStill
                    ? Icons.videocam_rounded
                    : Icons.photo_library_rounded,
                label: _lab.isStill ? 'Live' : 'Photo',
                accent: Brand.emerald,
                active: _lab.isStill,
                onTap: _lab.isStill ? _lab.resumeLive : _lab.loadStill,
              ),
              DeckButton(
                icon: Icons.tune_rounded,
                label: 'Settings',
                accent: Brand.emerald,
                onTap: () => LabelSettingsSheet.show(context, _lab),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
