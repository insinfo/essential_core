import 'package:essential_core/essential_core.dart';
import 'package:test/test.dart';

void main() {
  group('StringExtensions', () {
    test('toCapitalized converts the first character and lowercases the rest',
        () {
      expect('jOAO'.toCapitalized(), 'Joao');
      expect(''.toCapitalized(), '');
    });

    test('toTitleCase capitalizes each word', () {
      expect('joAO da   silVA'.toTitleCase(), 'Joao Da Silva');
      expect(''.toTitleCase(), '');
    });

    test('containsIgnoreCase ignores case differences', () {
      expect('Essential Core'.containsIgnoreCase('core'), isTrue);
      expect('Essential Core'.containsIgnoreCase('dart'), isFalse);
    });

    test('containsIgnoreAccents ignores case and diacritics', () {
      expect('Informacao Basica'.containsIgnoreAccents('informação'), isTrue);
      expect('Joao'.containsIgnoreAccents('maria'), isFalse);
    });

    test('withoutAccents removes diacritics', () {
      expect('ação Útil'.withoutAccents, 'acao Util');
    });

    test('equalsIgnoreCase compares nullable values case-insensitively', () {
      expect('x'.equalsIgnoreCase('ABC', 'abc'), isTrue);
      expect('x'.equalsIgnoreCase(null, null), isTrue);
      expect('x'.equalsIgnoreCase('ABC', null), isFalse);
    });
  });

  group('SetExtension', () {
    test('replace updates an existing item', () {
      final values = <int>{1, 2, 3};

      values.replace(2, 4);

      expect(values, <int>{1, 3, 4});
    });

    test('replace does nothing when the old item is missing', () {
      final values = <int>{1, 2, 3};

      values.replace(9, 4);

      expect(values, <int>{1, 2, 3});
    });

    test('removeAndAdd removes the old item and inserts the new one', () {
      final values = <String>{'a', 'b'};

      values.removeAndAdd('b', 'c');

      expect(values, <String>{'a', 'c'});
    });

    test('removeAndAdd still inserts the new item when the old one is absent',
        () {
      final values = <String>{'a', 'b'};

      values.removeAndAdd('z', 'c');

      expect(values, <String>{'a', 'b', 'c'});
    });
  });
}
