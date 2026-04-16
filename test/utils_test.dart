import 'package:essential_core/essential_core.dart';
import 'package:test/test.dart';

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
      expect(EssentialCoreUtils.blacklistedCPF('11111111111'), isTrue);
      expect(EssentialCoreUtils.blacklistedCPF('52998224725'), isFalse);
      expect(
          EssentialCoreUtils.gerarDigitoVerificador(
              [5, 2, 9, 9, 8, 2, 2, 4, 7]),
          2);
    });

    test('validates CPF and CNPJ values', () {
      expect(EssentialCoreUtils.validarCPF('529.982.247-25'), isTrue);
      expect(EssentialCoreUtils.validarCPF('111.111.111-11'), isFalse);
      expect(EssentialCoreUtils.validarCnpj('04.252.011/0001-10'), isTrue);
      expect(EssentialCoreUtils.validarCnpj('11.111.111/1111-11'), isFalse);
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
