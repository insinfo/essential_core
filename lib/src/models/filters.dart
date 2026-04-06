import 'dart:convert';

import 'filter_search_field.dart';

/// One sorting criterion used by [Filters].
class FilterOrderField {
  /// Field identifier to sort by.
  final String field;

  /// Sort direction, usually `asc` or `desc`.
  final String direction;

  /// Creates a sorting criterion.
  const FilterOrderField({
    required this.field,
    this.direction = 'desc',
  });

  /// Creates an instance from a serialized map.
  factory FilterOrderField.fromMap(Map<String, dynamic> map) {
    return FilterOrderField(
      field: map['field']?.toString() ?? '',
      direction: map['direction']?.toString() ?? 'desc',
    );
  }

  /// Serializes this criterion into a map.
  Map<String, dynamic> toMap() {
    return {
      'field': field,
      'direction': direction,
    };
  }
}

/// Generic pagination, search, sorting, and custom filter model.
class Filters {
  /// Map key used for [limit].
  static const kLimit = 'limit';

  /// Map key used for [offset].
  static const kOffset = 'offset';

  /// Map key used for [searchString].
  static const kSearch = 'search';

  /// Map key used for [orderBy].
  static const kOrderBy = 'orderBy';

  /// Map key used for [orderDir].
  static const kOrderDir = 'orderDir';

  /// Map key used for [orderFields].
  static const kOrderFields = 'orderFields';

  /// Reserved key accepted by [Filters.fromMap] for nested custom filters.
  static const kAdditionalFilters = 'additionalFilters';

  /// Map key used for [searchInFields].
  static const kSearchInFields = 'searchInFields';

  /// Keys reserved by the core filtering model.
  static const Set<String> reservedKeys = <String>{
    kLimit,
    kOffset,
    kSearch,
    kOrderBy,
    kOrderDir,
    kOrderFields,
    kAdditionalFilters,
    kSearchInFields,
  };

  /// Maximum number of items to request.
  int? limit = 12;

  /// Starting offset for pagination.
  int? offset = 0;

  /// Free-text query.
  String? searchString;

  /// Field name used for sorting.
  String? orderBy;

  /// Sort direction, usually `asc` or `desc`.
  String? orderDir = 'desc';

  /// Ordered list of sorting criteria.
  List<FilterOrderField> orderFields = <FilterOrderField>[];

  /// Fields that should receive [searchString].
  List<FilterSearchField> searchInFields = <FilterSearchField>[];

  /// Arbitrary custom filters that should travel with the query model.
  ///
  /// These values are flattened into the top-level map returned by [toMap] so
  /// they can be used directly as query parameters.
  Map<String, dynamic> additionalFilters = <String, dynamic>{};

  /// Whether sorting is currently configured.
  bool get isOrder => orderFields.isNotEmpty || orderBy != null;

  /// Whether a non-empty free-text search is currently configured.
  bool get isSearch => searchString != null && searchString?.trim() != '';

  /// Whether [limit] is enabled.
  bool get isLimit => limit != null;

  /// Whether [offset] is enabled.
  bool get isOffset => offset != null;

  /// Whether custom additional filters are present.
  bool get hasAdditionalFilters => additionalFilters.isNotEmpty;

  /// Creates a filter model and normalizes the current sorting state.
  Filters({
    this.limit = 12,
    this.offset = 0,
    this.searchString,
    this.orderBy,
    this.orderDir,
    List<FilterOrderField>? orderFields,
    Map<String, dynamic>? additionalFilters,
  })  : orderFields = orderFields != null
            ? List<FilterOrderField>.from(orderFields)
            : <FilterOrderField>[],
        additionalFilters = additionalFilters != null
            ? Map<String, dynamic>.from(additionalFilters)
            : <String, dynamic>{} {
    syncOrderState();
  }

  /// Creates a [Filters] object from a serialized map.
  Filters.fromMap(Map<String, dynamic> map) {
    fillFromMap(map);
  }

  /// Copies all values from another [Filters] instance.
  void fillFromFilters(Filters filters) {
    limit = filters.limit;
    offset = filters.offset;
    searchString = filters.searchString;
    orderBy = filters.orderBy;
    orderDir = filters.orderDir;
    orderFields = List<FilterOrderField>.from(filters.orderFields);
    searchInFields = List<FilterSearchField>.from(filters.searchInFields);
    additionalFilters = Map<String, dynamic>.from(filters.additionalFilters);
    syncOrderState();
  }

  /// Replaces the sorting criteria list.
  void setOrderFields(List<FilterOrderField> fields) {
    orderFields = List<FilterOrderField>.from(
      fields.where((field) => field.field.trim().isNotEmpty),
    );
    syncOrderState();
  }

  /// Adds [key] to [map] only when [value] is not `null`.
  void addToMapIfNotNull(Map<String, dynamic> map, String key, dynamic value) {
    if (value != null) {
      map[key] = value;
    }
  }

  /// Configures a single sorting criterion.
  void setSingleOrder(
    String? field, {
    String direction = 'desc',
  }) {
    if (field == null || field.trim().isEmpty) {
      orderFields = <FilterOrderField>[];
      orderBy = null;
      orderDir = null;
      return;
    }

    orderFields = <FilterOrderField>[
      FilterOrderField(field: field, direction: direction),
    ];
    syncOrderState();
  }

  /// Adds a search target field.
  void addSearchInField(FilterSearchField filterSearchField) {
    searchInFields.add(filterSearchField);
  }

  /// Sets or replaces a custom filter entry.
  void setAdditionalFilter(String key, dynamic value) {
    additionalFilters[key] = value;
  }

  /// Removes a custom filter entry.
  void removeAdditionalFilter(String key) {
    additionalFilters.remove(key);
  }

  /// Converts this object into a serializable map.
  ///
  /// Reserved pagination and sorting fields are combined with
  /// [additionalFilters]. Custom filters are flattened into the top-level map
  /// to make query-string serialization straightforward.
  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{};

    if (limit != null) {
      map[kLimit] = limit;
    }
    if (offset != null) {
      map[kOffset] = offset;
    }
    if (searchString != null) {
      map[kSearch] = searchString;
    }
    if (orderBy != null) {
      map[kOrderBy] = orderBy;
    }
    if (orderDir != null) {
      map[kOrderDir] = orderDir;
    }
    if (orderFields.isNotEmpty) {
      map[kOrderFields] =
          jsonEncode(orderFields.map((field) => field.toMap()).toList());
    }
    if (searchInFields.isNotEmpty) {
      map[kSearchInFields] =
          jsonEncode(searchInFields.map((e) => e.toMap()).toList());
    }
    if (additionalFilters.isNotEmpty) {
      map.addAll(additionalFilters);
    }

    return map;
  }

  /// Converts this object into a string-only query-parameter map.
  Map<String, String> getParams() {
    return toMap().map((key, value) => MapEntry(key, value.toString()));
  }

  /// Fills this instance from a serialized map.
  ///
  /// Unknown keys are collected into [additionalFilters]. This allows the
  /// object to remain generic while still supporting domain-specific query
  /// parameters externally.
  void fillFromMap(Map<String, dynamic> map) {
    additionalFilters = parseAdditionalFilters(map[kAdditionalFilters]);

    if (map.containsKey(kLimit) && map[kLimit] != null) {
      limit = toNullableInt(map[kLimit]);
    }
    if (map.containsKey(kOffset) && map[kOffset] != null) {
      offset = toNullableInt(map[kOffset]);
    }
    if (map.containsKey(kSearch) && map[kSearch] != null) {
      searchString = toNullableString(map[kSearch]);
    }
    if (map.containsKey(kOrderBy) && map[kOrderBy] != null) {
      orderBy = toNullableString(map[kOrderBy]);
    }
    if (map.containsKey(kOrderDir) && map[kOrderDir] != null) {
      orderDir = toNullableString(map[kOrderDir]);
    }
    orderFields = parseOrderFields(map[kOrderFields]);
    if (map.containsKey(kSearchInFields) && map[kSearchInFields] != null) {
      final rawValue = map[kSearchInFields];
      if (rawValue is String && rawValue.trim().isNotEmpty) {
        final decoded = jsonDecode(rawValue);
        if (decoded is List) {
          searchInFields = decoded
              .whereType<Map>()
              .map((e) =>
                  FilterSearchField.fromMap(Map<String, dynamic>.from(e)))
              .toList();
        }
      } else if (rawValue is List) {
        searchInFields = rawValue
            .whereType<Map>()
            .map((e) => FilterSearchField.fromMap(Map<String, dynamic>.from(e)))
            .toList();
      }
    }

    for (final entry in map.entries) {
      if (reservedKeys.contains(entry.key) || entry.value == null) {
        continue;
      }
      additionalFilters[entry.key] = entry.value;
    }

    syncOrderState();
  }

  /// Parses sorting criteria from a JSON string or a list of maps.
  List<FilterOrderField> parseOrderFields(dynamic rawValue) {
    if (rawValue is String && rawValue.trim().isNotEmpty) {
      final decoded = jsonDecode(rawValue);
      if (decoded is List) {
        return decoded
            .whereType<Map>()
            .map((e) => FilterOrderField.fromMap(Map<String, dynamic>.from(e)))
            .where((field) => field.field.trim().isNotEmpty)
            .toList();
      }
    }

    if (rawValue is List) {
      return rawValue
          .whereType<Map>()
          .map((e) => FilterOrderField.fromMap(Map<String, dynamic>.from(e)))
          .where((field) => field.field.trim().isNotEmpty)
          .toList();
    }

    return <FilterOrderField>[];
  }

  /// Parses custom filter values from a map or a JSON-encoded map.
  Map<String, dynamic> parseAdditionalFilters(dynamic rawValue) {
    if (rawValue is Map) {
      return Map<String, dynamic>.from(rawValue);
    }
    if (rawValue is String && rawValue.trim().isNotEmpty) {
      final decoded = jsonDecode(rawValue);
      if (decoded is Map) {
        return Map<String, dynamic>.from(decoded);
      }
    }
    return <String, dynamic>{};
  }

  /// Converts [value] into an `int` when possible.
  int? toNullableInt(dynamic value) {
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

  /// Reads a boolean value from [map] using [key] when present.
  bool? toNullableBool(Map<String, dynamic> map, String key) {
    if (map.containsKey(key) && map[key] != null) {
      return map[key].toString().toLowerCase() == 'true';
    }
    return null;
  }

  /// Returns [value] when it is already a `String`.
  String? toNullableString(dynamic value) {
    if (value == null) {
      return null;
    }
    if (value is String) {
      return value;
    }
    return null;
  }

  /// Keeps [orderFields], [orderBy], and [orderDir] synchronized.
  void syncOrderState() {
    if (orderFields.isEmpty) {
      if (orderBy != null && orderBy!.trim().isNotEmpty) {
        orderFields = <FilterOrderField>[
          FilterOrderField(
            field: orderBy!,
            direction: orderDir ?? 'desc',
          ),
        ];
      }
      return;
    }

    final primaryOrder = orderFields.first;
    orderBy = primaryOrder.field;
    orderDir = primaryOrder.direction;
  }
}
