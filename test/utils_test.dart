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
      expect(EssentialCoreUtils.toNullableDateTime(now), now);
      expect(
        EssentialCoreUtils.toNullableDateTime('2024-01-02T03:04:05Z'),
        DateTime.parse('2024-01-02T03:04:05Z'),
      );
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

    test('validates CPF and CNPJ values', () {
      expect(EssentialCoreUtils.validarCPF('529.982.247-25'), isTrue);
      expect(EssentialCoreUtils.validarCPF('000.000.000-00'), isFalse);
      expect(EssentialCoreUtils.validarCPF('111.111.111-11'), isFalse);
      expect(EssentialCoreUtils.validarCnpj('04.252.011/0001-10'), isTrue);
      expect(EssentialCoreUtils.validarCnpj('11.111.111/1111-11'), isFalse);
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
