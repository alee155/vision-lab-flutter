import 'package:flutter/services.dart';

/// One recognition candidate.
///
/// ML Kit's scores are unbounded and inverted: lower means a better match, and
/// some models do not populate them at all.
class InkCandidate {
  const InkCandidate({required this.text, required this.score});

  final String text;
  final double score;
}

/// Speaks to the ML Kit digital-ink plugin over its method channel directly.
///
/// The published Dart wrapper assigns the platform's `score` straight into a
/// non-nullable `double`, so a candidate whose score crosses the channel as an
/// int throws `type 'int' is not a subtype of type 'double'` — and because the
/// throw happens mid-loop it discards every candidate, not just that one.
/// Recognition itself is fine; only the parsing is broken. Reading the reply
/// here with `num.toDouble()` sidesteps it, and costs nothing else: the
/// arguments below are exactly what the wrapper sends.
class InkRecognizerChannel {
  const InkRecognizerChannel(this.id);

  static const _channel = MethodChannel('google_mlkit_digital_ink_recognizer');

  /// Identifies the cached native recogniser instance.
  final String id;

  Future<List<InkCandidate>> recognize({
    required String model,
    required List<Map<String, dynamic>> strokes,
    Map<String, dynamic>? context,
  }) async {
    final reply = await _channel.invokeMethod<dynamic>(
      'vision#startDigitalInkRecognizer',
      <String, dynamic>{
        'id': id,
        'ink': <String, dynamic>{'strokes': strokes},
        'context': context,
        'model': model,
      },
    );
    if (reply is! List) return const [];

    final candidates = <InkCandidate>[];
    for (final row in reply) {
      if (row is! Map) continue;
      final text = row['text'];
      if (text is! String || text.isEmpty) continue;
      candidates.add(
        InkCandidate(text: text, score: (row['score'] as num?)?.toDouble() ?? 0),
      );
    }
    return candidates;
  }

  Future<void> close() => _channel.invokeMethod<void>(
        'vision#closeDigitalInkRecognizer',
        <String, dynamic>{'id': id},
      );
}
