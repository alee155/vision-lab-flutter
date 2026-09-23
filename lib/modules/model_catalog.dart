import 'package:flutter/material.dart';

import '../design/palette.dart';
import '../features/face/face_screen.dart';
import '../features/ink/ink_screen.dart';
import '../features/object/object_screen.dart';

/// One ML Kit capability. Adding object detection later is an entry here plus
/// a screen — the shell, camera rig and coordinate maths are already shared.
class VisionModel {
  const VisionModel({
    required this.index,
    required this.name,
    required this.shortName,
    required this.summary,
    required this.icon,
    required this.accent,
    this.builder,
  });

  final String index;
  final String name;
  final String shortName;
  final String summary;
  final IconData icon;

  /// Each model owns a hue, so the deck reads as a family.
  final Color accent;

  /// Null until the module exists.
  final WidgetBuilder? builder;

  bool get ready => builder != null;
}

Widget _faceScreen(BuildContext context) => const FaceScreen();
Widget _inkScreen(BuildContext context) => const InkScreen();
Widget _objectScreen(BuildContext context) => const ObjectScreen();

const modelCatalog = <VisionModel>[
  VisionModel(
    index: '01',
    name: 'Face Detection',
    shortName: 'Face\nDetection',
    summary: 'Contours, landmarks, head pose and expression',
    icon: Icons.face_retouching_natural,
    accent: Brand.red,
    builder: _faceScreen,
  ),
  VisionModel(
    index: '02',
    name: 'Object Detection',
    shortName: 'Object\nDetection',
    summary: 'Boxes and stable tracking ids, five per frame',
    icon: Icons.view_in_ar,
    accent: Brand.amber,
    builder: _objectScreen,
  ),
  VisionModel(
    index: '03',
    name: 'Digital Ink',
    shortName: 'Digital\nInk',
    summary: 'Handwriting and sketches, recognised on device',
    icon: Icons.draw,
    accent: Brand.violet,
    builder: _inkScreen,
  ),
  VisionModel(
    index: '04',
    name: 'Image Labeling',
    shortName: 'Image\nLabeling',
    summary: 'Names what is in the frame, ~400 concepts',
    icon: Icons.sell,
    accent: Brand.emerald,
  ),
];
