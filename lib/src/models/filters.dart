import 'dart:convert';

import 'filter_search_field.dart';
import '../utils/essential_core_utils.dart';

/// One sorting criterion used by [Filters].
///
/// Use this for multi-field sorting flows where `orderBy`/`orderDir` are not
/// expressive enough.
class FilterOrderField {
  /// Field identifier to sort by.
  ///
  /// Empty or whitespace-only values are ignored by [Filters.setOrderFields].
  final String field;

  /// Sort direction, usually `asc` or `desc`.
  final String direction;

  /// Creates a sorting criterion.
  ///
  /// [direction] defaults to `desc`.
  const FilterOrderField({
    required this.field,
    this.direction = 'desc',
  });

  /// Creates an instance from a serialized map.
  ///
  /// Values are converted with `toString()` when present. Missing [direction]
  /// defaults to `desc`.
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
///
/// [Filters] is designed as a transport object for list APIs. It can be built
/// in UI code, serialized into query parameters with [getParams], reconstructed
/// from a map with [Filters.fromMap], and extended with domain-specific
/// [additionalFilters].
///
/// Simple sorting (`orderBy`/`orderDir`) and advanced sorting ([orderFields])
/// are intentionally independent. Use one or both according to the endpoint
/// contract; setting one does not mutate the other.
///
/// Example:
///
/// ```dart
/// final filters = Filters(
///   limit: 20,
///   offset: 0,
///   searchString: 'ana',
///   orderBy: 'name',
///   orderDir: 'asc',
///   additionalFilters: {'active': true},
/// );
///
/// final params = filters.getParams();
/// ```
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
  ///
  /// When [fillFromMap] receives unknown keys, they are copied to
  /// [additionalFilters]. Keys in this set are handled by the core model and
  /// are not treated as custom filters.
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
  ///
  /// Set to `null` to omit the limit from [toMap].
  int? limit = 12;

  /// Starting offset for pagination.
  ///
  /// Set to `null` to omit the offset from [toMap].
  int? offset = 0;

  /// Free-text query.
  ///
  /// Use [searchInFields] to describe which fields should receive this value.
  String? searchString;

  /// Field name used for simple single-field sorting.
  String? orderBy;

  /// Sort direction, usually `asc` or `desc`.
  String? orderDir = 'desc';

  /// Ordered list of sorting criteria.
  ///
  /// Values are serialized as a JSON string by [toMap] to make HTTP query
  /// parameter transport straightforward.
  List<FilterOrderField> orderFields = <FilterOrderField>[];

  /// Fields that should receive [searchString].
  ///
  /// Values are serialized as a JSON string by [toMap].
  List<FilterSearchField> searchInFields = <FilterSearchField>[];

  /// Arbitrary custom filters that should travel with the query model.
  ///
  /// These values are flattened into the top-level map returned by [toMap] so
  /// they can be used directly as query parameters.
  Map<String, dynamic> additionalFilters = <String, dynamic>{};

  /// Whether sorting is currently configured.
  bool get isOrder => orderBy != null;

  /// Whether a non-empty free-text search is currently configured.
  bool get isSearch => searchString != null && searchString?.trim() != '';

  /// Whether [limit] is enabled.
  bool get isLimit => limit != null;

  /// Whether [offset] is enabled.
  bool get isOffset => offset != null;

  /// Whether custom additional filters are present.
  bool get hasAdditionalFilters => additionalFilters.isNotEmpty;

  /// Creates a filter model.
  ///
  /// List and map arguments are defensively copied so later changes to the
  /// constructor arguments do not mutate this object.
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
            : <String, dynamic>{};

  /// Creates a [Filters] object from a serialized map.
  ///
  /// The map may contain normal Dart values or JSON-encoded strings for
  /// [orderFields], [searchInFields], and [additionalFilters].
  Filters.fromMap(Map<String, dynamic> map) {
    fillFromMap(map);
  }

  /// Copies all values from another [Filters] instance.
  ///
  /// Mutable collections are copied, not shared.
  void fillFromFilters(Filters filters) {
    limit = filters.limit;
    offset = filters.offset;
    searchString = filters.searchString;
    orderBy = filters.orderBy;
    orderDir = filters.orderDir;
    orderFields = List<FilterOrderField>.from(filters.orderFields);
    searchInFields = List<FilterSearchField>.from(filters.searchInFields);
    additionalFilters = Map<String, dynamic>.from(filters.additionalFilters);
  }

  /// Replaces the sorting criteria list.
  ///
  /// Entries with blank [FilterOrderField.field] values are discarded.
  void setOrderFields(List<FilterOrderField> fields) {
    orderFields = List<FilterOrderField>.from(
      fields.where((field) => field.field.trim().isNotEmpty),
    );
  }

  /// Adds [key] to [map] only when [value] is not `null`.
  ///
  /// This helper is public for compatibility with older consumers.
  void addToMapIfNotNull(Map<String, dynamic> map, String key, dynamic value) {
    if (value != null) {
      map[key] = value;
    }
  }

  /// Adds a search target field to [searchInFields].
  void addSearchInField(FilterSearchField filterSearchField) {
    searchInFields.add(filterSearchField);
  }

  /// Sets or replaces a custom filter entry.
  ///
  /// Custom filters are flattened into [toMap] unless their key collides with a
  /// reserved key.
  void setAdditionalFilter(String key, dynamic value) {
    additionalFilters[key] = value;
  }

  /// Removes a custom filter entry when present.
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
  ///
  /// This is useful for HTTP clients that require `Map<String, String>` query
  /// parameters. Complex values are already JSON-encoded by [toMap].
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
  }

  /// Parses sorting criteria from a JSON string or a list of maps.
  ///
  /// Invalid, empty, or unsupported inputs return an empty list.
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
  ///
  /// Invalid, empty, or unsupported inputs return an empty map.
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
  ///
  /// Only `int` values and strings accepted by [int.tryParse] are converted.
  int? toNullableInt(dynamic value) {
    return EssentialCoreUtils.toNullableInt(value);
  }

  /// Reads a boolean value from [map] using [key] when present.
  ///
  /// The string `true`, ignoring case, maps to `true`; any other present value
  /// maps to `false`.
  bool? toNullableBool(Map<String, dynamic> map, String key) {
    return EssentialCoreUtils.toNullableBool(map, key);
  }

  /// Returns [value] when it is already a `String`.
  String? toNullableString(dynamic value) {
    return EssentialCoreUtils.toNullableString(value);
  }
}
