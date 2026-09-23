import 'package:flutter/foundation.dart';

/// A recognizer language, as ML Kit tags them.
///
/// Every tag here is downloaded on demand — the models are not bundled, which
/// is why this module needs a network connection once per language.
@immutable
class InkLanguage {
  const InkLanguage(this.tag, this.name, {this.note});

  /// BCP-47 tag ML Kit identifies the model by.
  final String tag;
  final String name;
  final String? note;

  @override
  bool operator ==(Object other) => other is InkLanguage && other.tag == tag;

  @override
  int get hashCode => tag.hashCode;
}

const inkLanguages = <InkLanguage>[
  InkLanguage('en-US', 'English'),
  InkLanguage('es-ES', 'Spanish'),
  InkLanguage('fr-FR', 'French'),
  InkLanguage('de-DE', 'German'),
  InkLanguage('it-IT', 'Italian'),
  InkLanguage('pt-BR', 'Portuguese'),
  InkLanguage('hi-IN', 'Hindi'),
  InkLanguage('ar', 'Arabic'),
  InkLanguage('ru-RU', 'Russian'),
  InkLanguage('ja-JP', 'Japanese'),
  InkLanguage('ko-KR', 'Korean'),
  InkLanguage('zh-Hani-CN', 'Chinese'),
  // Two models that recognise drawings rather than words — the most fun way to
  // see what the recogniser is actually doing.
  InkLanguage('zxx-Zsye-x-emoji', 'Emoji', note: 'Draw a shape, get an emoji'),
  InkLanguage('zxx-Zsym-x-autodraw', 'AutoDraw', note: 'Sketch an object, get its name'),
];
