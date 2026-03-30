import 'package:essential_core/essential_core.dart';
import 'package:test/test.dart';

void main() {
  group('CoreUtils', () {
    test('parses nullable scalar values', () {
      expect(CoreUtils.toNullableInt('12'), 12);
      expect(CoreUtils.toNullableInt('abc'), isNull);
      expect(CoreUtils.toNullableDouble('10,5'), 10.5);
      expect(CoreUtils.toNullableString(1), isNull);
      expect(
        CoreUtils.toNullableDateTime('2024-01-02T03:04:05Z'),
        DateTime.parse('2024-01-02T03:04:05Z'),
      );
    });

    test('validates CPF and CNPJ values', () {
      expect(CoreUtils.validarCPF('529.982.247-25'), isTrue);
      expect(CoreUtils.validarCPF('111.111.111-11'), isFalse);
      expect(CoreUtils.validarCnpj('04.252.011/0001-10'), isTrue);
      expect(CoreUtils.validarCnpj('11.111.111/1111-11'), isFalse);
    });

    test('validates emails', () {
      expect(CoreUtils.emailIsValid('dev@example.com'), isTrue);
      expect(CoreUtils.emailIsValid('invalid-email'), isFalse);
    });

    test('truncate shortens text respecting omission', () {
      expect(CoreUtils.truncate('essential', 5), 'essen');
      expect(CoreUtils.truncate('essential', 6, '...'), 'ess...');
      expect(CoreUtils.truncate('essential', 2, '...'), '..');
    });
  });

  group('EssentialCoreUtils', () {
    test('hidePartsOfString preserves visible prefix', () {
      expect(
        EssentialCoreUtils.hidePartsOfString('abcdef', visibleCharacters: 3),
        'abc***',
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
