// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

import 'package:essential_core/essential_core.dart';
import 'package:test/test.dart';

class MockModel implements SerializeBase {
  final int id;
  final String name;

  MockModel(this.id, this.name);

  @override
  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'name': name,
    };
  }

  factory MockModel.fromMap(Map<String, dynamic> map) {
    return MockModel(
      map['id'] as int,
      map['name'] as String,
    );
  }

  @override
  bool operator ==(covariant MockModel other) {
    if (identical(this, other)) {
      return true;
    }
    return other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

void main() {
  group('DataFrame constructor', () {
    test('initializes error and template outlet context', () {
      final df = DataFrame<MockModel>(
        items: [MockModel(1, 'Jon')],
        totalRecords: 1,
        error: 'network-error',
      );

      expect(df.error, 'network-error');
      expect(df.templateOutletContext['\$implicit'], same(df));
    });
  });

  group('DataFrame.newClear', () {
    test('starts empty', () {
      final df = DataFrame<MockModel>.newClear();

      final person1 = MockModel(1, 'Jon');
      df.add(person1);

      final person2 = MockModel(2, 'Yve');
      df.add(person2);

      expect(df.totalRecords, 0);
      expect(df.length, 2);
      expect(df[0], person1);
      expect(df[1], person2);
    });
  });

  group('DataFrame.fromMapWithFactory', () {
    test('builds a typed dataframe with a builder', () {
      final df = DataFrame<MockModel>.fromMapWithFactory(
        {
          'totalRecords': 2,
          'items': [
            {'id': 1, 'name': 'Jon'},
            {'id': 2, 'name': 'Yve'},
          ],
        },
        MockModel.fromMap,
      );

      expect(df.totalRecords, 2);
      expect(df.items, [MockModel(1, 'Jon'), MockModel(2, 'Yve')]);
    });

    test('accepts missing items and uses the default totalRecords value', () {
      final df = DataFrame<MockModel>.fromMapWithFactory({}, MockModel.fromMap);

      expect(df.totalRecords, 0);
      expect(df.items, isEmpty);
    });

    test('keeps maps when builder is null for dynamic map types', () {
      final df = DataFrame<Map<String, dynamic>>.fromMapWithFactory(
        {
          'totalRecords': 1,
          'items': [
            {'id': 1, 'name': 'Jon'}
          ],
        },
        null,
      );

      expect(df.totalRecords, 1);
      expect(df.items, [
        {'id': 1, 'name': 'Jon'}
      ]);
    });

    test('throws when T implements SerializeBase and builder is null', () {
      final map = {
        'totalRecords': 1,
        'items': [
          {'id': 1, 'name': 'Jon'}
        ]
      };

      expect(
        () => DataFrame<MockModel>.fromMapWithFactory(map, null),
        throwsException,
      );
    });
  });

  group('DataFrame.toListOf', () {
    test('returns an empty list when items is empty', () {
      final df = DataFrame<MockModel>.newClear();

      final result = df.toListOf<MockModel>(MockModel.fromMap);

      expect(result, isEmpty);
    });

    test('returns a typed list when items already match the target type', () {
      final df = DataFrame<MockModel>(
        items: [MockModel(1, 'Jon')],
        totalRecords: 1,
      );

      final result = df.toListOf<MockModel>(MockModel.fromMap);

      expect(result, [MockModel(1, 'Jon')]);
    });

    test('converts a list of maps using the provided factory', () {
      final df = DataFrame<Map<String, dynamic>>(
        items: [
          {'id': 1, 'name': 'Jon'}
        ],
        totalRecords: 1,
      );

      final result = df.toListOf<MockModel>(MockModel.fromMap);

      expect(result, [MockModel(1, 'Jon')]);
    });

    test('returns an empty list for unsupported item types', () {
      final df = DataFrame<Object>(
        items: [Object()],
        totalRecords: 1,
      );

      final result = df.toListOf<MockModel>(MockModel.fromMap);

      expect(result, isEmpty);
    });
  });

  group('DataFrame serialization', () {
    test('toMap exposes totalRecords and items', () {
      final df = DataFrame<MockModel>(
        items: [MockModel(1, 'Jon')],
        totalRecords: 1,
      );

      final map = df.toMap();

      expect(map['totalRecords'], 1);
      expect(map['items'], hasLength(1));
      expect((map['items'] as List).first, isA<MockModel>());
    });

    test('itemsAsMap serializes items that implement SerializeBase', () {
      final df = DataFrame<MockModel>(
        items: [MockModel(1, 'Jon')],
        totalRecords: 1,
      );

      expect(df.itemsAsMap, [
        {'id': 1, 'name': 'Jon'}
      ]);
    });

    test('itemsAsMap returns maps when items already contain maps', () {
      final df = DataFrame<Map<String, dynamic>>(
        items: [
          {'id': 1, 'name': 'Jon'}
        ],
        totalRecords: 1,
      );

      expect(df.itemsAsMap, [
        {'id': 1, 'name': 'Jon'}
      ]);
    });

    test('itemsAsMap handles LinkedHashMap instances correctly', () {
      final rawDecoded = jsonDecode('{"id": 1, "name": "Jon"}');

      final df = DataFrame<dynamic>(
        items: [rawDecoded],
        totalRecords: 1,
      );

      final result = df.itemsAsMap;

      expect(result, isNotEmpty);
      expect(result.first['id'], 1);
    });

    test('itemsAsMap returns an empty list for non-serializable items', () {
      final df = DataFrame<Object>(
        items: [Object()],
        totalRecords: 1,
      );

      expect(df.itemsAsMap, isEmpty);
    });

    test('toJson serializes totalRecords and items', () {
      final df = DataFrame<MockModel>(
        items: [MockModel(1, 'Jon')],
        totalRecords: 1,
      );

      final json = jsonDecode(df.toJson()) as Map<String, dynamic>;

      expect(json, {
        'totalRecords': 1,
        'items': [
          {'id': 1, 'name': 'Jon'}
        ]
      });
    });

    test('toJson serializes DateTime values as ISO-8601 strings', () {
      final date = DateTime(2024, 1, 1, 12, 0, 0);
      final df = DataFrame<dynamic>(
        items: [date],
        totalRecords: 1,
      );

      final jsonStr = df.toJson();
      final json = jsonDecode(jsonStr) as Map<String, dynamic>;

      expect((json['items'] as List).first, date.toIso8601String());
    });

    test('toString includes the dataframe identifier', () {
      final df = DataFrame<MockModel>(
        items: [MockModel(1, 'Jon')],
        totalRecords: 1,
      );

      expect(df.toString(), startsWith('instanceof DataFrame | '));
    });
  });

  group('DataFrame list operations', () {
    test('adds, inserts, updates, and removes items', () {
      final df = DataFrame<MockModel>.newClear();
      final jon = MockModel(1, 'Jon');
      final yve = MockModel(2, 'Yve');
      final ana = MockModel(3, 'Ana');

      df.add(jon);
      df.addAll([yve]);
      df.insert(1, ana);
      df[0] = MockModel(4, 'Kai');

      expect(df.length, 3);
      expect(df[0], MockModel(4, 'Kai'));
      expect(df[1], ana);
      expect(df[2], yve);

      expect(df.removeAt(1), ana);
      expect(df.remove(yve), isTrue);
      expect(df.length, 1);
    });

    test('removeItem returns the original index of the removed item', () {
      final jon = MockModel(1, 'Jon');
      final yve = MockModel(2, 'Yve');
      final df = DataFrame<MockModel>(
        items: [jon, yve],
        totalRecords: 2,
      );

      final idx = df.removeItem(yve);

      expect(idx, 1);
      expect(df.items, [jon]);
    });

    test('removeItem returns -1 when the item does not exist', () {
      final jon = MockModel(1, 'Jon');
      final df = DataFrame<MockModel>(
        items: [jon],
        totalRecords: 1,
      );

      final idx = df.removeItem(MockModel(2, 'Yve'));

      expect(idx, -1);
      expect(df.items, [jon]);
    });

    test('allows resizing the underlying list length', () {
      final df = DataFrame<MockModel>(
        items: [MockModel(1, 'Jon'), MockModel(2, 'Yve')],
        totalRecords: 2,
      );

      df.length = 1;

      expect(df.items, [MockModel(1, 'Jon')]);
    });
  });
}
