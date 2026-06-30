import 'dart:math';

/// Utility helpers for string masking, accent removal, parsing, and document
/// validation.
///
/// This class groups stateless helpers that are commonly needed across
/// applications. All methods are static and do not retain per-call state.
class EssentialCoreUtils {
  static const Map<String, String> _accentMap = <String, String>{
    'â': 'a',
    'Â': 'A',
    'à': 'a',
    'À': 'A',
    'á': 'a',
    'Á': 'A',
    'ã': 'a',
    'Ã': 'A',
    'ê': 'e',
    'Ê': 'E',
    'è': 'e',
    'È': 'E',
    'é': 'e',
    'É': 'E',
    'î': 'i',
    'Î': 'I',
    'ì': 'i',
    'Ì': 'I',
    'í': 'i',
    'Í': 'I',
    'õ': 'o',
    'Õ': 'O',
    'ô': 'o',
    'Ô': 'O',
    'ò': 'o',
    'Ò': 'O',
    'ó': 'o',
    'Ó': 'O',
    'ü': 'u',
    'Ü': 'U',
    'û': 'u',
    'Û': 'U',
    'ú': 'u',
    'Ú': 'U',
    'ù': 'u',
    'Ù': 'U',
    'ç': 'c',
    'Ç': 'C',
  };

  static final RegExp _accentRegex = RegExp('[${_accentMap.keys.join()}]');
  static final RegExp _emailRegex = RegExp(
      r"^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,253}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,253}[a-zA-Z0-9])?)*$");
  static final RegExp _repeatedCpfRegex = RegExp(r'^(\d)\1{10}$');
  static final RegExp _strictCnpjRegex = RegExp(
    r'^(?:[0-9A-Z]{2}\.[0-9A-Z]{3}\.[0-9A-Z]{3}/[0-9A-Z]{4}-[0-9]{2}|[0-9A-Z]{12}[0-9]{2})$',
  );
  static const String _cnpjValidChars = '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ';

  /// Generates a combined hash code for [objects].
  ///
  /// This is a small wrapper around Dart's platform-agnostic [Object.hashAll].
  /// Use it when implementing `hashCode` for classes that compare multiple
  /// fields.
  static int hashObjects(Iterable<Object?> objects) {
    return Object.hashAll(objects);
  }

  /// Generates a combined hash code for two objects.
  static int hash2(Object? a, Object? b) {
    return Object.hash(a, b);
  }

  /// Generates a combined hash code for three objects.
  static int hash3(Object? a, Object? b, Object? c) {
    return Object.hash(a, b, c);
  }

  /// Generates a combined hash code for four objects.
  static int hash4(Object? a, Object? b, Object? c, Object? d) {
    return Object.hash(a, b, c, d);
  }

  /// Returns a new map with [defaults] applied before [values].
  ///
  /// Keys present in [values] win over keys in [defaults]. Neither input map is
  /// mutated.
  static Map<K, V> mergeDefaults<K, V>(
    Map<K, V>? values,
    Map<K, V> defaults,
  ) {
    return <K, V>{
      ...defaults,
      if (values != null) ...values,
    };
  }

  /// Masks the trailing portion of [string], preserving the first
  /// [visibleCharacters] characters and filling the rest with [trail].
  ///
  /// Example:
  ///
  /// ```dart
  /// EssentialCoreUtils.hidePartsOfString('1234567890');
  /// // '12********'
  /// ```
  ///
  /// [trail] may contain more than one character. In that case, the returned
  /// string can become longer than [string].
  static String hidePartsOfString(String string,
      {int visibleCharacters = 2, String trail = '*'}) {
    if (string.length < visibleCharacters) {
      return string;
    }
    return string.substring(0, visibleCharacters) +
        (trail * (string.length - visibleCharacters));
  }

  /// Replaces common accented characters in [s] with their plain equivalents.
  ///
  /// This helper covers the accent map used by this package's legacy API.
  /// For a broader string extension, see `withoutAccents`.
  static String removerAcentos(String s) {
    return s.replaceAllMapped(
      _accentRegex,
      (match) => _accentMap[match.group(0)]!,
    );
  }

  /// Converts [value] to a string for permissive text-normalization flows.
  ///
  /// `null` and empty lists return an empty string. Other values use
  /// `toString()`.
  static String stringify(Object? value) {
    if (value == null || (value is List && value.isEmpty)) {
      return '';
    }
    return value.toString();
  }

  /// Returns a trimmed string, or `null` for `null`, empty, or literal `null`.
  static String? blankToNull(Object? value) {
    final text = value?.toString().trim();
    if (text == null || text.isEmpty || text.toLowerCase() == 'null') {
      return null;
    }
    return text;
  }

  /// Returns [value] as a non-empty trimmed string or [defaultValue].
  static String stringOrDefault(Object? value, String defaultValue) {
    return blankToNull(value) ?? defaultValue;
  }

  /// Converts an iterable [value] to a fixed `List<String>`.
  ///
  /// Unsupported values return an empty list.
  static List<String> stringList(Object? value) {
    if (value is Iterable) {
      return value.map((item) => item.toString()).toList(growable: false);
    }
    return const <String>[];
  }

  /// Converts an iterable of maps into `List<Map<String, dynamic>>`.
  ///
  /// Non-map entries are ignored. Unsupported values return an empty list.
  static List<Map<String, dynamic>> mapList(Object? value) {
    if (value is Iterable) {
      return value
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList(growable: false);
    }
    return const <Map<String, dynamic>>[];
  }

  /// Removes every non-ASCII digit from [value].
  static String onlyNumbers(String? value) {
    if (value == null || value.isEmpty) {
      return '';
    }

    final sanitized = StringBuffer();
    for (var i = 0; i < value.length; i++) {
      final codeUnit = value.codeUnitAt(i);
      if (_isAsciiDigit(codeUnit)) {
        sanitized.writeCharCode(codeUnit);
      }
    }
    return sanitized.toString();
  }

  /// Converts [value] into `int` when possible.
  ///
  /// Accepted inputs are `int` and strings accepted by [int.tryParse].
  /// Unsupported values return `null`.
  static int? toNullableInt(dynamic value) {
    if (value == null) {
      return null;
    }
    if (value is int) {
      return value;
    }
    if (value is String) {
      return int.tryParse(value);
    }
    return null;
  }

  /// Converts [value] into `double` when possible.
  ///
  /// Accepted inputs include `num` and strings accepted by [double.tryParse].
  /// Commas in strings are treated as decimal separators.
  static double? toNullableDouble(dynamic value) {
    if (value == null) {
      return null;
    }
    if (value is double) {
      return value;
    }
    if (value is int) {
      return value.toDouble();
    }
    if (value is num) {
      return value.toDouble();
    }
    if (value is String) {
      return double.tryParse(value.replaceAll(',', '.'));
    }
    return double.tryParse(value.toString());
  }

  /// Returns [value] when it is a `String`.
  ///
  /// Other values return `null`; no implicit `toString()` conversion is
  /// performed.
  static String? toNullableString(dynamic value) {
    if (value == null) {
      return null;
    }
    if (value is String) {
      return value;
    }
    return null;
  }

  /// Reads a nullable boolean value from [map] using [key].
  ///
  /// When [key] is absent or its value is `null`, returns `null`. When present,
  /// only the string `true`, ignoring case, maps to `true`; any other present
  /// value maps to `false`.
  static bool? toNullableBool(Map<String, dynamic> map, String key) {
    if (map.containsKey(key) && map[key] != null) {
      return map[key].toString().toLowerCase() == 'true';
    }
    return null;
  }

  /// Converts [value] into a nullable boolean using common text forms.
  ///
  /// Accepted true values are `true`, `t`, `1`, `sim`, `s`, `yes`, and `y`.
  /// Accepted false values are `false`, `f`, `0`, `nao`, `não`, `n`, and `no`.
  /// Unknown values return `null`.
  static bool? parseBoolLoose(Object? value) {
    if (value == null) {
      return null;
    }
    if (value is bool) {
      return value;
    }

    final text = value.toString().trim().toLowerCase();
    if (text.isEmpty) {
      return null;
    }

    const trueValues = <String>{'true', 't', '1', 'sim', 's', 'yes', 'y'};
    const falseValues = <String>{
      'false',
      'f',
      '0',
      'nao',
      'não',
      'n',
      'no',
    };

    if (trueValues.contains(text)) {
      return true;
    }
    if (falseValues.contains(text)) {
      return false;
    }
    return null;
  }

  /// Converts [value] into a boolean.
  ///
  /// In non-strict mode, every string except `0`, `false`, and the empty string
  /// maps to `true`. In strict mode, only `1` and `true` map to `true`.
  static bool toBoolean(Object? value, {bool strict = false}) {
    final text = value?.toString() ?? '';
    if (strict) {
      return text == '1' || text == 'true';
    }
    return text != '0' && text != 'false' && text.isNotEmpty;
  }

  /// Converts [value] into `DateTime` when possible.
  ///
  /// [DateTime] values are returned unchanged. Strings are parsed with
  /// [DateTime.tryParse].
  static DateTime? toNullableDateTime(dynamic value) {
    if (value == null) {
      return null;
    }
    if (value is DateTime) {
      return value;
    }
    if (value is String) {
      return DateTime.tryParse(value);
    }
    return DateTime.tryParse(value.toString());
  }

  /// Trims [chars] from both sides of [text].
  ///
  /// When [chars] is omitted, standard Dart whitespace trimming is used.
  static String trimChars(String text, [String? chars]) {
    if (chars == null || chars.isEmpty) {
      return text.trim();
    }
    return text.replaceAll(
        RegExp('^${_oneOf(chars)}+|${_oneOf(chars)}+\$'), '');
  }

  /// Trims [chars] from the left side of [text].
  static String ltrimChars(String text, [String? chars]) {
    if (chars == null || chars.isEmpty) {
      return text.trimLeft();
    }
    return text.replaceAll(RegExp('^${_oneOf(chars)}+'), '');
  }

  /// Trims [chars] from the right side of [text].
  static String rtrimChars(String text, [String? chars]) {
    if (chars == null || chars.isEmpty) {
      return text.trimRight();
    }
    return text.replaceAll(RegExp('${_oneOf(chars)}+\$'), '');
  }

  /// Keeps only characters included in [allowedChars].
  static String whitelistChars(String text, String allowedChars) {
    if (allowedChars.isEmpty) {
      return '';
    }
    return text.replaceAll(RegExp('[^${_charClass(allowedChars)}]+'), '');
  }

  /// Removes characters included in [blockedChars].
  static String blacklistChars(String text, String blockedChars) {
    if (blockedChars.isEmpty) {
      return text;
    }
    return text.replaceAll(RegExp('[${_charClass(blockedChars)}]+'), '');
  }

  /// Removes ASCII control characters.
  ///
  /// Set [keepNewLines] to preserve `\n` and `\r`.
  static String stripLow(String text, {bool keepNewLines = false}) {
    final pattern = keepNewLines
        ? RegExp(r'[\x00-\x09\x0B\x0C\x0E-\x1F\x7F]')
        : RegExp(r'[\x00-\x1F\x7F]');
    return text.replaceAll(pattern, '');
  }

  /// Escapes the five most common HTML-sensitive characters.
  ///
  /// This does not parse HTML; it simply replaces `&`, `"`, `'`, `<`, and `>`.
  static String escapeHtml(String text) {
    return text
        .replaceAll('&', '&amp;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&#x27;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;');
  }

  /// Removes characters outside ISO-8859-1's single-byte range.
  static String removeNonIso88591Characters(String text) {
    return text.replaceAll(RegExp(r'[^\x00-\xFF]'), '');
  }

  /// Canonicalizes common e-mail address forms.
  ///
  /// Invalid e-mails return an empty string. Domains are always lowercased.
  /// When [lowercase] is `true`, the local part is lowercased too. Gmail and
  /// Googlemail addresses are normalized to `gmail.com`, remove dots from the
  /// local part, and strip `+tag` suffixes.
  static String normalizeEmail(String email, {bool lowercase = true}) {
    if (!emailIsValid(email)) {
      return '';
    }

    final at = email.lastIndexOf('@');
    var local = email.substring(0, at);
    var domain = email.substring(at + 1).toLowerCase();

    if (lowercase) {
      local = local.toLowerCase();
    }

    if (domain == 'gmail.com' || domain == 'googlemail.com') {
      local = local.toLowerCase().replaceAll('.', '').split('+').first;
      domain = 'gmail.com';
    }

    return '$local@$domain';
  }

  /// Whether [cpf] belongs to a blocked repeated-digit sequence.
  ///
  /// This returns `true` for values such as `00000000000` and
  /// `11111111111`, which can otherwise satisfy the CPF check-digit algorithm
  /// mathematically while still being invalid real-world identifiers.
  static bool blacklistedCPF(String cpf) {
    return _repeatedCpfRegex.hasMatch(cpf);
  }

  /// Removes every non-digit character from [cpf].
  ///
  /// This is useful before storing or comparing CPF values. `null` returns an
  /// empty string.
  ///
  /// ```dart
  /// EssentialCoreUtils.sanitizarCpf('529.982.247-25'); // '52998224725'
  /// ```
  static String sanitizarCpf(String? cpf) {
    return onlyNumbers(cpf);
  }

  /// Applies the canonical CPF mask `000.000.000-00`.
  ///
  /// Non-digit characters are ignored before formatting. When the sanitized
  /// value does not contain exactly 11 digits, the sanitized value is returned
  /// unchanged.
  static String formatarCpf(String? cpf) {
    final sanitized = sanitizarCpf(cpf);
    if (sanitized.length != 11) {
      return sanitized;
    }

    return '${sanitized.substring(0, 3)}.'
        '${sanitized.substring(3, 6)}.'
        '${sanitized.substring(6, 9)}-'
        '${sanitized.substring(9)}';
  }

  /// Masks a CPF for public display in the federal transparency style.
  ///
  /// The returned value preserves only the middle six digits and hides the
  /// first three digits and the two check digits:
  ///
  /// ```dart
  /// EssentialCoreUtils.mascararCpfGovernoFederal('123.456.789-10');
  /// // '***.456.789-**'
  /// ```
  ///
  /// This is the conservative pattern commonly used for public transparency
  /// pages because CPF identifies a natural person. When [cpf] does not contain
  /// exactly 11 digits, the sanitized value is returned unchanged.
  static String mascararCpfGovernoFederal(
    String? cpf, {
    String ocultador = '*',
  }) {
    final sanitized = sanitizarCpf(cpf);
    if (sanitized.length != 11) {
      return sanitized;
    }

    final mask = _maskSymbol(ocultador);
    final hiddenBlock = mask * 3;
    final hiddenDigits = mask * 2;

    return '$hiddenBlock.'
        '${sanitized.substring(3, 6)}.'
        '${sanitized.substring(6, 9)}-'
        '$hiddenDigits';
  }

  /// Generates a mathematically valid CPF.
  ///
  /// By default the returned value is unformatted. Set [formatado] to `true` to
  /// receive the canonical mask `000.000.000-00`. [random] can be supplied by
  /// tests or callers that need deterministic generation.
  static String gerarCpf({bool formatado = false, Random? random}) {
    final rand = random ?? Random();
    late String cpf;

    do {
      final digits = List<int>.generate(9, (_) => rand.nextInt(10));
      digits.add(gerarDigitoVerificador(digits));
      digits.add(gerarDigitoVerificador(digits));
      cpf = digits.join();
    } while (blacklistedCPF(cpf));

    return formatado ? formatarCpf(cpf) : cpf;
  }

  /// Validates a CPF number.
  ///
  /// Non-digit characters are ignored, so formatted and raw values are both
  /// accepted:
  ///
  /// ```dart
  /// EssentialCoreUtils.validarCPF('529.982.247-25'); // true
  /// ```
  ///
  /// Repeated-digit sequences are rejected before check-digit comparison.
  static bool validarCPF(String? cpf) {
    if (cpf == null || cpf.trim().isEmpty) {
      return false;
    }

    final sanitizedValue = sanitizarCpf(cpf);
    if (sanitizedValue.length != 11) {
      return false;
    }

    final sanitizedCpf = sanitizedValue
        .split('')
        .map((String digit) => int.parse(digit))
        .toList();

    if (blacklistedCPF(sanitizedCpf.join())) {
      return false;
    }

    return sanitizedCpf[9] ==
            gerarDigitoVerificador(sanitizedCpf.getRange(0, 9).toList()) &&
        sanitizedCpf[10] ==
            gerarDigitoVerificador(sanitizedCpf.getRange(0, 10).toList());
  }

  /// Calculates the CPF verification digit for [digits].
  ///
  /// [digits] should contain the first 9 CPF digits when calculating the first
  /// verifier, or the first 10 digits when calculating the second verifier.
  static int gerarDigitoVerificador(List<int> digits) {
    var baseNumber = 0;
    for (var i = 0; i < digits.length; i++) {
      baseNumber += digits[i] * ((digits.length + 1) - i);
    }
    final verificationDigit = baseNumber * 10 % 11;
    return verificationDigit >= 10 ? 0 : verificationDigit;
  }

  /// Basic e-mail format validation.
  ///
  /// This method performs syntactic validation only. It does not check DNS,
  /// mailbox existence, or deliverability.
  static bool emailIsValid(String email) {
    return _emailRegex.hasMatch(email);
  }

  /// Removes mask characters and normalizes a CNPJ to uppercase ASCII.
  ///
  /// The returned value keeps only `0..9` and `A..Z`. Lowercase ASCII letters
  /// are converted to uppercase and any other character is ignored.
  ///
  /// ```dart
  /// EssentialCoreUtils.sanitizarCnpj('12.abc.345/01de-35');
  /// // '12ABC34501DE35'
  /// ```
  static String sanitizarCnpj(String? cnpj) {
    if (cnpj == null || cnpj.isEmpty) {
      return '';
    }

    final sanitized = StringBuffer();
    for (var i = 0; i < cnpj.length; i++) {
      var codeUnit = cnpj.codeUnitAt(i);
      if (_isAsciiLowercaseLetter(codeUnit)) {
        codeUnit -= 32;
      }
      if (_isAsciiDigit(codeUnit) || _isAsciiUppercaseLetter(codeUnit)) {
        sanitized.writeCharCode(codeUnit);
      }
    }
    return sanitized.toString();
  }

  /// Applies the canonical CNPJ mask `XX.XXX.XXX/XXXX-YY`.
  ///
  /// The first twelve positions may be digits or uppercase ASCII letters and
  /// the last two positions are check digits. When the sanitized value does not
  /// contain exactly 14 characters, the sanitized value is returned unchanged.
  static String formatarCnpj(String? cnpj) {
    final sanitized = sanitizarCnpj(cnpj);
    if (sanitized.length != 14 || !_hasValidCnpjShape(sanitized)) {
      return sanitized;
    }

    return '${sanitized.substring(0, 2)}.'
        '${sanitized.substring(2, 5)}.'
        '${sanitized.substring(5, 8)}/'
        '${sanitized.substring(8, 12)}-'
        '${sanitized.substring(12)}';
  }

  /// Formats a CNPJ for public display in the federal transparency style.
  ///
  /// CNPJ generally identifies a legal entity, so this helper intentionally
  /// does not hide digits; it only sanitizes and applies the canonical mask.
  ///
  /// ```dart
  /// EssentialCoreUtils.mascararCnpjGovernoFederal('12345678000199');
  /// // '12.345.678/0001-99'
  /// ```
  ///
  /// MEI/EI cases can require additional LGPD review when the surrounding data
  /// exposes the natural person, but that cannot be inferred safely from the
  /// CNPJ number alone.
  static String mascararCnpjGovernoFederal(String? cnpj) {
    return formatarCnpj(cnpj);
  }

  /// Masks either a CPF or a CNPJ for federal-style public display.
  ///
  /// CPF values are returned as `***.456.789-**`. CNPJ values are returned open
  /// and formatted as `12.345.678/0001-99`. Inputs that are neither CPF nor CNPJ
  /// are returned after CNPJ sanitization, preserving alphanumeric document
  /// characters when present.
  static String mascararDocumentoGovernoFederal(
    String? documento, {
    String ocultadorCpf = '*',
  }) {
    final cpf = sanitizarCpf(documento);
    if (cpf.length == 11) {
      return mascararCpfGovernoFederal(cpf, ocultador: ocultadorCpf);
    }

    final cnpj = sanitizarCnpj(documento);
    if (cnpj.length == 14) {
      return mascararCnpjGovernoFederal(cnpj);
    }

    return cnpj;
  }

  /// Generates a mathematically valid CNPJ.
  ///
  /// When [alfanumerico] is `true`, the first twelve positions may contain
  /// digits or uppercase ASCII letters according to Receita Federal's
  /// alphanumeric CNPJ rules. When `false`, the generated CNPJ is numeric.
  ///
  /// By default the returned value is unformatted. Set [formatado] to `true` to
  /// receive the canonical mask `XX.XXX.XXX/XXXX-YY`. [random] can be supplied
  /// by tests or callers that need deterministic generation.
  static String gerarCnpj({
    bool formatado = false,
    bool alfanumerico = true,
    Random? random,
  }) {
    final rand = random ?? Random();
    final codeUnits = List<int>.filled(14, 0);

    do {
      for (var i = 0; i < 12; i++) {
        final char = alfanumerico
            ? _cnpjValidChars[rand.nextInt(_cnpjValidChars.length)]
            : rand.nextInt(10).toString();
        codeUnits[i] = char.codeUnitAt(0);
      }
    } while (!alfanumerico && _hasRepeatedCodeUnits(codeUnits, 12));

    codeUnits[12] = _calculateCnpjDigit(codeUnits, 12) + 48;
    codeUnits[13] = _calculateCnpjDigit(codeUnits, 13) + 48;

    final cnpj = String.fromCharCodes(codeUnits);
    return formatado ? formatarCnpj(cnpj) : cnpj;
  }

  /// Validates a legacy numeric or alphanumeric CNPJ number.
  ///
  /// Uses Receita Federal's modulo 11 algorithm. The first 12 positions accept
  /// `[0-9A-Z]`, each character is converted with ASCII - 48, and the last two
  /// positions must be numeric check digits.
  ///
  /// In permissive mode, mask characters (`.`, `/`, `-`) and ASCII whitespace
  /// are ignored, and lowercase letters are normalized to uppercase.
  ///
  /// When [strict] is `true`, accepts only the canonical mask
  /// `XX.XXX.XXX/XXXX-YY` or 14 clean uppercase characters.
  ///
  /// Example:
  ///
  /// ```dart
  /// EssentialCoreUtils.validarCnpj('54.550.752/0001-55'); // true
  /// EssentialCoreUtils.validarCnpj('12ABC34501DE35');     // true
  /// ```
  static bool validarCnpj(String? cnpj, {bool strict = false}) {
    if (cnpj == null || cnpj.length > 64) {
      return false;
    }

    if (strict && !_strictCnpjRegex.hasMatch(cnpj)) {
      return false;
    }

    final codeUnits = List<int>.filled(14, 0);
    var length = 0;
    var firstCodeUnit = 0;
    var repeatedNumeric = false;

    for (var i = 0; i < cnpj.length; i++) {
      var codeUnit = cnpj.codeUnitAt(i);

      if (_isCnpjMaskOrWhitespace(codeUnit)) {
        continue;
      }

      if (_isAsciiLowercaseLetter(codeUnit)) {
        codeUnit -= 32;
      }

      if (length == 14) {
        return false;
      }

      if (length < 12) {
        if (!_isAsciiDigit(codeUnit) && !_isAsciiUppercaseLetter(codeUnit)) {
          return false;
        }
      } else if (!_isAsciiDigit(codeUnit)) {
        return false;
      }

      if (length == 0) {
        firstCodeUnit = codeUnit;
        repeatedNumeric = _isAsciiDigit(codeUnit);
      } else if (codeUnit != firstCodeUnit) {
        repeatedNumeric = false;
      }

      codeUnits[length++] = codeUnit;
    }

    if (length != 14 || repeatedNumeric) {
      return false;
    }

    final firstDigit = _calculateCnpjDigit(codeUnits, 12);
    if (codeUnits[12] - 48 != firstDigit) {
      return false;
    }

    final secondDigit = _calculateCnpjDigit(codeUnits, 13);
    return codeUnits[13] - 48 == secondDigit;
  }

  static bool _isCnpjMaskOrWhitespace(int codeUnit) {
    return codeUnit == 46 ||
        codeUnit == 47 ||
        codeUnit == 45 ||
        codeUnit == 32 ||
        codeUnit == 9 ||
        codeUnit == 10 ||
        codeUnit == 11 ||
        codeUnit == 12 ||
        codeUnit == 13;
  }

  static bool _isAsciiDigit(int codeUnit) {
    return codeUnit >= 48 && codeUnit <= 57;
  }

  static bool _isAsciiLowercaseLetter(int codeUnit) {
    return codeUnit >= 97 && codeUnit <= 122;
  }

  static bool _isAsciiUppercaseLetter(int codeUnit) {
    return codeUnit >= 65 && codeUnit <= 90;
  }

  static bool _hasRepeatedCodeUnits(List<int> codeUnits, int length) {
    final firstCodeUnit = codeUnits[0];
    for (var i = 1; i < length; i++) {
      if (codeUnits[i] != firstCodeUnit) {
        return false;
      }
    }
    return true;
  }

  static bool _hasValidCnpjShape(String cnpj) {
    for (var i = 0; i < cnpj.length; i++) {
      final codeUnit = cnpj.codeUnitAt(i);
      if (i < 12) {
        if (!_isAsciiDigit(codeUnit) && !_isAsciiUppercaseLetter(codeUnit)) {
          return false;
        }
      } else if (!_isAsciiDigit(codeUnit)) {
        return false;
      }
    }
    return true;
  }

  static String _maskSymbol(String value) {
    return value.isEmpty ? '*' : value[0];
  }

  static String _oneOf(String chars) {
    return '[${_charClass(chars)}]';
  }

  static String _charClass(String chars) {
    final buffer = StringBuffer();
    for (var i = 0; i < chars.length; i++) {
      buffer.write(RegExp.escape(chars[i]));
    }
    return buffer.toString();
  }

  static int _calculateCnpjDigit(List<int> codeUnits, int length) {
    var sum = 0;
    var weight = 2;

    for (var i = length - 1; i >= 0; i--) {
      sum += (codeUnits[i] - 48) * weight;
      weight = weight == 9 ? 2 : weight + 1;
    }

    final mod = sum % 11;
    return mod < 2 ? 0 : 11 - mod;
  }

  /// Truncates [text] to [maxLength], appending [omission] when necessary.
  ///
  /// If [omission] is longer than or equal to [maxLength], the omission itself
  /// is truncated. When [maxLength] is zero or negative, an empty string is
  /// returned.
  static String truncate(String text, int maxLength, [String omission = '']) {
    if (maxLength <= 0) {
      return '';
    }
    if (text.length <= maxLength) {
      return text;
    }
    if (omission.length >= maxLength) {
      return omission.substring(0, maxLength);
    }
    return text.substring(0, maxLength - omission.length) + omission;
  }
}
