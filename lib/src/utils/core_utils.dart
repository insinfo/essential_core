/// Generic parsing, validation, and formatting helpers shared across apps.
class CoreUtils {
  /// Converts [value] into `int` when possible.
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
  static bool blacklistedCPF(String cpf) {
    return cpf == '11111111111' ||
        cpf == '22222222222' ||
        cpf == '33333333333' ||
        cpf == '44444444444' ||
        cpf == '55555555555' ||
        cpf == '66666666666' ||
        cpf == '77777777777' ||
        cpf == '88888888888' ||
        cpf == '99999999999';
  }

  /// Validates a CPF number.
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
  static int gerarDigitoVerificador(List<int> digits) {
    var baseNumber = 0;
    for (var i = 0; i < digits.length; i++) {
      baseNumber += digits[i] * ((digits.length + 1) - i);
    }
    final verificationDigit = baseNumber * 10 % 11;
    return verificationDigit >= 10 ? 0 : verificationDigit;
  }

  /// Basic e-mail format validation.
  static bool emailIsValid(String email) {
    return RegExp(
            r"^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,253}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,253}[a-zA-Z0-9])?)*$")
        .hasMatch(email);
  }

  /// Validates a CNPJ number.
  static bool validarCnpj(String? cnpj) {
    if (cnpj == null) {
      return false;
    }

    final numbers = cnpj.replaceAll(RegExp(r'[^0-9]'), '');
    if (numbers.length != 14) {
      return false;
    }
    if (RegExp(r'^(\d)\1*$').hasMatch(numbers)) {
      return false;
    }

    final digits = numbers.split('').map((String d) => int.parse(d)).toList();

    var calcDv1 = 0;
    var j = 0;
    for (final i in Iterable<int>.generate(12, (i) => i < 4 ? 5 - i : 13 - i)) {
      calcDv1 += digits[j++] * i;
    }
    calcDv1 %= 11;
    final dv1 = calcDv1 < 2 ? 0 : 11 - calcDv1;
    if (digits[12] != dv1) {
      return false;
    }

    var calcDv2 = 0;
    j = 0;
    for (final i in Iterable<int>.generate(13, (i) => i < 5 ? 6 - i : 14 - i)) {
      calcDv2 += digits[j++] * i;
    }
    calcDv2 %= 11;
    final dv2 = calcDv2 < 2 ? 0 : 11 - calcDv2;
    if (digits[13] != dv2) {
      return false;
    }

    return true;
  }

  /// Truncates [text] to [maxLength], appending [omission] when necessary.
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
