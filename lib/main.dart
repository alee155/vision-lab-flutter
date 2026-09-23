import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app/vision_lab_app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // FrameMapper assumes an upright frame; locking orientation keeps the
  // detection overlay aligned and the layout stable.
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(const VisionLabApp());
}
