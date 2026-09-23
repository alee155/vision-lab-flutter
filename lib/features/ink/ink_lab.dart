import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show PlatformException;
import 'package:flutter/painting.dart';
import 'package:google_ml_kit/google_ml_kit.dart' as mlkit;

import 'ink_channel.dart';
import 'ink_language.dart';

/// Whether the selected language's model is available on this device.
enum ModelState { checking, missing, downloading, ready, failed }

/// One drawn stroke, in canvas coordinates, with the timestamps ML Kit uses to
/// understand writing order and speed.
class PenStroke {
  PenStroke(this.startedAt);

  final int startedAt;
  final List<Offset> points = [];
  final List<int> times = [];

  void add(Offset p, int t) {
    points.add(p);
    times.add(t);
  }

  bool get isEmpty => points.isEmpty;
  int get length => points.length;
}

/// Drives the digital ink module: model download, stroke capture, recognition.
///
/// Recognition fires automatically a beat after you stop writing, which is how
/// handwriting input behaves everywhere else; the button is there to re-run it.
class InkLab extends ChangeNotifier {
  static const _idleBeforeRecognise = Duration(milliseconds: 900);

  /// ML Kit gives no way to cancel or time out a download, so this is only how
  /// long we keep claiming one is in flight before telling the user it stalled.
  static const _downloadLimit = Duration(minutes: 3);

  final mlkit.DigitalInkRecognizerModelManager _models =
      mlkit.DigitalInkRecognizerModelManager();

  InkRecognizerChannel? _recognizer;
  InkLanguage _language = inkLanguages.first;
  ModelState _state = ModelState.checking;
  String? _detail;

  final List<PenStroke> _strokes = [];
  PenStroke? _active;
  List<InkCandidate> _candidates = const [];
  double _latencyMs = 0;
  bool _recognising = false;
  String? _recognitionError;
  int _revision = 0;
  bool _disposed = false;
  Timer? _debounce;
  Size _canvasSize = Size.zero;
  Stopwatch? _penClock;
  DateTime? _downloadStartedAt;
  Timer? _ticker;
  Timer? _poll;

  InkLanguage get language => _language;
  ModelState get state => _state;
  String? get detail => _detail;
  List<PenStroke> get strokes => List.unmodifiable(_strokes);
  PenStroke? get active => _active;
  List<InkCandidate> get candidates => _candidates;

  /// Set when the last recognition attempt failed. Surfaced in the UI — a
  /// swallowed error here is indistinguishable from "the model found nothing".
  String? get recognitionError => _recognitionError;

  /// Increments on every completed recognition, so a repeated result still
  /// reads as a new value to AnimatedSwitcher.
  int get revision => _revision;
  double get latencyMs => _latencyMs;
  bool get recognising => _recognising;
  bool get isEmpty => _strokes.isEmpty && _active == null;

  /// How long the current (or last) download has been running. ML Kit reports
  /// no percentage, so elapsed time is the only honest progress signal there is.
  Duration get downloadElapsed => _downloadStartedAt == null
      ? Duration.zero
      : DateTime.now().difference(_downloadStartedAt!);
  bool get canRecognise => _state == ModelState.ready && !isEmpty && !_recognising;

  int get strokeCount => _strokes.length + (_active == null ? 0 : 1);

  int get pointCount =>
      _strokes.fold(0, (sum, s) => sum + s.length) + (_active?.length ?? 0);

  /// Milliseconds of pen-down time in this drawing.
  int get writingMs => _penClock?.elapsedMilliseconds ?? 0;

  InkCandidate? get best => _candidates.isEmpty ? null : _candidates.first;

  Future<void> boot() => _syncModel();

  // ── Model ────────────────────────────────────────────────────────────────

  Future<void> _syncModel() async {
    _set(ModelState.checking);
    try {
      final downloaded = await _models.isModelDownloaded(_language.tag);
      if (_disposed) return;
      _set(downloaded ? ModelState.ready : ModelState.missing);
    } catch (e) {
      _set(ModelState.failed, e.toString());
    }
  }

  Future<void> downloadModel() async {
    if (_state == ModelState.downloading) return;
    _downloadStartedAt = DateTime.now();
    _set(ModelState.downloading);
    _watchDownload();
    try {
      final ok = await _models.downloadModel(_language.tag, isWifiRequired: false);
      if (_disposed || _state != ModelState.downloading) return;
      _stopWatching();
      _set(
        ok ? ModelState.ready : ModelState.failed,
        ok ? null : 'The download did not complete.',
      );
      if (ok && !isEmpty) unawaited(recognise());
    } catch (e) {
      if (_disposed) return;
      _stopWatching();
      _set(ModelState.failed, e.toString());
    }
  }

  /// Two timers stand in for the progress callback ML Kit does not provide: one
  /// to keep the elapsed clock ticking, and one to notice a download that has
  /// finished natively without the call returning.
  void _watchDownload() {
    _ticker = Timer.periodic(const Duration(milliseconds: 500), (_) {
      if (_disposed || _state != ModelState.downloading) return;
      if (downloadElapsed > _downloadLimit) {
        _stopWatching();
        _set(
          ModelState.failed,
          'Still running after three minutes. The connection may be slow or the '
          'download may have stalled — it is safe to retry.',
        );
        return;
      }
      notifyListeners();
    });

    _poll = Timer.periodic(const Duration(seconds: 4), (_) async {
      if (_disposed || _state != ModelState.downloading) return;
      try {
        if (await _models.isModelDownloaded(_language.tag)) {
          if (_disposed || _state != ModelState.downloading) return;
          _stopWatching();
          _set(ModelState.ready);
          if (!isEmpty) unawaited(recognise());
        }
      } catch (_) {
        // A failed check mid-download tells us nothing; the next tick retries.
      }
    });
  }

  void _stopWatching() {
    _ticker?.cancel();
    _poll?.cancel();
    _ticker = null;
    _poll = null;
  }

  Future<void> setLanguage(InkLanguage next) async {
    if (next == _language) return;
    _stopWatching();
    _downloadStartedAt = null;
    _language = next;
    // The recogniser is bound to one language, so it has to be rebuilt.
    await _recognizer?.close();
    _recognizer = null;
    _candidates = const [];
    _latencyMs = 0;
    notifyListeners();
    await _syncModel();
  }

  InkRecognizerChannel _ensureRecognizer() => _recognizer ??=
      InkRecognizerChannel(DateTime.now().microsecondsSinceEpoch.toString());

  // ── Drawing ──────────────────────────────────────────────────────────────

  void setCanvasSize(Size size) => _canvasSize = size;

  void penDown(Offset p) {
    _debounce?.cancel();
    _penClock ??= Stopwatch();
    if (!_penClock!.isRunning) _penClock!.start();
    _active = PenStroke(_penClock!.elapsedMilliseconds)
      ..add(p, _penClock!.elapsedMilliseconds);
    notifyListeners();
  }

  void penMove(Offset p) {
    final stroke = _active;
    if (stroke == null) return;
    // Skip sub-pixel jitter: fewer, cleaner points recognise better.
    if (stroke.points.isNotEmpty && (stroke.points.last - p).distance < 1.5) return;
    stroke.add(p, _penClock?.elapsedMilliseconds ?? 0);
    notifyListeners();
  }

  void penUp() {
    final stroke = _active;
    _active = null;
    if (stroke != null && !stroke.isEmpty) _strokes.add(stroke);
    _penClock?.stop();
    notifyListeners();

    if (_strokes.isNotEmpty && _state == ModelState.ready) {
      _debounce?.cancel();
      _debounce = Timer(_idleBeforeRecognise, recognise);
    }
  }

  void undo() {
    _debounce?.cancel();
    if (_strokes.isEmpty) return;
    _strokes.removeLast();
    _candidates = const [];
    notifyListeners();
    if (_strokes.isNotEmpty && _state == ModelState.ready) {
      _debounce = Timer(_idleBeforeRecognise, recognise);
    }
  }

  void clear() {
    _debounce?.cancel();
    _strokes.clear();
    _active = null;
    _candidates = const [];
    _recognitionError = null;
    _latencyMs = 0;
    _penClock = null;
    notifyListeners();
  }

  // ── Recognition ──────────────────────────────────────────────────────────

  Future<void> recognise() async {
    if (_strokes.isEmpty || _state != ModelState.ready || _recognising) return;
    _recognising = true;
    _recognitionError = null;
    notifyListeners();

    final strokes = [
      for (final stroke in _strokes)
        <String, dynamic>{
          'points': [
            for (var i = 0; i < stroke.points.length; i++)
              <String, dynamic>{
                'x': stroke.points[i].dx,
                'y': stroke.points[i].dy,
                't': stroke.times[i],
              },
          ],
        },
    ];

    final clock = Stopwatch()..start();
    try {
      // Telling the recogniser how big the writing area is improves its
      // candidates, but it is also the argument most likely to be rejected by a
      // platform, so a failure falls back to a plain call before giving up.
      List<InkCandidate> candidates;
      try {
        candidates = await _recogniseWith(strokes, withArea: true);
      } catch (first) {
        if (kDebugMode) {
          debugPrint('[ink] recognition with writing area failed: $first');
        }
        candidates = await _recogniseWith(strokes, withArea: false);
      }

      clock.stop();
      if (_disposed) return;
      _candidates = candidates;
      _latencyMs = clock.elapsedMicroseconds / 1000;
      _revision++;
      if (candidates.isEmpty) {
        _recognitionError = 'The model returned no candidates for these strokes.';
      }
    } catch (e) {
      if (_disposed) return;
      _candidates = const [];
      _latencyMs = 0;
      _recognitionError = _describe(e);
      if (kDebugMode) debugPrint('[ink] recognition failed: $e');
    } finally {
      _recognising = false;
      if (!_disposed) notifyListeners();
    }
  }

  Future<List<InkCandidate>> _recogniseWith(
    List<Map<String, dynamic>> strokes, {
    required bool withArea,
  }) {
    return _ensureRecognizer().recognize(
      model: _language.tag,
      strokes: strokes,
      context: (!withArea || _canvasSize.isEmpty)
          ? null
          : <String, dynamic>{
              'preContext': null,
              'writingArea': <String, dynamic>{
                'width': _canvasSize.width,
                'height': _canvasSize.height,
              },
            },
    );
  }

  /// Platform errors arrive as PlatformException with the useful part split
  /// across three fields; flatten them into something a human can act on.
  static String _describe(Object e) {
    if (e is PlatformException) {
      final parts = [e.message, e.details?.toString()]
          .whereType<String>()
          .where((p) => p.isNotEmpty)
          .toSet();
      return parts.isEmpty ? e.code : '${parts.join(' — ')} (${e.code})';
    }
    if (e is NoSuchMethodError) {
      return 'The recogniser returned nothing at all. This usually means the '
          'model is present but could not be loaded — try re-downloading it.';
    }
    return e.toString();
  }

  void _set(ModelState state, [String? detail]) {
    _state = state;
    _detail = detail;
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _debounce?.cancel();
    _stopWatching();
    _recognizer?.close();
    super.dispose();
  }
}
