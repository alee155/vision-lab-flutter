import 'package:flutter/painting.dart';

import 'palette.dart';

/// Poppins is bundled rather than fetched, so Android and iOS render
/// identically and nothing reflows on first launch.
const _family = 'Poppins';

abstract final class Typo {
  static const eyebrow = TextStyle(
    fontFamily: _family,
    fontSize: 12,
    height: 1.2,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.5,
    color: Tone.tertiary,
  );

  static const display = TextStyle(
    fontFamily: _family,
    fontSize: 32,
    height: 1.1,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.9,
    color: Tone.primary,
  );

  static const featureTitle = TextStyle(
    fontFamily: _family,
    fontSize: 24,
    height: 1.18,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.5,
    color: Tone.primary,
  );

  static const sheetTitle = TextStyle(
    fontFamily: _family,
    fontSize: 22,
    height: 1.2,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.4,
    color: Tone.primary,
  );

  static const navTitle = TextStyle(
    fontFamily: _family,
    fontSize: 17,
    height: 1.2,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.2,
    color: Tone.primary,
  );

  static const rowTitle = TextStyle(
    fontFamily: _family,
    fontSize: 16,
    height: 1.25,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.1,
    color: Tone.primary,
  );

  static const rowSub = TextStyle(
    fontFamily: _family,
    fontSize: 12,
    height: 1.35,
    fontWeight: FontWeight.w500,
    color: Tone.faint,
  );

  static const body = TextStyle(
    fontFamily: _family,
    fontSize: 13.5,
    height: 1.5,
    fontWeight: FontWeight.w500,
    color: Tone.secondary,
  );

  static const button = TextStyle(
    fontFamily: _family,
    fontSize: 15,
    height: 1.2,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.1,
    color: Tone.primary,
  );

  /// Big percentage readouts. Tight tracking is most of what makes a number
  /// look designed rather than printed.
  static const statValue = TextStyle(
    fontFamily: _family,
    fontSize: 27,
    height: 1.0,
    fontWeight: FontWeight.w700,
    letterSpacing: -1.1,
    color: Tone.primary,
    fontFeatures: [FontFeature.tabularFigures()],
  );

  static const statKey = TextStyle(
    fontFamily: _family,
    fontSize: 11.5,
    height: 1.2,
    fontWeight: FontWeight.w600,
    color: Tone.tertiary,
  );

  static const poseValue = TextStyle(
    fontFamily: _family,
    fontSize: 19,
    height: 1.0,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.5,
    color: Tone.primary,
    fontFeatures: [FontFeature.tabularFigures()],
  );

  static const chip = TextStyle(
    fontFamily: _family,
    fontSize: 13.5,
    height: 1.2,
    fontWeight: FontWeight.w700,
    color: Tone.primary,
  );

  static const tag = TextStyle(
    fontFamily: _family,
    fontSize: 11.5,
    height: 1.2,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.3,
    color: Tone.faint,
  );
}
