import 'package:essential_core/essential_core.dart';
import 'package:test/test.dart';

void main() {
  group('InteractiveTextMask', () {
    test('formats CPF values interactively', () {
      final mask = InteractiveTextMask.cpf();

      expect(mask.format(''), '');
      expect(mask.format('1'), '1');
      expect(mask.format('123'), '123.');
      expect(mask.format('12345678901'), '123.456.789-01');
      expect(mask.format('123.456.789-01'), '123.456.789-01');
      expect(mask.unmask('123.456.789-01'), '12345678901');
    });

    test('ignores rejected CPF characters and extra digits', () {
      final mask = InteractiveTextMask.cpf();

      final result = mask.apply(MaskedTextValue.collapsed('123abc4567890199'));

      expect(result.text, '123.456.789-01');
      expect(result.rawText, '12345678901');
      expect(result.isComplete, isTrue);
      expect(result.selectionStart, result.text.length);
      expect(result.selectionEnd, result.text.length);
    });

    test('formats alphanumeric CNPJ values with numeric check digits', () {
      final mask = InteractiveTextMask.cnpj();

      expect(mask.format('12abc34501de35'), '12.ABC.345/01DE-35');
      expect(mask.unmask('12.ABC.345/01DE-35'), '12ABC34501DE35');
      expect(mask.apply(MaskedTextValue.collapsed('12ABC34501DEA5')).text,
          '12.ABC.345/01DE-5');
    });

    test('formats numeric CNPJ values when alphanumeric mode is disabled', () {
      final mask = InteractiveTextMask.cnpj(alphanumeric: false);

      expect(mask.format('54550752000155'), '54.550.752/0001-55');
      expect(mask.format('12ABC34501DE35'), '12.345.013/5');
      expect(InteractiveTextMask.cnpjNumeric().format('54550752000155'),
          '54.550.752/0001-55');
      expect(InteractiveTextMask.cnpjAlphanumeric().format('12abc34501de35'),
          '12.ABC.345/01DE-35');
    });

    test('supports non-eager display formatting', () {
      final mask = InteractiveTextMask.cpf(eager: false);

      expect(mask.format('123'), '123');
      expect(mask.format('12345678901'), '123.456.789-01');
      expect(mask.format('123', eager: true), '123.');
    });

    test('maps collapsed selection through inserted literals', () {
      final mask = InteractiveTextMask.cpf();

      final result = mask.apply(
        MaskedTextValue(
          text: '1234',
          selectionStart: 4,
          selectionEnd: 4,
        ),
      );

      expect(result.text, '123.4');
      expect(result.selectionStart, 5);
      expect(result.selectionEnd, 5);
    });

    test('does not push manually positioned cursor across eager literals', () {
      final mask = InteractiveTextMask.cpf();

      final result = mask.apply(
        MaskedTextValue(
          text: '123.456',
          selectionStart: 3,
          selectionEnd: 3,
        ),
      );

      expect(result.text, '123.456.');
      expect(result.selectionStart, 3);
      expect(result.selectionEnd, 3);
    });

    test('moves cursor across eager literals while typing through applyEdit',
        () {
      final mask = InteractiveTextMask.cpf();

      final result = mask.applyEdit(
        oldValue: MaskedTextValue.collapsed('12'),
        newValue: MaskedTextValue.collapsed('123'),
      );

      expect(result.text, '123.');
      expect(result.selectionStart, 4);
      expect(result.selectionEnd, 4);
    });

    test('does not trap backspace when a mask literal is deleted', () {
      final mask = InteractiveTextMask.cpf();

      final result = mask.applyEdit(
        oldValue: MaskedTextValue(
          text: '123.456.789-00',
          selectionStart: 4,
          selectionEnd: 4,
        ),
        newValue: MaskedTextValue(
          text: '123456.789-00',
          selectionStart: 3,
          selectionEnd: 3,
        ),
      );

      expect(result.text, '123.456.789-00');
      expect(result.selectionStart, 3);
      expect(result.selectionEnd, 3);
    });

    test('maps selection ranges through the mask', () {
      final mask = InteractiveTextMask.cpf();

      final result = mask.apply(
        MaskedTextValue(
          text: '123456',
          selectionStart: 2,
          selectionEnd: 5,
        ),
      );

      expect(result.text, '123.456.');
      expect(result.selectionStart, 2);
      expect(result.selectionEnd, 6);
      expect(result.isCollapsed, isFalse);
    });

    test('supports generic masks and custom tokens', () {
      final mask = InteractiveTextMask(pattern: 'SS-000');

      expect(mask.format('ab123'), 'AB-123');
      expect(mask.unmask('AB-123'), 'AB123');

      final custom = InteractiveTextMask(
        pattern: '##/##',
        tokens: const <String, MaskToken>{
          '#': MaskToken.digit,
        },
      );

      expect(custom.format('1234'), '12/34');
    });

    test('any token does not consume mask literals as raw text', () {
      final mask = InteractiveTextMask(pattern: '**-**');

      final formatted = mask.format('ABCD', eager: false);

      expect(formatted, 'AB-CD');
      expect(mask.unmask(formatted), 'ABCD');
      expect(mask.format(formatted, eager: false), formatted);
    });

    test('supports escaped token characters as literals', () {
      final mask = InteractiveTextMask(pattern: r'\0\0 000');

      expect(mask.maxRawLength, 3);
      expect(mask.format('123'), '00 123');
      expect(mask.unmask('00 123'), '123');
    });

    test('normalizes invalid selections and copyWith offsets safely', () {
      final value = MaskedTextValue(text: 'abc', selectionEnd: 1);

      expect(value.selectionStart, 1);
      expect(value.selectionEnd, 1);

      final inverted = MaskedTextValue(
        text: 'abc',
        selectionStart: 3,
        selectionEnd: -2,
      );

      expect(inverted.selectionStart, 0);
      expect(inverted.selectionEnd, 3);
      expect(value.copyWith(text: 'a').selectionStart, 1);
      expect(value.copyWith(text: '').selectionStart, 0);
    });

    test('rejects masks without editable tokens', () {
      expect(
        () => InteractiveTextMask(pattern: '---'),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('throws when token normalization returns an invalid length', () {
      final mask = InteractiveTextMask(
        pattern: '#',
        tokens: <String, MaskToken>{
          '#': MaskToken(
            accepts: (_) => true,
            normalize: (_) => 'AB',
          ),
        },
      );

      expect(() => mask.format('1'), throwsA(isA<StateError>()));
    });
  });
}
