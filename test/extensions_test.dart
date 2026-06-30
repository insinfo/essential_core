import 'dart:io';

import 'package:essential_core/essential_core.dart';
import 'package:test/test.dart';

List<String> _portugueseTitleCaseCollection() {
  return File('test/fixtures/portuguese_title_case_collection.txt')
      .readAsLinesSync()
      .where((line) => line.trim().isNotEmpty)
      .toList();
}

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

    test('toPortugueseTitleCase uses Portuguese title rules', () {
      expect(
        "SANTA BÁRBARA D'OESTE".toPortugueseTitleCase(),
        "Santa Bárbara D'Oeste",
      );
      expect(
        'SÃO JOSÉ DO RIO PARDO'.toPortugueseTitleCase(),
        'São José do Rio Pardo',
      );
      expect(
        'PARCELAMENTO DE IPTU'.toPortugueseTitleCase(),
        'Parcelamento de IPTU',
      );
      expect('joão de deus'.toPortugueseTitleCase(), 'João de Deus');
    });

    test('toPortugueseTitleCase preserves acronyms and punctuation', () {
      expect(
        'consulta cpf e cnpj no gov.br'.toPortugueseTitleCase(),
        'Consulta CPF e CNPJ no gov.br',
      );
      expect('(iptu), iss e pje'.toPortugueseTitleCase(), '(IPTU), ISS e PJe');
      expect(
        'rio-das-ostras e cabo-frio'.toPortugueseTitleCase(),
        'Rio-das-Ostras e Cabo-Frio',
      );
      expect('  área   de   ti  '.toPortugueseTitleCase(), 'Área de TI');
    });

    test('PtTitleCase converts strings without extension syntax', () {
      expect(PtTitleCase.convert('sistema sei e eproc'), 'Sistema SEI e eProc');
      expect(PtTitleCase.convert(''), '');
      expect(PtTitleCase.convert('   '), '');
    });

    test('toPortugueseTitleCase accepts custom lowercase words and acronyms',
        () {
      expect(
        'relatório conforme norma abc'.toPortugueseTitleCase(
          lowercaseWords: const <String>['conforme'],
          acronyms: const <String, String>{'abc': 'ABC'},
        ),
        'Relatório conforme Norma ABC',
      );
      expect(
        PtTitleCase.convert(
          'consulta via api municipal',
          lowercaseWords: const <String>['via'],
          acronyms: const <String, String>{'api': 'API'},
        ),
        'Consulta via API Municipal',
      );
      expect(
        'processo sei e pje'.toPortugueseTitleCase(
          acronyms: const <String, String>{'pje': 'PJE'},
        ),
        'Processo SEI e PJE',
      );
    });

    test('toPortugueseTitleCase handles the real service-name collection', () {
      final lines = _portugueseTitleCaseCollection();

      expect(lines, hasLength(259));

      for (final line in lines) {
        final converted = line.toPortugueseTitleCase();

        expect(converted, isNotEmpty, reason: line);
        expect(converted, converted.trim(), reason: line);
        expect(converted.contains(RegExp(r'\s{2,}')), isFalse, reason: line);
        expect(converted.toPortugueseTitleCase(), converted, reason: line);
      }
    });

    test('toPortugueseTitleCase matches key collection expectations', () {
      const cases = <String, String>{
        'Ligação água pluvial': 'Ligação Água Pluvial',
        'Autorização para confecção de talões':
            'Autorização para Confecção de Talões',
        'AUTO  DE INFRAÇAO SEMOB': 'Auto de Infraçao SEMOB',
        'Inscrição como ambulante': 'Inscrição como Ambulante',
        'DEVOLUÇÃO DO VALOR DA TAXA DE INSCRIÇÃO VI CONCURSO PÚBLICO':
            'Devolução do Valor da Taxa de Inscrição VI Concurso Público',
        'notificaçao/intimaçao': 'Notificaçao/Intimaçao',
        'PROCESSO JUDICIAL - PCPT': 'Processo Judicial - PCPT',
        'PROCESSO JUDICIAL - PSPUA': 'Processo Judicial - PSPUA',
        'Calculo de ITBI online/Eletrônico':
            'Calculo de ITBI Online/Eletrônico',
        'Estação Rádio Base (ERB)': 'Estação Rádio Base (ERB)',
        'ISENÇÃO DE IPTU- LC.:052/2017 art.: 2°':
            'Isenção de IPTU- LC.:052/2017 Art.: 2°',
        'PPP - PERFIL PROFISSIOGRÁFICO PREVIDENCIÁRIO':
            'PPP - Perfil Profissiográfico Previdenciário',
        'DEFESA/RECURSO': 'Defesa/Recurso',
        'B.O.F': 'B.O.F',
        'INDICAÇÃO - CMRO': 'Indicação - CMRO',
        'DESENQUADRAMENTO NO SIMEI': 'Desenquadramento no SIMEI',
        'INSCRIÇÃO DE CANTEIRO DE OBRAS PJ':
            'Inscrição de Canteiro de Obras PJ',
        'INSCRIÇÃO DE CANTEIRO DE OBRAS PF':
            'Inscrição de Canteiro de Obras PF',
        'Tribunal de Contas do Estado do Rio de Janeiro - TCE/RJ':
            'Tribunal de Contas do Estado do Rio de Janeiro - TCE/RJ',
        'TERMO DE AJUSTE DE CONTAS - TAC': 'Termo de Ajuste de Contas - TAC',
        'x - READAPTAÇÃO DE FUNÇÃO': 'X - Readaptação de Função',
        'X - TERMO DE AJUSTE DE CONTAS ': 'X - Termo de Ajuste de Contas',
      };

      for (final entry in cases.entries) {
        expect(entry.key.toPortugueseTitleCase(), entry.value);
      }
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
