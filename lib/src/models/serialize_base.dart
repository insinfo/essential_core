/// Contract for domain objects that can serialize themselves into a map.
///
/// Implement this interface when a model should participate in generic
/// serialization helpers such as `DataFrame.itemsAsMap` and
/// `DataFrame.toJson`.
///
/// Implementations should return only values that can be encoded by
/// `jsonEncode`, or values handled by the caller's custom encoder.
///
/// Example:
///
/// ```dart
/// class User implements SerializeBase {
///   User({required this.id, required this.name});
///
///   final int id;
///   final String name;
///
///   @override
///   Map<String, dynamic> toMap() => {
///         'id': id,
///         'name': name,
///       };
/// }
/// ```
abstract class SerializeBase {
  /// Converts the current object into a serializable map representation.
  ///
  /// The returned map is expected to use stable field names that match the
  /// model's API or wire format.
  Map<String, dynamic> toMap();
}
