 import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart' show WidgetsBinding;
import 'package:flutter/services.dart';
import 'package:google_ml_kit/google_ml_kit.dart';

/// Lifecycle of the capture rig, surfaced verbatim in the UI status strip.
enum RigStatus { idle, opening, running, paused, denied, unavailable, failed }

typedef FrameHandler = void Function(InputImage image, Size rawSize);

/// Owns the camera hardware and hands upright [InputImage]s to whichever
/// vision module is mounted. Kept free of any face-specific knowledge so the
/// object-detection and image-labeling modules can reuse it unchanged.
class VisionCamera extends ChangeNotifier {
  CameraController? _controller;
  List<CameraDescription> _cameras = const [];
  int _index = 0;
  RigStatus _status = RigStatus.idle;
  String? _detail;
  FrameHandler? _onFrame;
  bool _busy = false;
  bool _disposed = false;

  CameraController? get controller => _controller;
  RigStatus get status => _status;
  String? get detail => _detail;
  bool get isRunning => _status == RigStatus.running;
  bool get hasMultipleLenses => _cameras.length > 1;

  CameraDescription? get description =>
      _cameras.isEmpty ? null : _cameras[_index];

  CameraLensDirection get lens =>
      description?.lensDirection ?? CameraLensDirection.back;

  /// Android renders the front preview un-mirrored relative to the buffer ML
  /// Kit sees; iOS mirrors both consistently. See [FaceConfig.mirrorOverlay]
  /// for the manual override.
  bool get overlayShouldMirror =>
      Platform.isAndroid && lens == CameraLensDirection.front;

  Size get previewSize {
    final p = _controller?.value.previewSize;
    if (p == null) return Size.zero;
    // previewSize is reported in sensor (landscape) orientation.
    return Size(p.height, p.width);
  }

  set onFrame(FrameHandler? handler) => _onFrame = handler;

  Future<void> start({  prefer = CameraLensDirection.front}) async {
    if (_busy) return;
    _busy = true;
    try {
      _set(RigStatus.opening);

      if (_cameras.isEmpty) {
        _cameras = await availableCameras();
        if (_cameras.isEmpty) {
          _set(RigStatus.unavailable, 'No camera hardware reported.');
          return;
        }
        final preferred = _cameras.indexWhere((c) => c.lensDirection == prefer);
        _index = preferred >= 0 ? preferred : 0;
      }

      await _open();
    } on CameraException catch (e) {
      _reportCameraException(e);
    } catch (e) {
      _set(RigStatus.failed, e.toString());
    } finally {
      _busy = false;
    }
  }

  /// `initialize()` is what actually raises the OS permission prompt, and it
  /// reports a refusal through these codes — which is why the app carries no
  /// separate permission dependency.
  void _reportCameraException(CameraException e) {
    switch (e.code) {
      case 'CameraAccessDenied':
      case 'CameraAccessDeniedWithoutPrompt':
      case 'CameraAccessRestricted':
      case 'AudioAccessDenied':
        _set(RigStatus.denied, e.description);
      default:
        _set(RigStatus.failed, '${e.code}: ${e.description ?? ''}'.trim());
    }
  }

  Future<void> _open() async {
    await _teardown();

    final controller = CameraController(
      _cameras[_index],
      ResolutionPreset.high,
      enableAudio: false,
      // The only two formats ML Kit accepts directly, so we never pay for a
      // pixel-format conversion on the frame path.
      imageFormatGroup:
          Platform.isAndroid ? ImageFormatGroup.nv21 : ImageFormatGroup.bgra8888,
    );
    _controller = controller;

    await controller.initialize();
    if (_disposed) return;
    await controller.lockCaptureOrientation(DeviceOrientation.portraitUp);
    await controller.startImageStream(_handleImage);
    if (_disposed) return;
    _set(RigStatus.running);
  }

  void _handleImage(CameraImage image) {
    final handler = _onFrame;
    final camera = description;
    if (handler == null || camera == null || _status != RigStatus.running) return;

    final input = _toInputImage(image, camera);
    if (input == null) return;
    handler(input, Size(image.width.toDouble(), image.height.toDouble()));
  }

  Future<void> switchLens() async {
    if (_cameras.length < 2 || _busy) return;
    _busy = true;
    try {
      _index = (_index + 1) % _cameras.length;
      _set(RigStatus.opening);
      await _open();
    } on CameraException catch (e) {
      _reportCameraException(e);
    } finally {
      _busy = false;
    }
  }

  /// Freezes the frame path without releasing the hardware, so resuming is
  /// instant and the last overlay stays on screen.
  Future<void> setPaused(bool paused) async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;
    if (paused && _status == RigStatus.running) {
      _set(RigStatus.paused);
      await controller.stopImageStream();
    } else if (!paused && _status == RigStatus.paused) {
      await controller.startImageStream(_handleImage);
      _set(RigStatus.running);
    }
  }

  /// Fully releases hardware — used when the app backgrounds.
  Future<void> suspend() async {
    await _teardown();
    if (_status == RigStatus.running || _status == RigStatus.paused) {
      _set(RigStatus.idle);
    }
  }

  Future<void> _teardown() async {
    final controller = _controller;
    _controller = null;
    if (controller == null) return;

    // Detach first and let the tree actually drop CameraPreview before the
    // controller dies. Disposing in the same turn leaves a build able to call
    // buildPreview() on a dead controller, which throws every frame.
    if (!_disposed) notifyListeners();
    try {
      await WidgetsBinding.instance.endOfFrame;
    } catch (_) {
      // No binding in a test; nothing to wait for.
    }

    try {
      if (controller.value.isStreamingImages) {
        await controller.stopImageStream();
      }
    } catch (_) {
      // Stream may already be torn down by the platform; nothing to recover.
    }
    try {
      await controller.dispose();
    } catch (_) {
      // Already disposed by a hot restart or a platform teardown.
    }
  }

  void _set(RigStatus status, [String? detail]) {
    _status = status;
    _detail = detail;
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _onFrame = null;
    _teardown();
    super.dispose();
  }
}

const _deviceRotation = <DeviceOrientation, int>{
  DeviceOrientation.portraitUp: 0,
  DeviceOrientation.landscapeLeft: 90,
  DeviceOrientation.portraitDown: 180,
  DeviceOrientation.landscapeRight: 270,
};

/// Wraps a [CameraImage] as an ML Kit [InputImage] without copying pixels.
InputImage? _toInputImage(CameraImage image, CameraDescription camera) {
  final sensor = camera.sensorOrientation;

  final InputImageRotation? rotation;
  if (Platform.isIOS) {
    rotation = InputImageRotationValue.fromRawValue(sensor);
  } else {
    // Portrait-locked, so the device contributes no extra rotation.
    final compensation = _deviceRotation[DeviceOrientation.portraitUp]!;
    final degrees = camera.lensDirection == CameraLensDirection.front
        ? (sensor + compensation) % 360
        : (sensor - compensation + 360) % 360;
    rotation = InputImageRotationValue.fromRawValue(degrees);
  }
  if (rotation == null) return null;

  final format = InputImageFormatValue.fromRawValue(image.format.raw);
  if (format == null) return null;
  if (Platform.isAndroid && format != InputImageFormat.nv21) return null;
  if (Platform.isIOS && format != InputImageFormat.bgra8888) return null;
  if (image.planes.length != 1) return null;

  final plane = image.planes.first;
  return InputImage.fromBytes(
    bytes: plane.bytes,
    metadata: InputImageMetadata(
      size: Size(image.width.toDouble(), image.height.toDouble()),
      rotation: rotation,
      format: format,
      bytesPerRow: plane.bytesPerRow,
    ),
  );
}
