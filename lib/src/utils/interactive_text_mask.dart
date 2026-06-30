/// Predicate used by [MaskToken] to decide whether a character is accepted.
typedef MaskTokenPredicate = bool Function(String character);

/// Normalizer used by [MaskToken] before a character is written to the result.
typedef MaskTokenNormalizer = String Function(String character);

/// A token definition used by [InteractiveTextMask].
///
/// Tokens describe the editable positions in a mask. Literal mask characters
/// such as `.`, `/`, `-`, `(`, and `)` are inserted automatically by the
/// formatter.
class MaskToken {
  /// Creates a mask token.
  ///
  /// [accepts] decides whether a user-provided character can fill the token.
  /// [normalize] can transform accepted characters before they are stored.
  const MaskToken({
    required this.accepts,
    this.normalize = _identity,
  });

  /// Accepts ASCII digits `0..9`.
  static const digit = MaskToken(accepts: _isAsciiDigit);

  /// Accepts ASCII letters `A..Z` and `a..z`, normalizing to uppercase.
  static const letter = MaskToken(
    accepts: _isAsciiLetter,
    normalize: _asciiUppercase,
  );

  /// Accepts ASCII letters and digits, normalizing letters to uppercase.
  static const alphanumeric = MaskToken(
    accepts: _isAsciiAlphanumeric,
    normalize: _asciiUppercase,
  );

  /// Accepts any non-empty single code-unit character.
  ///
  /// Empty strings are rejected. Like the other built-in tokens, this token is
  /// designed for simple input-mask positions rather than grapheme-cluster
  /// processing.
  static const any = MaskToken(accepts: _acceptAny);

  /// Returns whether [character] can fill this token.
  final MaskTokenPredicate accepts;

  /// Normalizes [character] before it is written.
  ///
  /// Normalizers must return exactly one UTF-16 code unit. Returning an empty
  /// string or multiple code units breaks the one-token-to-one-character mask
  /// contract and causes [InteractiveTextMask] to throw a [StateError].
  final MaskTokenNormalizer normalize;

  static String _identity(String character) => character;

  static bool _acceptAny(String character) => character.isNotEmpty;

  static bool _isAsciiDigit(String character) {
    if (character.length != 1) {
      return false;
    }
    final codeUnit = character.codeUnitAt(0);
    return codeUnit >= 48 && codeUnit <= 57;
  }

  static bool _isAsciiLetter(String character) {
    if (character.length != 1) {
      return false;
    }
    final codeUnit = character.codeUnitAt(0);
    return (codeUnit >= 65 && codeUnit <= 90) ||
        (codeUnit >= 97 && codeUnit <= 122);
  }

  static bool _isAsciiAlphanumeric(String character) {
    return _isAsciiDigit(character) || _isAsciiLetter(character);
  }

  static String _asciiUppercase(String character) {
    if (character.length != 1) {
      return character;
    }
    final codeUnit = character.codeUnitAt(0);
    if (codeUnit >= 97 && codeUnit <= 122) {
      return String.fromCharCode(codeUnit - 32);
    }
    return character;
  }
}

/// Text value and selection used by [InteractiveTextMask].
///
/// This type deliberately avoids Flutter, DOM, Angular, or terminal APIs. UI
/// adapters can convert from their native text-editing model into this value,
/// call [InteractiveTextMask.apply] or [InteractiveTextMask.applyEdit], and then
/// write the returned text and selection back to the component.
class MaskedTextValue {
  /// Creates a text value with an optional selection.
  ///
  /// When either selection edge is omitted, it is copied from the other edge.
  /// When both are omitted, the selection is collapsed at the end of [text].
  /// Selection values are clamped to the text bounds and normalized so
  /// [selectionStart] is never greater than [selectionEnd].
  MaskedTextValue({
    required this.text,
    int? selectionStart,
    int? selectionEnd,
  })  : selectionStart = _normalizedSelectionStart(
          text,
          selectionStart,
          selectionEnd,
        ),
        selectionEnd = _normalizedSelectionEnd(
          text,
          selectionStart,
          selectionEnd,
        );

  /// Creates a collapsed selection at [offset], or at the end of [text].
  MaskedTextValue.collapsed(String text, {int? offset})
      : this(
          text: text,
          selectionStart: offset ?? text.length,
          selectionEnd: offset ?? text.length,
        );

  /// Current text.
  final String text;

  /// Inclusive selection start.
  final int selectionStart;

  /// Exclusive selection end.
  final int selectionEnd;

  /// Whether the selection is collapsed.
  bool get isCollapsed => selectionStart == selectionEnd;

  /// Returns a copy with selected fields replaced.
  MaskedTextValue copyWith({
    String? text,
    int? selectionStart,
    int? selectionEnd,
  }) {
    final nextText = text ?? this.text;
    return MaskedTextValue(
      text: nextText,
      selectionStart: selectionStart ?? this.selectionStart,
      selectionEnd: selectionEnd ?? this.selectionEnd,
    );
  }

  @override
  String toString() {
    return 'MaskedTextValue(text: $text, selectionStart: $selectionStart, '
        'selectionEnd: $selectionEnd)';
  }

  static int _normalizedSelectionStart(
    String text,
    int? selectionStart,
    int? selectionEnd,
  ) {
    final start = _clampOffset(
      selectionStart ?? selectionEnd ?? text.length,
      text.length,
    );
    final end = _clampOffset(
      selectionEnd ?? selectionStart ?? text.length,
      text.length,
    );
    return start <= end ? start : end;
  }

  static int _normalizedSelectionEnd(
    String text,
    int? selectionStart,
    int? selectionEnd,
  ) {
    final start = _clampOffset(
      selectionStart ?? selectionEnd ?? text.length,
      text.length,
    );
    final end = _clampOffset(
      selectionEnd ?? selectionStart ?? text.length,
      text.length,
    );
    return start <= end ? end : start;
  }

  static int _clampOffset(int value, int length) {
    if (value < 0) {
      return 0;
    }
    if (value > length) {
      return length;
    }
    return value;
  }
}

/// Result returned by [InteractiveTextMask.apply].
class MaskedTextResult extends MaskedTextValue {
  /// Creates a mask result.
  MaskedTextResult({
    required super.text,
    required this.rawText,
    required this.isComplete,
    super.selectionStart,
    super.selectionEnd,
  });

  /// Text after removing mask literals and rejected characters.
  final String rawText;

  /// Whether [rawText] filled every editable token in the mask.
  final bool isComplete;
}

/// Framework-agnostic interactive text mask formatter.
///
/// The formatter is pure Dart and does not import `dart:html`, Flutter, or any
/// UI framework. It can be used from browser, VM, server-side rendering, tests,
/// AngularDart, Flutter, or any custom UI adapter.
///
/// The formatter is optimized for short-to-medium input masks such as CPF,
/// CNPJ, CEP, phone numbers, document codes, and identifiers. [apply] and
/// [applyEdit] reprocess the current text to keep cursor mapping deterministic,
/// which is appropriate for UI input masks but not intended for very long text
/// documents.
///
/// Example for a web input adapter:
///
/// ```dart
/// final mask = InteractiveTextMask.cpf();
/// final result = mask.applyEdit(
///   oldValue: previousValue,
///   newValue: MaskedTextValue(
///     text: input.value ?? '',
///     selectionStart: input.selectionStart,
///     selectionEnd: input.selectionEnd,
///   ),
/// );
///
/// input.value = result.text;
/// input.setSelectionRange(result.selectionStart, result.selectionEnd);
/// ```
class InteractiveTextMask {
  /// Creates a formatter from a [pattern].
  ///
  /// Editable positions are characters present in [tokens]. Characters not
  /// present in [tokens] are treated as literals and inserted automatically.
  /// Prefix a character with [escapeCharacter] to force it to be treated as a
  /// literal even when it is also a token character.
  ///
  /// When [eager] is `true`, the next literal is inserted as soon as the user
  /// completes the token group before it. This matches common interactive input
  /// behavior for CPF/CNPJ fields.
  InteractiveTextMask({
    required this.pattern,
    Map<String, MaskToken>? tokens,
    this.eager = true,
    this.escapeCharacter = r'\',
  }) : tokens = Map<String, MaskToken>.unmodifiable(
          tokens ?? defaultTokens,
        ) {
    if (escapeCharacter.length != 1) {
      throw ArgumentError.value(
        escapeCharacter,
        'escapeCharacter',
        'Must be exactly one UTF-16 code unit.',
      );
    }

    _parts = _compilePattern(pattern, this.tokens, escapeCharacter);
    var tokenCount = 0;
    for (final part in _parts) {
      if (part.isToken) {
        tokenCount++;
      }
    }
    if (tokenCount == 0) {
      throw ArgumentError.value(
        pattern,
        'pattern',
        'Must contain at least one editable token.',
      );
    }
    _tokenCount = tokenCount;
  }

  /// Creates a CPF mask using the pattern `000.000.000-00`.
  factory InteractiveTextMask.cpf({bool eager = true}) {
    return InteractiveTextMask(
      pattern: '000.000.000-00',
      eager: eager,
      tokens: const <String, MaskToken>{
        '0': MaskToken.digit,
      },
    );
  }

  /// Creates a CNPJ mask.
  ///
  /// When [alphanumeric] is `true`, the first twelve positions accept digits
  /// and ASCII letters, while the last two positions accept only digits:
  /// `AA.AAA.AAA/AAAA-00`.
  ///
  /// When [alphanumeric] is `false`, every editable position accepts only
  /// digits: `00.000.000/0000-00`.
  factory InteractiveTextMask.cnpj({
    bool alphanumeric = true,
    bool eager = true,
  }) {
    return InteractiveTextMask(
      pattern: alphanumeric ? 'AA.AAA.AAA/AAAA-00' : '00.000.000/0000-00',
      eager: eager,
      tokens: <String, MaskToken>{
        '0': MaskToken.digit,
        if (alphanumeric) 'A': MaskToken.alphanumeric,
      },
    );
  }

  /// Creates a numeric CNPJ mask using `00.000.000/0000-00`.
  factory InteractiveTextMask.cnpjNumeric({bool eager = true}) {
    return InteractiveTextMask.cnpj(alphanumeric: false, eager: eager);
  }

  /// Creates an alphanumeric CNPJ mask using `AA.AAA.AAA/AAAA-00`.
  factory InteractiveTextMask.cnpjAlphanumeric({bool eager = true}) {
    return InteractiveTextMask.cnpj(alphanumeric: true, eager: eager);
  }

  /// Default token definitions for generic masks.
  ///
  /// - `0`: ASCII digit.
  /// - `A`: ASCII letter or digit, normalized to uppercase.
  /// - `S`: ASCII letter, normalized to uppercase.
  /// - `x`: ASCII letter or digit, normalized to uppercase.
  /// - `*`: any non-empty single code-unit character.
  static const Map<String, MaskToken> defaultTokens = <String, MaskToken>{
    '0': MaskToken.digit,
    'A': MaskToken.alphanumeric,
    'S': MaskToken.letter,
    'x': MaskToken.alphanumeric,
    '*': MaskToken.any,
  };

  /// Mask pattern.
  final String pattern;

  /// Token definitions used by [pattern].
  final Map<String, MaskToken> tokens;

  /// Whether literals should be inserted eagerly while typing.
  final bool eager;

  /// Character used to escape token characters in [pattern].
  final String escapeCharacter;

  /// Maximum amount of raw characters accepted by this mask.
  int get maxRawLength => _tokenCount;

  late final List<_CompiledMaskPart> _parts;
  late final int _tokenCount;

  /// Applies the mask to [value] and maps the selection to the masked text.
  ///
  /// This method only receives the current value, so it uses conservative
  /// cursor mapping that does not push a manually positioned cursor across an
  /// eagerly inserted literal. For framework formatters that receive both the
  /// old and new value, prefer [applyEdit].
  MaskedTextResult apply(MaskedTextValue value) {
    return _apply(value, eagerForCursor: false);
  }

  /// Applies the mask to an edit operation.
  ///
  /// [oldValue] is the previous value accepted by the UI component and
  /// [newValue] is the value produced by the platform after the user's edit.
  /// Providing both values lets the formatter distinguish insertion from
  /// deletion, avoiding common cursor traps around literals such as `.` and
  /// `-`.
  MaskedTextResult applyEdit({
    required MaskedTextValue oldValue,
    required MaskedTextValue newValue,
  }) {
    final isInsertion = newValue.text.length > oldValue.text.length;
    return _apply(newValue, eagerForCursor: isInsertion);
  }

  /// Applies the mask to [text] and returns only the formatted text.
  ///
  /// Set [eager] to override this formatter's interactive literal behavior for
  /// one call. A common choice for display-only formatting is `eager: false`.
  String format(String text, {bool? eager}) {
    return _formatRaw(unmask(text), eager: eager ?? this.eager);
  }

  /// Removes literals and rejected characters from [text].
  String unmask(String text) {
    return _extractRaw(text, text.length);
  }

  MaskedTextResult _apply(
    MaskedTextValue value, {
    required bool eagerForCursor,
  }) {
    final rawText = unmask(value.text);
    final text = _formatRaw(rawText, eager: eager);
    final start = _maskedOffsetFor(
      value.text,
      value.selectionStart,
      eagerForCursor: eagerForCursor,
    );
    final end = _maskedOffsetFor(
      value.text,
      value.selectionEnd,
      eagerForCursor: eagerForCursor,
    );

    return MaskedTextResult(
      text: text,
      rawText: rawText,
      isComplete: rawText.length == _tokenCount,
      selectionStart: start > text.length ? text.length : start,
      selectionEnd: end > text.length ? text.length : end,
    );
  }

  int _maskedOffsetFor(
    String text,
    int offset, {
    required bool eagerForCursor,
  }) {
    final clampedOffset = MaskedTextValue._clampOffset(offset, text.length);
    final rawBeforeOffset = _extractRaw(text, clampedOffset);
    return _formatRaw(rawBeforeOffset, eager: eagerForCursor).length;
  }

  String _extractRaw(String text, int limit) {
    final clampedLimit = MaskedTextValue._clampOffset(limit, text.length);
    final raw = StringBuffer();
    var textIndex = 0;
    var partIndex = 0;

    while (textIndex < clampedLimit && partIndex < _parts.length) {
      final part = _parts[partIndex];
      final character = text[textIndex];

      if (!part.isToken) {
        if (character == part.character) {
          textIndex++;
        }
        partIndex++;
        continue;
      }

      final token = part.token!;
      if (token.accepts(character)) {
        raw.write(_normalizeTokenValue(token, character));
        partIndex++;
      }
      textIndex++;
    }

    return raw.toString();
  }

  String _formatRaw(String raw, {required bool eager}) {
    final result = StringBuffer();
    var rawIndex = 0;

    for (var partIndex = 0;
        partIndex < _parts.length && rawIndex <= raw.length;
        partIndex++) {
      final part = _parts[partIndex];

      if (!part.isToken) {
        if (rawIndex < raw.length ||
            (eager &&
                rawIndex == raw.length &&
                rawIndex > 0 &&
                part.hasTokenAfter)) {
          result.write(part.character);
        }
        continue;
      }

      if (rawIndex >= raw.length) {
        break;
      }

      final token = part.token!;
      final rawCharacter = raw[rawIndex];
      if (token.accepts(rawCharacter)) {
        result.write(_normalizeTokenValue(token, rawCharacter));
      }
      rawIndex++;
    }

    return result.toString();
  }

  static String _normalizeTokenValue(MaskToken token, String character) {
    final normalized = token.normalize(character);
    if (normalized.length != 1) {
      throw StateError(
        'MaskToken.normalize must return exactly one UTF-16 code unit.',
      );
    }
    return normalized;
  }

  static List<_CompiledMaskPart> _compilePattern(
    String pattern,
    Map<String, MaskToken> tokens,
    String escapeCharacter,
  ) {
    final parts = <_CompiledMaskPart>[];

    for (var i = 0; i < pattern.length; i++) {
      final character = pattern[i];
      if (character == escapeCharacter) {
        if (i + 1 < pattern.length) {
          parts.add(_CompiledMaskPart.literal(pattern[++i]));
        } else {
          parts.add(_CompiledMaskPart.literal(character));
        }
        continue;
      }

      final token = tokens[character];
      parts.add(
        token == null
            ? _CompiledMaskPart.literal(character)
            : _CompiledMaskPart.token(character, token),
      );
    }

    var hasTokenAfter = false;
    for (var i = parts.length - 1; i >= 0; i--) {
      final part = parts[i];
      parts[i] = part.copyWith(hasTokenAfter: hasTokenAfter);
      if (part.isToken) {
        hasTokenAfter = true;
      }
    }

    return List<_CompiledMaskPart>.unmodifiable(parts);
  }
}

class _CompiledMaskPart {
  const _CompiledMaskPart._({
    required this.character,
    required this.token,
    required this.hasTokenAfter,
  });

  factory _CompiledMaskPart.literal(String character) {
    return _CompiledMaskPart._(
      character: character,
      token: null,
      hasTokenAfter: false,
    );
  }

  factory _CompiledMaskPart.token(String character, MaskToken token) {
    return _CompiledMaskPart._(
      character: character,
      token: token,
      hasTokenAfter: false,
    );
  }

  final String character;
  final MaskToken? token;
  final bool hasTokenAfter;

  bool get isToken => token != null;

  _CompiledMaskPart copyWith({bool? hasTokenAfter}) {
    return _CompiledMaskPart._(
      character: character,
      token: token,
      hasTokenAfter: hasTokenAfter ?? this.hasTokenAfter,
    );
  }
}
