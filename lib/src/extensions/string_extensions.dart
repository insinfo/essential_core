/// String formatting and comparison helpers used across the package.
///
/// These helpers are intentionally lightweight and framework-agnostic. They
/// cover common UI and query use cases such as display capitalization,
/// accent-insensitive matching, and Portuguese title case conversion.
extension StringExtensions on String {
  /// Returns this string with the first character uppercased and the
  /// remaining characters lowercased.
  String toCapitalized() =>
      length > 0 ? '${this[0].toUpperCase()}${substring(1).toLowerCase()}' : '';

  /// Normalizes repeated spaces and capitalizes each word in this string.
  ///
  /// This is a simple language-neutral title case. For Portuguese text where
  /// connectors such as `de` and `do` should remain lowercase, prefer
  /// [toPortugueseTitleCase].
  String toTitleCase() => length > 0
      ? replaceAll(RegExp(' +'), ' ')
          .split(' ')
          .map((str) => str.toCapitalized())
          .join(' ')
      : '';

  /// Converts this string to title case using Portuguese connector and acronym
  /// rules.
  ///
  /// [lowercaseWords] adds custom words that should remain lowercase when they
  /// are not the first word. [acronyms] adds or overrides case-insensitive
  /// fixed spellings.
  ///
  /// Example:
  ///
  /// ```dart
  /// 'PARCELAMENTO DE IPTU'.toPortugueseTitleCase();
  /// // 'Parcelamento de IPTU'
  ///
  /// 'relatório conforme norma abc'.toPortugueseTitleCase(
  ///   lowercaseWords: ['conforme'],
  ///   acronyms: {'abc': 'ABC'},
  /// );
  /// // 'Relatório conforme Norma ABC'
  /// ```
  String toPortugueseTitleCase({
    Iterable<String> lowercaseWords = const <String>[],
    Map<String, String> acronyms = const <String, String>{},
  }) =>
      PtTitleCase.convert(
        this,
        lowercaseWords: lowercaseWords,
        acronyms: acronyms,
      );

  /// Returns whether this string contains [secondString] ignoring case.
  bool containsIgnoreCase(String secondString) =>
      toLowerCase().contains(secondString.toLowerCase());

  /// Returns whether this string contains [secondString] ignoring accents and
  /// case.
  bool containsIgnoreAccents(String secondString) => withoutAccents
      .toLowerCase()
      .contains(secondString.withoutAccents.toLowerCase());

  /// Compares [a] and [b] ignoring case, treating two `null` values as equal.
  ///
  /// The extension receiver is not used and is kept for backward
  /// compatibility with the existing API.
  bool equalsIgnoreCase(String? a, String? b) =>
      (a == null && b == null) ||
      (a != null && b != null && a.toLowerCase() == b.toLowerCase());
}

/// Accent-insensitive normalization helpers for [String].
extension DiacriticsAwareString on String {
  static const diacritics =
      'ÀÁÂÃÄÅàáâãäåÒÓÔÕÕÖØòóôõöøÈÉÊËĚèéêëěðČÇçčÐĎďÌÍÎÏìíîïĽľÙÚÛÜŮùúûüůŇÑñňŘřŠšŤťŸÝÿýŽž';
  static const nonDiacritics =
      'AAAAAAaaaaaaOOOOOOOooooooEEEEEeeeeeeCCccDDdIIIIiiiiLlUUUUUuuuuuNNnnRrSsTtYYyyZz';

  /// Returns this string with known diacritic characters replaced by their
  /// non-accented equivalents.
  ///
  /// Example:
  ///
  /// ```dart
  /// 'Informação Útil'.withoutAccents; // 'Informacao Util'
  /// ```
  String get withoutAccents => splitMapJoin('',
      onNonMatch: (char) => char.isNotEmpty && diacritics.contains(char)
          ? nonDiacritics[diacritics.indexOf(char)]
          : char);
}

/// Portuguese-aware title case converter.
///
/// The converter normalizes whitespace, lowercases connector words in the
/// middle of a title, preserves known acronyms, and handles common separators
/// such as hyphen, slash, parentheses, and apostrophes.
///
/// Prefer the extension [StringExtensions.toPortugueseTitleCase] for fluent
/// use on strings, or call [convert] directly when a static helper is clearer.
class PtTitleCase {
  static const Set<String> _lowercaseMiddleWords = <String>{
    'a',
    'o',
    'as',
    'os',
    'um',
    'uma',
    'uns',
    'umas',
    'de',
    'do',
    'da',
    'dos',
    'das',
    'd',
    'e',
    'em',
    'como',
    'no',
    'na',
    'nos',
    'nas',
    'num',
    'numa',
    'nuns',
    'numas',
    'por',
    'para',
    'com',
    'sem',
    'sob',
    'sobre',
    'entre',
    'ate',
    'até',
    'apos',
    'após',
    'ante',
    'contra',
    'desde',
    'durante',
    'mediante',
    'perante',
    'pela',
    'pelas',
    'pelo',
    'pelos',
    'ao',
    'aos',
    'à',
    'às',
  };

  static const Map<String, String> _acronyms = <String, String>{
    'iptu': 'IPTU',
    'iss': 'ISS',
    'cpf': 'CPF',
    'cnpj': 'CNPJ',
    'rg': 'RG',
    'ti': 'TI',
    'sali': 'SALI',
    'semob': 'SEMOB',
    'vi': 'VI',
    'pcpt': 'PCPT',
    'ptc': 'PTC',
    'plc': 'PLC',
    'ptda': 'PTDA',
    'pspua': 'PSPUA',
    'itbi': 'ITBI',
    'erb': 'ERB',
    'pgm': 'PGM',
    'lc': 'LC',
    'ppp': 'PPP',
    'pje': 'PJe',
    'eproc': 'eProc',
    'sei': 'SEI',
    'gov.br': 'gov.br',
    'b.o.f': 'B.O.F',
    'cmro': 'CMRO',
    'pj': 'PJ',
    'pf': 'PF',
    'tce': 'TCE',
    'rj': 'RJ',
    'tac': 'TAC',
    'simei': 'SIMEI',
  };

  static final RegExp _spacesRegex = RegExp(r'\s+');
  static final RegExp _letterOrDigitRegex =
      RegExp(r'[\p{L}\p{N}]', unicode: true);

  /// Converts [input] to title case for Portuguese text.
  ///
  /// [lowercaseWords] adds connector words that should remain lowercase when
  /// they are not the first word. [acronyms] adds or overrides fixed spellings,
  /// using case-insensitive keys and preserving each mapped value as provided.
  ///
  /// The built-in acronym list covers common Brazilian public-sector and
  /// municipal terms such as `CPF`, `CNPJ`, `IPTU`, `ITBI`, `SEI`, `PJe`, and
  /// `eProc`.
  ///
  /// Example:
  ///
  /// ```dart
  /// PtTitleCase.convert("SANTA BÁRBARA D'OESTE");
  /// // "Santa Bárbara D'Oeste"
  /// ```
  static String convert(
    String input, {
    Iterable<String> lowercaseWords = const <String>[],
    Map<String, String> acronyms = const <String, String>{},
  }) {
    final text = input.trim().replaceAll(_spacesRegex, ' ');
    if (text.isEmpty) {
      return text;
    }

    final options = _PtTitleCaseOptions(
      lowercaseWords: lowercaseWords,
      acronyms: acronyms,
    );
    final tokens = text.split(' ');
    return [
      for (var i = 0; i < tokens.length; i++)
        _formatToken(tokens[i], isFirst: i == 0, options: options),
    ].join(' ');
  }

  static String _formatToken(
    String token, {
    required bool isFirst,
    required _PtTitleCaseOptions options,
  }) {
    if (token.isEmpty) {
      return token;
    }

    final firstCoreIndex = _firstLetterOrDigitIndex(token);
    if (firstCoreIndex == -1) {
      return token;
    }

    final lastCoreIndex = _lastLetterOrDigitIndex(token);
    final prefix = token.substring(0, firstCoreIndex);
    final core = token.substring(firstCoreIndex, lastCoreIndex + 1);
    final suffix = token.substring(lastCoreIndex + 1);
    final lower = core.toLowerCase();

    final acronym = options.acronyms[lower];
    if (acronym != null) {
      return '$prefix$acronym$suffix';
    }

    if (!isFirst && options.lowercaseWords.contains(lower)) {
      return '$prefix$lower$suffix';
    }

    final formatted = _formatDelimitedCore(core, options);

    return '$prefix$formatted$suffix';
  }

  static String _formatDelimitedCore(
    String core,
    _PtTitleCaseOptions options,
  ) {
    final buffer = StringBuffer();
    final segment = StringBuffer();
    var isFirstSegment = true;

    for (var i = 0; i < core.length; i++) {
      final char = core[i];
      if (char == '-' || char == '/') {
        buffer.write(
          _formatCorePart(
            segment.toString(),
            isFirst: isFirstSegment,
            options: options,
          ),
        );
        segment.clear();
        buffer.write(char);
        isFirstSegment = char == '-' ? false : true;
      } else {
        segment.write(char);
      }
    }

    buffer.write(
      _formatCorePart(
        segment.toString(),
        isFirst: isFirstSegment,
        options: options,
      ),
    );
    return buffer.toString();
  }

  static String _formatCorePart(
    String part, {
    required bool isFirst,
    required _PtTitleCaseOptions options,
  }) {
    if (part.isEmpty) {
      return part;
    }

    final lower = part.toLowerCase();
    final acronym = options.acronyms[lower];
    if (acronym != null) {
      return acronym;
    }

    final acronymPrefix = _formatAcronymPrefix(lower, options.acronyms);
    if (acronymPrefix != null) {
      return acronymPrefix;
    }

    if (!isFirst && options.lowercaseWords.contains(lower)) {
      return lower;
    }

    return _capitalize(lower);
  }

  static String? _formatAcronymPrefix(
    String lower,
    Map<String, String> acronyms,
  ) {
    for (final entry in acronyms.entries) {
      final key = entry.key;
      if (lower.length <= key.length || !lower.startsWith(key)) {
        continue;
      }

      final next = lower[key.length];
      if (!_letterOrDigitRegex.hasMatch(next)) {
        return '${entry.value}${lower.substring(key.length)}';
      }
    }

    return null;
  }

  static String _capitalize(String word) {
    if (!word.contains("'") && !word.contains('’')) {
      return _capitalizeSimple(word);
    }

    final buffer = StringBuffer();
    final segment = StringBuffer();

    for (var i = 0; i < word.length; i++) {
      final char = word[i];
      if (char == "'" || char == '’') {
        buffer.write(_capitalizeSimple(segment.toString()));
        segment.clear();
        buffer.write(char);
      } else {
        segment.write(char);
      }
    }

    buffer.write(_capitalizeSimple(segment.toString()));
    return buffer.toString();
  }

  static String _capitalizeSimple(String word) {
    if (word.isEmpty) {
      return word;
    }

    return word[0].toUpperCase() + word.substring(1);
  }

  static int _firstLetterOrDigitIndex(String value) {
    for (var i = 0; i < value.length; i++) {
      if (_letterOrDigitRegex.hasMatch(value[i])) {
        return i;
      }
    }
    return -1;
  }

  static int _lastLetterOrDigitIndex(String value) {
    for (var i = value.length - 1; i >= 0; i--) {
      if (_letterOrDigitRegex.hasMatch(value[i])) {
        return i;
      }
    }
    return -1;
  }
}

class _PtTitleCaseOptions {
  _PtTitleCaseOptions({
    required Iterable<String> lowercaseWords,
    required Map<String, String> acronyms,
  })  : lowercaseWords = _mergedLowercaseWords(lowercaseWords),
        acronyms = _mergedAcronyms(acronyms);

  final Set<String> lowercaseWords;
  final Map<String, String> acronyms;

  static Set<String> _mergedLowercaseWords(Iterable<String> customWords) {
    if (customWords.isEmpty) {
      return PtTitleCase._lowercaseMiddleWords;
    }

    return <String>{
      ...PtTitleCase._lowercaseMiddleWords,
      for (final word in customWords)
        if (word.trim().isNotEmpty) word.trim().toLowerCase(),
    };
  }

  static Map<String, String> _mergedAcronyms(
      Map<String, String> customAcronyms) {
    if (customAcronyms.isEmpty) {
      return PtTitleCase._acronyms;
    }

    return <String, String>{
      ...PtTitleCase._acronyms,
      for (final entry in customAcronyms.entries)
        if (entry.key.trim().isNotEmpty)
          entry.key.trim().toLowerCase(): entry.value,
    };
  }
}
