/// Represents a single generic filter entry for list, search, or query APIs.
///
/// A [Filter] is intentionally small: it carries a [key], an [operator], and a
/// [value]. Higher-level code can translate these fields into SQL predicates,
/// HTTP query parameters, GraphQL variables, or any other query format.
///
/// Example:
///
/// ```dart
/// final activeFilter = Filter(
///   key: 'status',
///   operator: '=',
///   value: 'active',
/// );
/// ```
class Filter {
  /// Filter key or field name.
  ///
  /// This usually matches a backend field, column, or query parameter.
  String key;

  /// Filter value.
  ///
  /// This is intentionally flexible to support strings, numbers, booleans, and
  /// any other serializable query value.
  Object? value;

  /// Comparison operator such as `=`, `!=`, `like`, or `ilike`.
  ///
  /// The package does not interpret the operator; consumers decide how it maps
  /// to their data source.
  String operator;

  /// Creates a filter entry.
  ///
  /// [operator] defaults to `=`.
  Filter({required this.key, this.operator = '=', this.value});

  /// Creates a [Filter] instance from a map representation.
  ///
  /// Missing `operator` values default to `=`.
  factory Filter.fromMap(Map<String, dynamic> map) {
    return Filter(
      key: map['key'] as String,
      value: map['value'],
      operator: map['operator'] as String? ?? '=',
    );
  }

  /// Converts the filter into a serializable map.
  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'key': key,
      'value': value,
      'operator': operator,
    };
  }
}
