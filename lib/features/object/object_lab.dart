import 'dart:async';
import 'dart:ui' as ui;

import 'package:camera/camera.dart' show CameraLensDirection;
import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:flutter/services.dart' show PlatformException;
import 'package:google_ml_kit/google_ml_kit.dart' show InputImage;
import 'package:image_picker/image_picker.dart';

import '../../core/camera/vision_camera.dart';
import '../../core/geometry/frame_mapper.dart';
import 'object_channel.dart';

enum ObjectSource { live, still }

/// One completed detection pass, with everything the overlay needs to place it.
class ObjectFrame {
  const ObjectFrame({
    required this.things,
    required this.sourceSize,
    required this.mirrored,
    required this.source,
  });

  static const empty = ObjectFrame(
    things: [],
    sourceSize: Size.zero,
    mirrored: false,
    source: ObjectSource.live,
  );

  final List<DetectedThing> things;
  final Size sourceSize;
  final bool mirrored;
  final ObjectSource source;

  BoxFit get fit => source == ObjectSource.live ? BoxFit.cover : BoxFit.contain;

  /// The largest object is the subject; everything else is background.
  DetectedThing? get primary => things.isEmpty
      ? null
      : things.reduce((a, b) => b.area > a.area ? b : a);
}

/// Drives object detection: camera → ML Kit → overlay, plus session telemetry.
class ObjectLab extends ChangeNotifier {
  final VisionCamera camera = VisionCamera();
  final ImagePicker _picker = ImagePicker();

  ObjectDetectorChannel? _detector;
  String? _detectorSignature;

  bool _classify = true;
  bool _multiple = true;
  ObjectFrame _frame = ObjectFrame.empty;
  bool _detecting = false;
  bool _disposed = false;
  String? _error;

  final List<double> _latencyTrace = <double>[];
  double _latencyEma = 0;
  double _fps = 0;
  int _framesInWindow = 0;
  final Stopwatch _fpsWindow = Stopwatch();
  int _framesProcessed = 0;
  int _peakObjects = 0;
  final Set<int> _seenIds = <int>{};
  DateTime? _sessionStart;

  ui.Image? _still;
  String? _stillName;
  String? _stillPath;

  bool get classify => _classify;
  bool get multiple => _multiple;
  ObjectFrame get frame => _frame;
  ui.Image? get still => _still;
  String? get stillName => _stillName;
  bool get isStill => _frame.source == ObjectSource.still && _still != null;
  String? get error => _error;

  List<double> get latencyTrace => List.unmodifiable(_latencyTrace);
  double get latencyMs => _latencyEma;
  double get fps => _fps;
  int get framesProcessed => _framesProcessed;
  int get objectCount => _frame.things.length;
  int get peakObjects => _peakObjects;
  int get uniqueIds => _seenIds.length;

  Duration get uptime => _sessionStart == null
      ? Duration.zero
      : DateTime.now().difference(_sessionStart!);

  bool get mirrored => camera.overlayShouldMirror;

  /// ML Kit's two modes are not interchangeable: stream tracks objects across
  /// frames and is meant for a live feed, single is more thorough and meant for
  /// one static image. The source decides, so neither is ever misapplied.
  String get mode => isStill ? 'single' : 'stream';

  Future<void> boot() async {
    camera.addListener(_onCameraChanged);
    camera.onFrame = _onFrame;
    await camera.start(prefer: CameraLensDirection.back);
  }

  void _onCameraChanged() {
    if (!_disposed) notifyListeners();
  }

  Map<String, dynamic> _options({required bool single}) => <String, dynamic>{
        'mode': single ? 'single' : 'stream',
        'type': 'base',
        'classify': _classify,
        'multiple': _multiple,
      };

  ObjectDetectorChannel _ensureDetector({required bool single}) {
    final signature = '${single ? 's' : 'm'}$_classify$_multiple';
    if (_detector != null && _detectorSignature == signature) return _detector!;
    _detector?.close();
    _detectorSignature = signature;
    return _detector =
        ObjectDetectorChannel(DateTime.now().microsecondsSinceEpoch.toString());
  }

  Future<void> setClassify(bool v) async {
    _classify = v;
    _resetTelemetry();
    notifyListeners();
    if (isStill) unawaited(_rerunStill());
  }

  Future<void> setMultiple(bool v) async {
    _multiple = v;
    _resetTelemetry();
    notifyListeners();
    if (isStill) unawaited(_rerunStill());
  }

  Future<void> _onFrame(InputImage image, Size rawSize) async {
    if (_detecting || _disposed) return;
    _detecting = true;
    final clock = Stopwatch()..start();
    try {
      final things = await _ensureDetector(single: false)
          .detect(image: image, options: _options(single: false));
      if (_disposed) return;
      clock.stop();
      _error = null;
      _publish(
        things: things,
        sourceSize: uprightSize(rawSize, image.metadata!.rotation),
        elapsed: clock.elapsedMicroseconds / 1000,
        source: ObjectSource.live,
        mirrored: mirrored,
      );
    } on PlatformException catch (e) {
      if (!_disposed) _error = (e.message ?? e.code).trim();
      if (kDebugMode) debugPrint('[object] detection failed: $e');
    } catch (e) {
      if (kDebugMode) debugPrint('[object] detection failed: $e');
    } finally {
      _detecting = false;
    }
  }

  void _publish({
    required List<DetectedThing> things,
    required Size sourceSize,
    required double elapsed,
    required ObjectSource source,
    required bool mirrored,
  }) {
    _frame = ObjectFrame(
      things: things,
      sourceSize: sourceSize,
      mirrored: mirrored,
      source: source,
    );

    _framesProcessed++;
    _sessionStart ??= DateTime.now();
    if (things.length > _peakObjects) _peakObjects = things.length;
    for (final t in things) {
      if (t.trackingId != null) _seenIds.add(t.trackingId!);
    }

    _latencyEma = _latencyEma == 0 ? elapsed : _latencyEma * 0.82 + elapsed * 0.18;
    _latencyTrace.add(elapsed);
    if (_latencyTrace.length > 48) _latencyTrace.removeAt(0);

    if (source == ObjectSource.live) {
      if (!_fpsWindow.isRunning) _fpsWindow.start();
      _framesInWindow++;
      if (_fpsWindow.elapsedMilliseconds >= 1000) {
        _fps = _framesInWindow * 1000 / _fpsWindow.elapsedMilliseconds;
        _framesInWindow = 0;
        _fpsWindow.reset();
      }
    }

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
    _peakObjects = 0;
    _seenIds.clear();
    _sessionStart = null;
  }

  Future<void> togglePause() => camera.setPaused(camera.isRunning);

  Future<void> switchLens() async {
    await _exitStill();
    await camera.switchLens();
  }

  // ── Still images ─────────────────────────────────────────────────────────

  Future<void> loadStill() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery, maxWidth: 2048);
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
    _stillPath = picked.path;
    _resetTelemetry();
    await _runStill();
  }

  Future<void> _runStill() async {
    final path = _stillPath;
    final image = _still;
    if (path == null || image == null) return;

    final clock = Stopwatch()..start();
    try {
      final things = await _ensureDetector(single: true).detect(
        image: InputImage.fromFilePath(path),
        options: _options(single: true),
      );
      clock.stop();
      if (_disposed) return;
      _error = null;
      _publish(
        things: things,
        sourceSize: Size(image.width.toDouble(), image.height.toDouble()),
        elapsed: clock.elapsedMicroseconds / 1000,
        source: ObjectSource.still,
        mirrored: false,
      );
    } catch (e) {
      if (!_disposed) {
        _error = e.toString();
        notifyListeners();
      }
      if (kDebugMode) debugPrint('[object] still detection failed: $e');
    }
  }

  Future<void> _rerunStill() => _runStill();

  Future<void> _exitStill() async {
    if (_still == null) return;
    _still?.dispose();
    _still = null;
    _stillName = null;
    _stillPath = null;
    _frame = ObjectFrame.empty;
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
    camera.removeListener(_onCameraChanged);
    camera.onFrame = null;
    camera.dispose();
    _detector?.close();
    _still?.dispose();
    super.dispose();
  }
}
