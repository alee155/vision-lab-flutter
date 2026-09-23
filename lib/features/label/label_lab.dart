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
import 'label_channel.dart';

enum LabelSource { live, still }

class LabelFrame {
  const LabelFrame({
    required this.tags,
    required this.sourceSize,
    required this.source,
  });

  static const empty =
      LabelFrame(tags: [], sourceSize: Size.zero, source: LabelSource.live);

  final List<ImageTag> tags;
  final Size sourceSize;
  final LabelSource source;

  ImageTag? get best => tags.isEmpty ? null : tags.first;
}

/// Drives image labeling. Unlike the other vision modules there is nothing to
/// draw over the frame — labeling describes the whole image, not regions of it.
class LabelLab extends ChangeNotifier {
  final VisionCamera camera = VisionCamera();
  final ImagePicker _picker = ImagePicker();

  ImageLabelerChannel? _labeler;
  double _threshold = 0.5;
  LabelFrame _frame = LabelFrame.empty;
  bool _busy = false;
  bool _disposed = false;
  String? _error;

  final List<double> _latencyTrace = <double>[];
  double _latencyEma = 0;
  double _fps = 0;
  int _framesInWindow = 0;
  final Stopwatch _fpsWindow = Stopwatch();
  int _framesProcessed = 0;
  int _peakTags = 0;
  final Set<String> _seen = <String>{};
  DateTime? _sessionStart;

  ui.Image? _still;
  String? _stillName;
  String? _stillPath;

  double get threshold => _threshold;
  LabelFrame get frame => _frame;
  ui.Image? get still => _still;
  String? get stillName => _stillName;
  bool get isStill => _frame.source == LabelSource.still && _still != null;
  String? get error => _error;

  List<double> get latencyTrace => List.unmodifiable(_latencyTrace);
  double get latencyMs => _latencyEma;
  double get fps => _fps;
  int get framesProcessed => _framesProcessed;
  int get tagCount => _frame.tags.length;
  int get peakTags => _peakTags;

  /// Distinct labels seen this session — a better measure of what the model can
  /// actually recognise than whatever happens to be on screen right now.
  List<String> get vocabularySeen => _seen.toList()..sort();

  Duration get uptime => _sessionStart == null
      ? Duration.zero
      : DateTime.now().difference(_sessionStart!);

  Future<void> boot() async {
    camera.addListener(_onCameraChanged);
    camera.onFrame = _onFrame;
    await camera.start(prefer: CameraLensDirection.back);
  }

  void _onCameraChanged() {
    if (!_disposed) notifyListeners();
  }

  ImageLabelerChannel _ensureLabeler() => _labeler ??=
      ImageLabelerChannel(DateTime.now().microsecondsSinceEpoch.toString());

  Future<void> setThreshold(double v) async {
    _threshold = v;
    _resetTelemetry();
    notifyListeners();
    if (isStill) unawaited(_runStill());
  }

  Future<void> _onFrame(InputImage image, Size rawSize) async {
    if (_busy || _disposed) return;
    _busy = true;
    final clock = Stopwatch()..start();
    try {
      final tags = await _ensureLabeler()
          .label(image: image, confidenceThreshold: _threshold);
      if (_disposed) return;
      clock.stop();
      _error = null;
      _publish(
        tags: tags,
        sourceSize: uprightSize(rawSize, image.metadata!.rotation),
        elapsed: clock.elapsedMicroseconds / 1000,
        source: LabelSource.live,
      );
    } on PlatformException catch (e) {
      if (!_disposed) _error = (e.message ?? e.code).trim();
      if (kDebugMode) debugPrint('[label] failed: $e');
    } catch (e) {
      if (kDebugMode) debugPrint('[label] failed: $e');
    } finally {
      _busy = false;
    }
  }

  void _publish({
    required List<ImageTag> tags,
    required Size sourceSize,
    required double elapsed,
    required LabelSource source,
  }) {
    _frame = LabelFrame(tags: tags, sourceSize: sourceSize, source: source);

    _framesProcessed++;
    _sessionStart ??= DateTime.now();
    if (tags.length > _peakTags) _peakTags = tags.length;
    for (final t in tags) {
      _seen.add(t.text);
    }

    _latencyEma = _latencyEma == 0 ? elapsed : _latencyEma * 0.82 + elapsed * 0.18;
    _latencyTrace.add(elapsed);
    if (_latencyTrace.length > 48) _latencyTrace.removeAt(0);

    if (source == LabelSource.live) {
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
    _peakTags = 0;
    _seen.clear();
    _sessionStart = null;
  }

  Future<void> togglePause() => camera.setPaused(camera.isRunning);

  Future<void> switchLens() async {
    await _exitStill();
    await camera.switchLens();
  }

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
      final tags = await _ensureLabeler().label(
        image: InputImage.fromFilePath(path),
        confidenceThreshold: _threshold,
      );
      clock.stop();
      if (_disposed) return;
      _error = null;
      _publish(
        tags: tags,
        sourceSize: Size(image.width.toDouble(), image.height.toDouble()),
        elapsed: clock.elapsedMicroseconds / 1000,
        source: LabelSource.still,
      );
    } catch (e) {
      if (!_disposed) {
        _error = e.toString();
        notifyListeners();
      }
      if (kDebugMode) debugPrint('[label] still failed: $e');
    }
  }

  Future<void> _exitStill() async {
    if (_still == null) return;
    _still?.dispose();
    _still = null;
    _stillName = null;
    _stillPath = null;
    _frame = LabelFrame.empty;
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
    _labeler?.close();
    _still?.dispose();
    super.dispose();
  }
}
