//C:\MyDartProjects\essential_core\lib\src\models\filter.dart

/// Represents a single generic filter entry for list, search, or query APIs.
class Filter {
  /// Filter key or field name.
  String key;

  /// Filter value.
  ///
  /// This is intentionally flexible to support strings, numbers, booleans, and
  /// any other serializable query value.
  Object? value;

  /// Comparison operator such as `=`, `!=`, `like`, or `ilike`.
  String operator;

  Filter({required this.key, this.operator = '=', this.value});

  /// Creates a [Filter] instance from a map representation.
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
