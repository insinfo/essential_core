import 'dart:convert';

import 'package:essential_core/essential_core.dart';
import 'package:test/test.dart';

void main() {
  group('Filter', () {
    test('serializes and deserializes a map', () {
      final filter = Filter(key: 'status', value: 'active', operator: '=');

      final map = filter.toMap();
      final restored = Filter.fromMap(map);

      expect(map, {
        'key': 'status',
        'value': 'active',
        'operator': '=',
      });
      expect(restored.key, 'status');
      expect(restored.value, 'active');
      expect(restored.operator, '=');
    });
  });

  group('FilterSearchField', () {
    test('serializes and deserializes a map', () {
      final field = FilterSearchField(
        label: 'Name',
        field: 'name',
        active: true,
        operator: 'ilike',
      );

      final map = field.toMap();
      final restored = FilterSearchField.fromMap(map);

      expect(map, {
        'label': 'Name',
        'field': 'name',
        'active': true,
        'operator': 'ilike',
      });
      expect(restored.label, 'Name');
      expect(restored.field, 'name');
      expect(restored.active, isTrue);
      expect(restored.operator, 'ilike');
    });
  });

  group('Filters', () {
    test('toMap and getParams expose reserved and custom values', () {
      final filters = Filters(
        limit: 20,
        offset: 40,
        searchString: 'ana',
        orderBy: 'name',
        orderDir: 'asc',
        orderFields: const <FilterOrderField>[
          FilterOrderField(field: 'name', direction: 'asc'),
          FilterOrderField(field: 'createdAt', direction: 'desc'),
        ],
        additionalFilters: {
          'status': 'active',
          'teamId': 10,
          'currentOnly': true,
        },
      );
      filters.addSearchInField(
        FilterSearchField(label: 'Name', field: 'name', active: true),
      );

      final map = filters.toMap();
      final params = filters.getParams();

      expect(map['limit'], 20);
      expect(map['offset'], 40);
      expect(map['search'], 'ana');
      expect(map['status'], 'active');
      expect(map['teamId'], 10);
      expect(map['currentOnly'], isTrue);
      expect(jsonDecode(map['orderFields'] as String), [
        {
          'field': 'name',
          'direction': 'asc',
        },
        {
          'field': 'createdAt',
          'direction': 'desc',
        },
      ]);
      expect(jsonDecode(map['searchInFields'] as String), [
        {
          'label': 'Name',
          'field': 'name',
          'active': true,
          'operator': '=',
        }
      ]);
      expect(params['orderDir'], 'asc');
      expect(params['currentOnly'], 'true');
    });

    test('fromMap accepts searchInFields as a json string', () {
      final filters = Filters.fromMap({
        'limit': '15',
        'offset': '30',
        'search': 'maria',
        'orderBy': 'createdAt',
        'orderDir': 'desc',
        'orderFields': jsonEncode([
          {
            'field': 'createdAt',
            'direction': 'desc',
          },
          {
            'field': 'id',
            'direction': 'asc',
          },
        ]),
        'searchInFields': jsonEncode([
          {
            'label': 'Name',
            'field': 'name',
            'active': true,
            'operator': 'ilike',
          }
        ]),
        'status': 'pending',
        'teamId': '9',
      });

      expect(filters.limit, 15);
      expect(filters.offset, 30);
      expect(filters.searchString, 'maria');
      expect(filters.orderBy, 'createdAt');
      expect(filters.orderDir, 'desc');
      expect(filters.orderFields, hasLength(2));
      expect(filters.orderFields.first.field, 'createdAt');
      expect(filters.orderFields.first.direction, 'desc');
      expect(filters.searchInFields, hasLength(1));
      expect(filters.searchInFields.first.field, 'name');
      expect(filters.searchInFields.first.operator, 'ilike');
      expect(filters.additionalFilters['status'], 'pending');
      expect(filters.additionalFilters['teamId'], '9');
    });

    test('fromMap accepts searchInFields as a list of maps', () {
      final filters = Filters.fromMap({
        'searchInFields': [
          {
            'label': 'CPF',
            'field': 'cpf',
            'active': false,
            'operator': '=',
          }
        ],
      });

      expect(filters.searchInFields, hasLength(1));
      expect(filters.searchInFields.first.label, 'CPF');
      expect(filters.searchInFields.first.active, isFalse);
    });

    test('fromMap merges nested additionalFilters and top-level custom keys',
        () {
      final filters = Filters.fromMap({
        'additionalFilters': jsonEncode({
          'status': 'active',
          'teamId': 7,
        }),
        'region': 'south',
      });

      expect(filters.additionalFilters, {
        'status': 'active',
        'teamId': 7,
        'region': 'south',
      });
    });

    test('fillFromFilters copies values from another instance', () {
      final source = Filters(
        limit: 50,
        offset: 100,
        searchString: 'text',
        orderBy: 'id',
        orderDir: 'asc',
        orderFields: const <FilterOrderField>[
          FilterOrderField(field: 'id', direction: 'asc'),
          FilterOrderField(field: 'createdAt', direction: 'desc'),
        ],
        additionalFilters: {
          'status': 'ok',
          'teamId': 7,
        },
      );
      source.addSearchInField(
        FilterSearchField(label: 'ID', field: 'id', active: true),
      );

      final target = Filters();
      target.fillFromFilters(source);

      expect(target.limit, 50);
      expect(target.offset, 100);
      expect(target.searchString, 'text');
      expect(target.orderBy, 'id');
      expect(target.orderDir, 'asc');
      expect(target.orderFields, hasLength(2));
      expect(target.orderFields.last.field, 'createdAt');
      expect(target.searchInFields, hasLength(1));
      expect(target.additionalFilters, {
        'status': 'ok',
        'teamId': 7,
      });
    });

    test('supports mutating additional filters explicitly', () {
      final filters = Filters();

      filters.setAdditionalFilter('status', 'active');
      filters.setAdditionalFilter('teamId', 12);
      filters.removeAdditionalFilter('status');

      expect(filters.additionalFilters, {
        'teamId': 12,
      });
    });

    test('setSingleOrder keeps legacy and multi-order state in sync', () {
      final filters = Filters();

      filters.setSingleOrder('pontuacao_final', direction: 'desc');

      expect(filters.orderBy, 'pontuacao_final');
      expect(filters.orderDir, 'desc');
      expect(filters.orderFields, hasLength(1));
      expect(filters.orderFields.first.field, 'pontuacao_final');
    });
  });
}
