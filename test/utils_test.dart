import 'dart:math';

import 'package:essential_core/essential_core.dart';
import 'package:test/test.dart';

String _cnpjWithDigits(String root) {
  final firstDigit = _cnpjDigit(root);
  final secondDigit = _cnpjDigit('$root$firstDigit');
  return '$root$firstDigit$secondDigit';
}

int _cnpjDigit(String value) {
  var sum = 0;
  var weight = 2;

  for (var i = value.length - 1; i >= 0; i--) {
    sum += (value.codeUnitAt(i) - 48) * weight;
    weight = weight == 9 ? 2 : weight + 1;
  }

  final mod = sum % 11;
  return mod < 2 ? 0 : 11 - mod;
}

void main() {
  group('EssentialCoreUtils', () {
    test('parses nullable scalar values', () {
      final now = DateTime.utc(2024, 1, 2, 3, 4, 5);

      expect(EssentialCoreUtils.toNullableInt(7), 7);
      expect(EssentialCoreUtils.toNullableInt('12'), 12);
      expect(EssentialCoreUtils.toNullableInt('abc'), isNull);
      expect(EssentialCoreUtils.toNullableDouble('10,5'), 10.5);
      expect(EssentialCoreUtils.toNullableDouble(10), 10.0);
      expect(EssentialCoreUtils.toNullableString(1), isNull);
      expect(EssentialCoreUtils.toNullableString('abc'), 'abc');
      expect(
        EssentialCoreUtils.toNullableBool({'enabled': 'TrUe'}, 'enabled'),
        isTrue,
      );
      expect(
        EssentialCoreUtils.toNullableBool({'enabled': 'false'}, 'enabled'),
        isFalse,
      );
      expect(EssentialCoreUtils.toNullableBool({}, 'enabled'), isNull);
      expect(EssentialCoreUtils.toNullableDateTime(now), now);
      expect(
        EssentialCoreUtils.toNullableDateTime('2024-01-02T03:04:05Z'),
        DateTime.parse('2024-01-02T03:04:05Z'),
      );
    });

    test('supports generic hash and map defaults helpers', () {
      expect(EssentialCoreUtils.hashObjects(['a', 1, true]),
          Object.hashAll(['a', 1, true]));
      expect(EssentialCoreUtils.hash2('a', 1), Object.hash('a', 1));
      expect(EssentialCoreUtils.hash3('a', 1, true), Object.hash('a', 1, true));
      expect(EssentialCoreUtils.hash4('a', 1, true, null),
          Object.hash('a', 1, true, null));

      final values = {'limit': 20};
      final defaults = {'limit': 12, 'offset': 0};
      final merged = EssentialCoreUtils.mergeDefaults(values, defaults);

      expect(merged, {'limit': 20, 'offset': 0});
      expect(defaults, {'limit': 12, 'offset': 0});
      expect(values, {'limit': 20});
    });

    test('normalizes generic text, list, and map values', () {
      expect(EssentialCoreUtils.stringify(null), '');
      expect(EssentialCoreUtils.stringify(<String>[]), '');
      expect(EssentialCoreUtils.stringify(10), '10');
      expect(EssentialCoreUtils.blankToNull('  texto  '), 'texto');
      expect(EssentialCoreUtils.blankToNull(' null '), isNull);
      expect(EssentialCoreUtils.blankToNull('   '), isNull);
      expect(EssentialCoreUtils.stringOrDefault('', 'fallback'), 'fallback');
      expect(
          EssentialCoreUtils.stringOrDefault(' value ', 'fallback'), 'value');
      expect(EssentialCoreUtils.stringList(['a', 1, true]), ['a', '1', 'true']);
      expect(EssentialCoreUtils.stringList('abc'), isEmpty);
      expect(
        EssentialCoreUtils.mapList([
          {'id': 1},
          'ignored',
          {'name': 'Ana'}
        ]),
        [
          {'id': 1},
          {'name': 'Ana'}
        ],
      );
      expect(EssentialCoreUtils.mapList('abc'), isEmpty);
      expect(EssentialCoreUtils.onlyNumbers('(11) 99999-0000'), '11999990000');
      expect(EssentialCoreUtils.onlyNumbers('abc-.-'), '');
      expect(EssentialCoreUtils.onlyNumbers('１２３.456'), '456');
      expect(EssentialCoreUtils.onlyNumbers(null), '');
    });

    test('parses loose boolean and boolean-like values', () {
      expect(EssentialCoreUtils.parseBoolLoose(true), isTrue);
      expect(EssentialCoreUtils.parseBoolLoose('sim'), isTrue);
      expect(EssentialCoreUtils.parseBoolLoose('YES'), isTrue);
      expect(EssentialCoreUtils.parseBoolLoose('não'), isFalse);
      expect(EssentialCoreUtils.parseBoolLoose('0'), isFalse);
      expect(EssentialCoreUtils.parseBoolLoose('maybe'), isNull);
      expect(EssentialCoreUtils.parseBoolLoose(null), isNull);

      expect(EssentialCoreUtils.toBoolean('1', strict: true), isTrue);
      expect(EssentialCoreUtils.toBoolean('yes', strict: true), isFalse);
      expect(EssentialCoreUtils.toBoolean('false'), isFalse);
      expect(EssentialCoreUtils.toBoolean('anything'), isTrue);
      expect(EssentialCoreUtils.toBoolean(''), isFalse);
    });

    test('trims, filters, and escapes generic strings', () {
      expect(EssentialCoreUtils.trimChars('***abc***', '*'), 'abc');
      expect(EssentialCoreUtils.ltrimChars('---abc---', '-'), 'abc---');
      expect(EssentialCoreUtils.rtrimChars('---abc---', '-'), '---abc');
      expect(EssentialCoreUtils.trimChars('  abc  '), 'abc');
      expect(EssentialCoreUtils.whitelistChars('a+b*c?', '+?'), '+?');
      expect(EssentialCoreUtils.blacklistChars('a+b*c?', '+?'), 'ab*c');
      expect(EssentialCoreUtils.whitelistChars('abc', ''), '');
      expect(EssentialCoreUtils.blacklistChars('abc', ''), 'abc');
      expect(EssentialCoreUtils.stripLow('a\x00b\nc'), 'abc');
      expect(EssentialCoreUtils.stripLow('a\x00b\nc', keepNewLines: true),
          'ab\nc');
      expect(
        EssentialCoreUtils.escapeHtml('<a href="x&y">\'ok\'</a>'),
        '&lt;a href=&quot;x&amp;y&quot;&gt;&#x27;ok&#x27;&lt;/a&gt;',
      );
      expect(
        EssentialCoreUtils.removeNonIso88591Characters('ação 😀'),
        'ação ',
      );
    });

    test('normalizes email addresses', () {
      expect(
        EssentialCoreUtils.normalizeEmail('Some.One+Tag@GoogleMail.com'),
        'someone@gmail.com',
      );
      expect(
        EssentialCoreUtils.normalizeEmail('User.Name@Example.COM'),
        'user.name@example.com',
      );
      expect(
        EssentialCoreUtils.normalizeEmail(
          'User.Name@Example.COM',
          lowercase: false,
        ),
        'User.Name@example.com',
      );
      expect(EssentialCoreUtils.normalizeEmail('invalid-email'), '');
    });

    test('exposes CPF helper validations', () {
      expect(EssentialCoreUtils.blacklistedCPF('00000000000'), isTrue);
      expect(EssentialCoreUtils.blacklistedCPF('11111111111'), isTrue);
      expect(EssentialCoreUtils.blacklistedCPF('52998224725'), isFalse);
      expect(
          EssentialCoreUtils.gerarDigitoVerificador(
              [5, 2, 9, 9, 8, 2, 2, 4, 7]),
          2);
    });

    test('sanitizes CPF values', () {
      expect(EssentialCoreUtils.sanitizarCpf('529.982.247-25'), '52998224725');
      expect(EssentialCoreUtils.sanitizarCpf(' cpf: 529 982 247 25 '),
          '52998224725');
      expect(EssentialCoreUtils.sanitizarCpf('abc-.-'), '');
      expect(EssentialCoreUtils.sanitizarCpf('１２３.456'), '456');
      expect(EssentialCoreUtils.sanitizarCpf(''), '');
      expect(EssentialCoreUtils.sanitizarCpf(null), '');
    });

    test('formats CPF values', () {
      expect(EssentialCoreUtils.formatarCpf('52998224725'), '529.982.247-25');
      expect(
          EssentialCoreUtils.formatarCpf('529.982.247-25'), '529.982.247-25');
      expect(EssentialCoreUtils.formatarCpf('CPF 529 982 247 25'),
          '529.982.247-25');
      expect(EssentialCoreUtils.formatarCpf('123'), '123');
      expect(EssentialCoreUtils.formatarCpf('123456789101'), '123456789101');
      expect(EssentialCoreUtils.formatarCpf(null), '');
    });

    test('generates valid CPF values', () {
      final cpf = EssentialCoreUtils.gerarCpf(random: Random(1));
      final formattedCpf =
          EssentialCoreUtils.gerarCpf(formatado: true, random: Random(1));

      expect(cpf, hasLength(11));
      expect(EssentialCoreUtils.validarCPF(cpf), isTrue);
      expect(formattedCpf, EssentialCoreUtils.formatarCpf(cpf));
      expect(EssentialCoreUtils.validarCPF(formattedCpf), isTrue);
    });

    test('masks CPF in federal public-display style', () {
      expect(
        EssentialCoreUtils.mascararCpfGovernoFederal('123.456.789-10'),
        '***.456.789-**',
      );
      expect(
        EssentialCoreUtils.mascararCpfGovernoFederal(
          '12345678910',
          ocultador: 'X',
        ),
        'XXX.456.789-XX',
      );
      expect(
        EssentialCoreUtils.mascararCpfGovernoFederal(
          '12345678910',
          ocultador: '',
        ),
        '***.456.789-**',
      );
      expect(
        EssentialCoreUtils.mascararCpfGovernoFederal(
          '12345678910',
          ocultador: '#!',
        ),
        '###.456.789-##',
      );
      expect(
        EssentialCoreUtils.mascararCpfGovernoFederal('CPF 123.456.789-10'),
        '***.456.789-**',
      );
      expect(EssentialCoreUtils.mascararCpfGovernoFederal('123'), '123');
      expect(EssentialCoreUtils.mascararCpfGovernoFederal(null), '');
    });

    test('masks CNPJ in federal public-display style without hiding digits',
        () {
      expect(
        EssentialCoreUtils.mascararCnpjGovernoFederal('54.550.752/0001-55'),
        '54.550.752/0001-55',
      );
      expect(
        EssentialCoreUtils.mascararCnpjGovernoFederal('12abc34501de35'),
        '12.ABC.345/01DE-35',
      );
      expect(
        EssentialCoreUtils.mascararCnpjGovernoFederal('12ABC34501DEAA'),
        '12ABC34501DEAA',
      );
      expect(EssentialCoreUtils.mascararCnpjGovernoFederal('123'), '123');
      expect(EssentialCoreUtils.mascararCnpjGovernoFederal(null), '');
    });

    test('masks CPF or CNPJ documents in federal public-display style', () {
      expect(
        EssentialCoreUtils.mascararDocumentoGovernoFederal(
          'CPF 123.456.789-10',
        ),
        '***.456.789-**',
      );
      expect(
        EssentialCoreUtils.mascararDocumentoGovernoFederal(
          '54.550.752/0001-55',
        ),
        '54.550.752/0001-55',
      );
      expect(
        EssentialCoreUtils.mascararDocumentoGovernoFederal(
          '12.ABC.345/01DE-35',
        ),
        '12.ABC.345/01DE-35',
      );
      expect(
        EssentialCoreUtils.mascararDocumentoGovernoFederal(
          '12345678910',
          ocultadorCpf: 'X',
        ),
        'XXX.456.789-XX',
      );
      expect(
        EssentialCoreUtils.mascararDocumentoGovernoFederal('doc 123'),
        'DOC123',
      );
      expect(EssentialCoreUtils.mascararDocumentoGovernoFederal(null), '');
    });

    test('validates CPF and CNPJ values', () {
      expect(EssentialCoreUtils.validarCPF('529.982.247-25'), isTrue);
      expect(EssentialCoreUtils.validarCPF('106.206.347-31'), isTrue);
      expect(EssentialCoreUtils.validarCPF('106.206.347-32'), isFalse);
      expect(EssentialCoreUtils.validarCPF('000.000.000-00'), isFalse);
      expect(EssentialCoreUtils.validarCPF('111.111.111-11'), isFalse);
      expect(EssentialCoreUtils.validarCnpj('04.252.011/0001-10'), isTrue);
      expect(EssentialCoreUtils.validarCnpj('39.223.581/0001-66'), isTrue);
      expect(EssentialCoreUtils.validarCnpj('39.223.581/0001-67'), isFalse);
      expect(EssentialCoreUtils.validarCnpj('11.111.111/1111-11'), isFalse);
    });

    test('sanitizes CNPJ values', () {
      expect(EssentialCoreUtils.sanitizarCnpj('12.abc.345/01de-35'),
          '12ABC34501DE35');
      expect(EssentialCoreUtils.sanitizarCnpj(' 54.550.752/0001-55 '),
          '54550752000155');
      expect(EssentialCoreUtils.sanitizarCnpj('cnpj: 54.550.752/0001-55'),
          'CNPJ54550752000155');
      expect(EssentialCoreUtils.sanitizarCnpj('12_ábc-345'), '12BC345');
      expect(EssentialCoreUtils.sanitizarCnpj('１２ABC'), 'ABC');
      expect(EssentialCoreUtils.sanitizarCnpj(''), '');
      expect(EssentialCoreUtils.sanitizarCnpj(null), '');
    });

    test('formats CNPJ values', () {
      expect(EssentialCoreUtils.formatarCnpj('12abc34501de35'),
          '12.ABC.345/01DE-35');
      expect(EssentialCoreUtils.formatarCnpj('54550752000155'),
          '54.550.752/0001-55');
      expect(EssentialCoreUtils.formatarCnpj('54.550.752/0001-55'),
          '54.550.752/0001-55');
      expect(
          EssentialCoreUtils.formatarCnpj('12ABC34501DEAA'), '12ABC34501DEAA');
      expect(EssentialCoreUtils.formatarCnpj('123'), '123');
      expect(EssentialCoreUtils.formatarCnpj('123456789012345'),
          '123456789012345');
      expect(EssentialCoreUtils.formatarCnpj(null), '');
    });

    test('generates valid CNPJ values', () {
      final cnpj = EssentialCoreUtils.gerarCnpj(random: Random(1));
      final formattedCnpj =
          EssentialCoreUtils.gerarCnpj(formatado: true, random: Random(1));
      final numericCnpj = EssentialCoreUtils.gerarCnpj(
        alfanumerico: false,
        random: Random(2),
      );

      expect(cnpj, hasLength(14));
      expect(EssentialCoreUtils.validarCnpj(cnpj), isTrue);
      expect(formattedCnpj, EssentialCoreUtils.formatarCnpj(cnpj));
      expect(EssentialCoreUtils.validarCnpj(formattedCnpj), isTrue);
      expect(numericCnpj, matches(RegExp(r'^\d{14}$')));
      expect(EssentialCoreUtils.validarCnpj(numericCnpj), isTrue);
    });

    test('rejects repeated CPF blacklist values', () {
      for (var digit = 0; digit <= 9; digit++) {
        expect(
          EssentialCoreUtils.validarCPF(
              List<String>.filled(11, '$digit').join()),
          isFalse,
          reason: 'repeated CPF must be rejected',
        );
      }
    });

    test('validates legacy numeric CNPJ with the alphanumeric algorithm', () {
      expect(EssentialCoreUtils.validarCnpj('54550752000155'), isTrue);
      expect(EssentialCoreUtils.validarCnpj('54.550.752/0001-55'), isTrue);
      expect(EssentialCoreUtils.validarCnpj('90.021.382/0001-22'), isTrue);
      expect(EssentialCoreUtils.validarCnpj('90.024.778/000123'), isTrue);
      expect(EssentialCoreUtils.validarCnpj('90.025.255/0001-00'), isTrue);
    });

    test('validates Receita Federal alphanumeric CNPJ examples', () {
      expect(EssentialCoreUtils.validarCnpj('12ABC34501DE35'), isTrue);
      expect(EssentialCoreUtils.validarCnpj('12.ABC.345/01DE-35'), isTrue);
      expect(EssentialCoreUtils.validarCnpj('1345C3A5000106'), isTrue);
      expect(EssentialCoreUtils.validarCnpj('R55231B3000757'), isTrue);
      expect(EssentialCoreUtils.validarCnpj('AL.R0K.4K9/0001-68'), isTrue);
      expect(EssentialCoreUtils.validarCnpj('AL.R0K.4K9/VYY0-41'), isTrue);
      expect(EssentialCoreUtils.validarCnpj('32.AYM.RED/0001-08'), isTrue);
      expect(EssentialCoreUtils.validarCnpj('S8.T45.HLW/0001-95'), isTrue);
      expect(EssentialCoreUtils.validarCnpj('S8.T45.HLW/J0ZT-28'), isTrue);
      expect(EssentialCoreUtils.validarCnpj('0R.AT1.HV8/0001-59'), isTrue);
      expect(EssentialCoreUtils.validarCnpj('PY.JKX.ABJ/0001-78'), isTrue);
      expect(EssentialCoreUtils.validarCnpj('DA.HWQ.8TY/P4PL-23'), isTrue);
    });

    test('normalizes lowercase and removes mask characters and spaces', () {
      expect(EssentialCoreUtils.validarCnpj('12abc34501de35'), isTrue);
      expect(EssentialCoreUtils.validarCnpj('12.abc.345/01de-35'), isTrue);
      expect(EssentialCoreUtils.validarCnpj(' 12 ABC 345 01DE 35 '), isTrue);
      expect(EssentialCoreUtils.validarCnpj('\t12ABC34501DE35\n'), isTrue);
    });

    test('rejects CNPJ with invalid check digits', () {
      expect(EssentialCoreUtils.validarCnpj('12ABC34501DE36'), isFalse);
      expect(EssentialCoreUtils.validarCnpj('R55231B3000700'), isFalse);
      expect(EssentialCoreUtils.validarCnpj('90.025.108/000101'), isFalse);
      expect(EssentialCoreUtils.validarCnpj('54.550.752/0001-54'), isFalse);
    });

    test('rejects malformed alphanumeric CNPJ values', () {
      expect(EssentialCoreUtils.validarCnpj(null), isFalse);
      expect(EssentialCoreUtils.validarCnpj(''), isFalse);
      expect(EssentialCoreUtils.validarCnpj('12ABC34501DE'), isFalse);
      expect(EssentialCoreUtils.validarCnpj('12ABC34501DE350'), isFalse);
      expect(EssentialCoreUtils.validarCnpj('90.025.255/0001'), isFalse);
      expect(EssentialCoreUtils.validarCnpj('90.024.420/0001A'), isFalse);
      expect(EssentialCoreUtils.validarCnpj('12ABC34501DEA5'), isFalse);
      expect(EssentialCoreUtils.validarCnpj('12ABC34501DE3A'), isFalse);
      expect(EssentialCoreUtils.validarCnpj('12_ABC34501DE35'), isFalse);
      expect(EssentialCoreUtils.validarCnpj('12ÁBC34501DE35'), isFalse);
      expect(EssentialCoreUtils.validarCnpj('12ABC34501DE35'.padLeft(65)),
          isFalse);
    });

    test('supports strict CNPJ validation mode', () {
      expect(
        EssentialCoreUtils.validarCnpj('12ABC34501DE35', strict: true),
        isTrue,
      );
      expect(
        EssentialCoreUtils.validarCnpj('12.ABC.345/01DE-35', strict: true),
        isTrue,
      );
      expect(
        EssentialCoreUtils.validarCnpj('12abc34501de35', strict: true),
        isFalse,
      );
      expect(
        EssentialCoreUtils.validarCnpj(' 12ABC34501DE35 ', strict: true),
        isFalse,
      );
      expect(
        EssentialCoreUtils.validarCnpj('90.024.778/000123', strict: true),
        isFalse,
      );
    });

    test('rejects repeated numeric CNPJ blacklist values', () {
      for (var digit = 0; digit <= 9; digit++) {
        expect(
          EssentialCoreUtils.validarCnpj(
              List<String>.filled(14, '$digit').join()),
          isFalse,
          reason: 'repeated numeric CNPJ must be rejected',
        );
      }
    });

    test('allows letters in each of the first twelve positions only', () {
      for (var position = 0; position < 12; position++) {
        final chars = List<String>.filled(12, '1');
        chars[position] = 'Z';
        expect(
          EssentialCoreUtils.validarCnpj(_cnpjWithDigits(chars.join())),
          isTrue,
          reason: 'position $position must accept A-Z',
        );
      }

      final root = '1234567890AZ';
      final valid = _cnpjWithDigits(root);
      expect(EssentialCoreUtils.validarCnpj(valid), isTrue);
      expect(EssentialCoreUtils.validarCnpj('${valid.substring(0, 12)}A1'),
          isFalse);
      expect(EssentialCoreUtils.validarCnpj('${valid.substring(0, 13)}Z'),
          isFalse);
    });

    test('validates emails', () {
      expect(EssentialCoreUtils.emailIsValid('dev@example.com'), isTrue);
      expect(EssentialCoreUtils.emailIsValid('invalid-email'), isFalse);
    });

    test('truncate shortens text respecting omission', () {
      expect(EssentialCoreUtils.truncate('essential', 0), '');
      expect(EssentialCoreUtils.truncate('core', 10), 'core');
      expect(EssentialCoreUtils.truncate('essential', 5), 'essen');
      expect(EssentialCoreUtils.truncate('essential', 6, '...'), 'ess...');
      expect(EssentialCoreUtils.truncate('essential', 2, '...'), '..');
    });
  });

  group('EssentialEssentialCoreUtils', () {
    test('hidePartsOfString preserves visible prefix', () {
      expect(
        EssentialCoreUtils.hidePartsOfString('abcdef', visibleCharacters: 3),
        'abc***',
      );
      expect(
        EssentialCoreUtils.hidePartsOfString('abc', visibleCharacters: 3),
        'abc',
      );
      expect(
        EssentialCoreUtils.hidePartsOfString('ab', visibleCharacters: 3),
        'ab',
      );
    });

    test('removerAcentos strips common accented characters', () {
      expect(EssentialCoreUtils.removerAcentos('ação Útil'), 'acao Util');
    });
  });
}
