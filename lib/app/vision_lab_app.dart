import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../design/palette.dart';
import '../design/type.dart';
import '../features/home/home_screen.dart';

class VisionLabApp extends StatelessWidget {
  const VisionLabApp({super.key});

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: Ground.base,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: MaterialApp(
        title: 'Vision Lab',
        debugShowCheckedModeBanner: false,
        theme: _theme,
        home: const HomeScreen(),
      ),
    );
  }
}

/// Material supplies routing, sheets and icons only — every surface and text
/// style comes from the design layer.
final ThemeData _theme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.dark,
  fontFamily: 'Poppins',
  scaffoldBackgroundColor: Ground.base,
  splashFactory: NoSplash.splashFactory,
  highlightColor: Colors.transparent,
  colorScheme: const ColorScheme.dark(
    primary: Brand.red,
    onPrimary: Colors.white,
    secondary: Brand.amber,
    surface: Ground.raised,
    onSurface: Tone.primary,
    outline: Ground.line,
  ),
  textTheme: const TextTheme(
    titleMedium: Typo.rowTitle,
    bodyMedium: Typo.body,
    labelSmall: Typo.eyebrow,
  ),
);
