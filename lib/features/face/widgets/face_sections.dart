import 'package:flutter/material.dart';
import 'package:google_ml_kit/google_ml_kit.dart'
    show Face, FaceContour, FaceDetectorMode, FaceLandmark;

import '../../../design/palette.dart';
import '../../../design/widgets/controls.dart';
import '../../../design/widgets/surfaces.dart';
import '../face_pipeline.dart';

/// The numbered readout sections below the viewport.
class FaceSections extends StatelessWidget {
  const FaceSections({super.key, required this.lab});

  final FaceLab lab;

  static String _pct(double? v) => v == null ? '—' : '${(v * 100).round()}%';

  static String _clock(Duration d) =>
      '${d.inMinutes.toString().padLeft(2, '0')}:'
      '${(d.inSeconds % 60).toString().padLeft(2, '0')}';

  static int _contourPoints(Face f) => f.contours.values
      .whereType<FaceContour>()
      .fold(0, (sum, c) => sum + c.points.length);

  static int _landmarkCount(Face f) =>
      f.landmarks.values.whereType<FaceLandmark>().length;

  @override
  Widget build(BuildContext context) {
    final frame = lab.frame;
    final face = frame.primary;
    final on = lab.config.classification;

    double? p(double? v) => on ? v : null;
    final smile = p(face?.smilingProbability);
    final left = p(face?.leftEyeOpenProbability);
    final right = p(face?.rightEyeOpenProbability);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── 01 Signals ────────────────────────────────────────────────────
        NumberedHeader(
          index: '01',
          title: 'Signals',
          trailing: on ? null : const Tag('Off'),
        ),
        MeterRow(label: 'Smile', value: smile, display: _pct(smile)),
        const SizedBox(height: Gap.md),
        MeterRow(
          label: 'Left eye',
          value: left,
          display: _pct(left),
          flagged: left != null && left < 0.25,
        ),
        const SizedBox(height: Gap.md),
        MeterRow(
          label: 'Right eye',
          value: right,
          display: _pct(right),
          flagged: right != null && right < 0.25,
        ),

        // ── 02 Head pose ──────────────────────────────────────────────────
        const NumberedHeader(index: '02', title: 'Head pose'),
        PoseStrip(
          yaw: face?.headEulerAngleY,
          pitch: face?.headEulerAngleX,
          roll: face?.headEulerAngleZ,
        ),

        // ── 03 Session ────────────────────────────────────────────────────
        const NumberedHeader(index: '03', title: 'Session'),
        StatGrid(
          rows: [
            [
              StatCell(label: 'Faces', value: '${lab.faceCount}'),
              StatCell(
                label: 'Blinks',
                value: '${lab.blinks}',
                highlight: lab.blinkActive,
              ),
              StatCell(
                label: 'Peak smile',
                value: lab.peakSmile == 0 ? '—' : _pct(lab.peakSmile),
              ),
            ],
            [
              StatCell(label: 'Frames', value: '${lab.framesProcessed}'),
              StatCell(
                label: 'Latency',
                value: lab.latencyMs == 0
                    ? '—'
                    : lab.latencyMs.toStringAsFixed(1),
                unit: 'ms',
                trace: lab.latencyTrace,
              ),
              StatCell(
                label: 'Throughput',
                value: lab.fps == 0 ? '—' : lab.fps.toStringAsFixed(0),
                unit: 'fps',
              ),
            ],
          ],
        ),

        // ── 04 Detection ──────────────────────────────────────────────────
        NumberedHeader(
          index: '04',
          title: 'Detection',
          trailing: frame.faces.length > 1 ? Tag('${frame.faces.length}') : null,
        ),
        LabCard(margin: EdgeInsets.zero, children: [
          DetailRow(
            label: 'Tracking id',
            value: face?.trackingId?.toString() ??
                (lab.config.tracking ? '—' : 'Off'),
          ),
          DetailRow(
            label: 'Bounding box',
            value: face == null
                ? '—'
                : '${face.boundingBox.left.round()}, ${face.boundingBox.top.round()}',
          ),
          DetailRow(
            label: 'Box size',
            value: face == null
                ? '—'
                : '${face.boundingBox.width.round()} × ${face.boundingBox.height.round()}',
          ),
          DetailRow(
            label: 'Contour points',
            value: face == null
                ? '—'
                : (lab.config.contours ? '${_contourPoints(face)}' : 'Off'),
          ),
          DetailRow(
            label: 'Landmarks',
            value: face == null
                ? '—'
                : (lab.config.landmarks ? '${_landmarkCount(face)}' : 'Off'),
          ),
        ]),

        // ── Every face, when the frame holds more than one ────────────────
        if (frame.faces.length > 1) ...[
          const NumberedHeader(index: '05', title: 'All faces'),
          LabCard(margin: EdgeInsets.zero, children: [
            for (final (i, f) in frame.faces.indexed)
              FaceRow(index: i + 1, face: f, primary: identical(f, face)),
          ]),
        ],

        // ── Source ────────────────────────────────────────────────────────
        NumberedHeader(
          index: frame.faces.length > 1 ? '06' : '05',
          title: 'Source',
        ),
        LabCard(margin: EdgeInsets.zero, children: [
          DetailRow(
            label: 'Input',
            value: lab.isStill
                ? (lab.stillName ?? 'Photo')
                : (lab.camera.lens.name == 'front' ? 'Front camera' : 'Rear camera'),
          ),
          DetailRow(
            label: 'Resolution',
            value: frame.sourceSize.isEmpty
                ? '—'
                : '${frame.sourceSize.width.toInt()} × ${frame.sourceSize.height.toInt()}',
          ),
          DetailRow(label: 'Overlay mirrored', value: frame.mirrored ? 'Yes' : 'No'),
          DetailRow(
            label: 'Accuracy mode',
            value: lab.config.mode == FaceDetectorMode.fast ? 'Fast' : 'Accurate',
          ),
          DetailRow(
            label: 'Minimum face size',
            value: '${(lab.config.minFaceSize * 100).round()}%',
          ),
          DetailRow(label: 'Running for', value: _clock(lab.uptime)),
        ]),
      ],
    );
  }
}
