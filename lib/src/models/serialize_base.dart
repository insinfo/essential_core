/// Contract for objects that can serialize themselves into a map.
abstract class SerializeBase {
  /// Converts the current object into a serializable map representation.
  Map<String, dynamic> toMap();
}
