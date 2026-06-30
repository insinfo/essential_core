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

  /// Whether [cpf] belongs to a blocked repeated-digit sequence.
  ///
  /// This returns `true` for values such as `00000000000` and
  /// `11111111111`, which can otherwise satisfy the CPF check-digit algorithm
  /// mathematically while still being invalid real-world identifiers.
  static bool blacklistedCPF(String cpf) {
    return _repeatedCpfRegex.hasMatch(cpf);
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

    final sanitizedValue = cpf.replaceAll(RegExp(r'[^0-9]'), '');
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
