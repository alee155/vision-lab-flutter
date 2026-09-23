import 'package:flutter/painting.dart';

/// Near-black ground, a single crimson brand, and one hue per model so the
/// playground reads as a family rather than a menu.
abstract final class Ground {
  static const base = Color(0xFF09090A);
  static const raised = Color(0xFF131315);
  static const tile = Color(0xFF17171A);
  static const sheet = Color(0xFF0F0F11);
  static const line = Color(0x12FFFFFF);
  static const lineStrong = Color(0x1FFFFFFF);
  static const veil = Color(0x1FFFFFFF);
}

abstract final class Tone {
  static const primary = Color(0xFFFFFFFF);
  static const secondary = Color(0x85FFFFFF);
  static const tertiary = Color(0x6BFFFFFF);
  static const faint = Color(0x52FFFFFF);
}

abstract final class Brand {
  static const red = Color(0xFFE23A2E);
  static const redLift = Color(0xFFFF6B5A);
  static const amber = Color(0xFFF0A030);
  static const violet = Color(0xFF8B5CF6);
  static const emerald = Color(0xFF16B981);
}

abstract final class Radii {
  static const tile = 18.0;
  static const card = 22.0;
  static const feature = 26.0;
  static const sheet = 32.0;
  static const stage = 34.0;
  static const chip = 12.0;
}

abstract final class Gap {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 18.0;
  static const xl = 24.0;
  static const xxl = 32.0;
}

abstract final class Motion {
  static const fast = Duration(milliseconds: 160);
  static const base = Duration(milliseconds: 280);
  static const slow = Duration(milliseconds: 460);
}
