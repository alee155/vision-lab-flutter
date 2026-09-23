import 'package:flutter/foundation.dart';
import 'package:google_ml_kit/google_ml_kit.dart';

import 'latency_ledger.dart';

/// Detector and overlay settings.
///
/// Fields that change what the *model computes* force the detector to be
/// rebuilt; fields that only change what is *drawn* do not. The settings sheet
/// reflects that split, and shows the measured cost of each computed option.
@immutable
class FaceConfig {
  const FaceConfig({
    this.mode = FaceDetectorMode.fast,
    this.classification = true,
    this.landmarks = true,
    this.contours = true,
    this.tracking = true,
    this.minFaceSize = 0.15,
    this.drawMesh = true,
    this.drawLandmarks = true,
    this.mirrorOverlay,
  });

  final FaceDetectorMode mode;
  final bool classification;
  final bool landmarks;
  final bool contours;
  final bool tracking;
  final double minFaceSize;

  final bool drawMesh;
  final bool drawLandmarks;

  /// Overrides the platform mirroring heuristic. Null trusts the rig.
  final bool? mirrorOverlay;

  Object get detectorSignature => Object.hash(
        mode, classification, landmarks, contours, tracking, minFaceSize);

  /// Bitmask identifying this option-set for [LatencyLedger].
  int get optionKey =>
      (contours ? OptionBit.contours : 0) |
      (landmarks ? OptionBit.landmarks : 0) |
      (classification ? OptionBit.classification : 0) |
      (tracking ? OptionBit.tracking : 0) |
      (mode == FaceDetectorMode.accurate ? OptionBit.accurate : 0);

  FaceDetectorOptions get options => FaceDetectorOptions(
        performanceMode: mode,
        enableClassification: classification,
        enableLandmarks: landmarks,
        enableContours: contours,
        enableTracking: tracking,
        minFaceSize: minFaceSize,
      );

  FaceConfig copyWith({
    FaceDetectorMode? mode,
    bool? classification,
    bool? landmarks,
    bool? contours,
    bool? tracking,
    double? minFaceSize,
    bool? drawMesh,
    bool? drawLandmarks,
    bool? mirrorOverlay,
    bool clearMirrorOverride = false,
  }) =>
      FaceConfig(
        mode: mode ?? this.mode,
        classification: classification ?? this.classification,
        landmarks: landmarks ?? this.landmarks,
        contours: contours ?? this.contours,
        tracking: tracking ?? this.tracking,
        minFaceSize: minFaceSize ?? this.minFaceSize,
        drawMesh: drawMesh ?? this.drawMesh,
        drawLandmarks: drawLandmarks ?? this.drawLandmarks,
        mirrorOverlay:
            clearMirrorOverride ? null : (mirrorOverlay ?? this.mirrorOverlay),
      );
}
