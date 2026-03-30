/// Describes which field should receive a free-text search operation.
class FilterSearchField {
  /// Map key used for [label].
  static const kLabel = 'label';

  /// Map key used for [field].
  static const kField = 'field';

  /// Map key used for [active].
  static const kActive = 'active';

  /// Map key used for [operator].
  static const kOperator = 'operator';

  /// Human-readable label for UI selectors.
  String label;

  /// Data source field name that should receive the search value.
  String field;

  /// Indicates whether this field is currently active.
  bool active;

  /// Comparison operator used when applying the search.
  String operator;

  FilterSearchField({
    required this.label,
    required this.field,
    this.active = false,
    this.operator = '=',
  });

  /// Creates a [FilterSearchField] from a map.
  factory FilterSearchField.fromMap(Map<String, dynamic> map) {
    return FilterSearchField(
      label: map[kLabel] as String,
      field: map[kField] as String,
      active: map[kActive] as bool? ?? false,
      operator: map[kOperator] as String? ?? '=',
    );
  }

  /// Converts the search field into a serializable map.
  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      kLabel: label,
      kField: field,
      kActive: active,
      kOperator: operator,
    };
  }
}
