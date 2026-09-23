import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/camera/vision_camera.dart';
import '../../core/geometry/frame_mapper.dart';
import 'face_config.dart';
import 'face_frame.dart';
import 'latency_ledger.dart';

/// Orchestrates camera → ML Kit → overlay, and keeps the running telemetry the
/// instrument panel reads from.
///
/// Frames are dropped while a detection is in flight rather than queued: on a
/// live signal, the newest frame is always the useful one, and queueing is how
/// these demos end up drawing boxes a second behind the subject.
class FaceLab extends ChangeNotifier {
  FaceLab();

  final VisionCamera camera = VisionCamera();
  final ImagePicker _picker = ImagePicker();
  final LatencyLedger ledger = LatencyLedger();

  FaceDetector? _detector;
  Object? _detectorSignature;

  FaceConfig _config = const FaceConfig();
  FaceFrame _frame = FaceFrame.empty;
  bool _detecting = false;
  bool _disposed = false;

  // ── Telemetry ────────────────────────────────────────────────────────────
  final List<double> _latencyTrace = <double>[];
  double _latencyEma = 0;
  double _fps = 0;
  int _framesInWindow = 0;
  final Stopwatch _fpsWindow = Stopwatch();
  int _framesProcessed = 0;
  int _blinks = 0;
  double _peakSmile = 0;
  int _peakFaces = 0;
  final Map<int, bool> _eyesClosed = <int, bool>{};
  Timer? _blinkFlash;
  bool _blinkActive = false;
  DateTime? _sessionStart;

  // ── Still-image mode ─────────────────────────────────────────────────────
  ui.Image? _still;
  String? _stillName;

  FaceConfig get config => _config;
  FaceFrame get frame => _frame;
  ui.Image? get still => _still;
  String? get stillName => _stillName;
  bool get isStill => _frame.source == FrameSource.still && _still != null;

  List<double> get latencyTrace => List.unmodifiable(_latencyTrace);
  double get latencyMs => _latencyEma;
  double get fps => _fps;
  int get framesProcessed => _framesProcessed;
  int get faceCount => _frame.faces.length;
  int get blinks => _blinks;
  double get peakSmile => _peakSmile;
  int get peakFaces => _peakFaces;
  bool get blinkActive => _blinkActive;

  Duration get uptime => _sessionStart == null
      ? Duration.zero
      : DateTime.now().difference(_sessionStart!);

  bool get mirrored =>
      _config.mirrorOverlay ?? camera.overlayShouldMirror;

  Future<void> boot() async {
    camera.addListener(_onCameraChanged);
    camera.onFrame = _onFrame;
    await camera.start();
  }

  void _onCameraChanged() {
    if (!_disposed) notifyListeners();
  }

  /// Blink detection is a hysteresis gate, not a threshold: a single noisy
  /// frame near the boundary would otherwise register dozens of blinks.
  void _trackExpressions(List<Face> faces) {
    for (final face in faces) {
      final smile = face.smilingProbability;
      if (smile != null && smile > _peakSmile) _peakSmile = smile;

      final left = face.leftEyeOpenProbability;
      final right = face.rightEyeOpenProbability;
      if (left == null || right == null) continue;

      final key = face.trackingId ?? -1;
      final wasClosed = _eyesClosed[key] ?? false;
      if (!wasClosed && left < 0.22 && right < 0.22) {
        _eyesClosed[key] = true;
      } else if (wasClosed && left > 0.60 && right > 0.60) {
        _eyesClosed[key] = false;
        _blinks++;
        _flashBlink();
      }
    }
  }

  void _flashBlink() {
    _blinkActive = true;
    _blinkFlash?.cancel();
    _blinkFlash = Timer(const Duration(milliseconds: 600), () {
      _blinkActive = false;
      if (!_disposed) notifyListeners();
    });
  }

  FaceDetector _ensureDetector() {
    if (_detector != null && _detectorSignature == _config.detectorSignature) {
      return _detector!;
    }
    _detector?.close();
    _detectorSignature = _config.detectorSignature;
    return _detector = FaceDetector(options: _config.options);
  }

  Future<void> updateConfig(FaceConfig next) async {
    final rebuild = next.detectorSignature != _config.detectorSignature;
    _config = next;
    if (rebuild) {
      _resetTelemetry();
      // The detector is deliberately NOT rebuilt here: closing it while a live
      // frame is still inside processImage crashes the platform channel. The
      // next _onFrame swaps it at a point where nothing is in flight.
      if (isStill) unawaited(_rerunStill());
    }
    notifyListeners();
  }

  Future<void> _onFrame(InputImage image, Size rawSize) async {
    if (_detecting || _disposed) return;
    _detecting = true;
    final clock = Stopwatch()..start();
    try {
      final faces = await _ensureDetector().processImage(image);
      if (_disposed) return;
      clock.stop();
      _publish(
        faces: faces,
        sourceSize: uprightSize(rawSize, image.metadata!.rotation),
        elapsed: clock.elapsedMicroseconds / 1000,
        source: FrameSource.live,
        mirrored: mirrored,
      );
    } catch (_) {
      // A dropped or malformed buffer is not worth interrupting the session
      // for; the next frame is milliseconds away.
    } finally {
      _detecting = false;
    }
  }

  void _publish({
    required List<Face> faces,
    required Size sourceSize,
    required double elapsed,
    required FrameSource source,
    required bool mirrored,
  }) {
    _frame = FaceFrame(
      faces: faces,
      sourceSize: sourceSize,
      latencyMs: elapsed,
      mirrored: mirrored,
      source: source,
    );

    _framesProcessed++;
    _sessionStart ??= DateTime.now();
    if (faces.length > _peakFaces) _peakFaces = faces.length;
    if (source == FrameSource.live) ledger.record(_config.optionKey, elapsed);
    _latencyEma = _latencyEma == 0 ? elapsed : _latencyEma * 0.82 + elapsed * 0.18;
    _latencyTrace.add(elapsed);
    if (_latencyTrace.length > 48) _latencyTrace.removeAt(0);

    if (source == FrameSource.live) {
      if (!_fpsWindow.isRunning) _fpsWindow.start();
      _framesInWindow++;
      if (_fpsWindow.elapsedMilliseconds >= 1000) {
        _fps = _framesInWindow * 1000 / _fpsWindow.elapsedMilliseconds;
        _framesInWindow = 0;
        _fpsWindow.reset();
      }
    }

    _trackExpressions(faces);

    if (!_disposed) notifyListeners();
  }

  void _resetTelemetry() {
    _latencyTrace.clear();
    _latencyEma = 0;
    _fps = 0;
    _framesInWindow = 0;
    _fpsWindow
      ..stop()
      ..reset();
    _framesProcessed = 0;
    _blinks = 0;
    _peakSmile = 0;
    _peakFaces = 0;
    _eyesClosed.clear();
    _sessionStart = null;
    ledger.clear();
  }

  void resetSession() {
    _resetTelemetry();
    notifyListeners();
  }

  Future<void> togglePause() async {
    await camera.setPaused(camera.isRunning);
  }

  Future<void> switchLens() async {
    await _exitStill();
    await camera.switchLens();
  }

  // ── Still images ─────────────────────────────────────────────────────────

  Future<void> loadStill() async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 2048,
    );
    if (picked == null || _disposed) return;

    await camera.suspend();
    final bytes = await picked.readAsBytes();
    final decoded = await decodeImageFromList(bytes);
    if (_disposed) {
      decoded.dispose();
      return;
    }

    _still?.dispose();
    _still = decoded;
    _stillName = picked.name;
    _resetTelemetry();
    await _runStill(picked.path, decoded);
  }

  Future<void> _runStill(String path, ui.Image image) async {
    final clock = Stopwatch()..start();
    final faces = await _ensureDetector().processImage(InputImage.fromFilePath(path));
    clock.stop();
    if (_disposed) return;
    _stillPath = path;
    _publish(
      faces: faces,
      sourceSize: Size(image.width.toDouble(), image.height.toDouble()),
      elapsed: clock.elapsedMicroseconds / 1000,
      source: FrameSource.still,
      mirrored: false,
    );
  }

  String? _stillPath;

  Future<void> _rerunStill() async {
    final path = _stillPath;
    final image = _still;
    if (path == null || image == null) return;
    await _runStill(path, image);
  }

  Future<void> _exitStill() async {
    if (_still == null) return;
    _still?.dispose();
    _still = null;
    _stillName = null;
    _stillPath = null;
    _frame = FaceFrame.empty;
    _resetTelemetry();
  }

  Future<void> resumeLive() async {
    await _exitStill();
    notifyListeners();
    await camera.start(prefer: camera.lens);
  }

  @override
  void dispose() {
    _disposed = true;
    _blinkFlash?.cancel();
    camera.removeListener(_onCameraChanged);
    camera.onFrame = null;
    camera.dispose();
    _detector?.close();
    _still?.dispose();
    super.dispose();
  }
}
