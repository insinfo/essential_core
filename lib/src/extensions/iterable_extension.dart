/// Convenience helpers for replacing values in a [Set].
///
/// These methods are small wrappers around `contains`, `remove`, and `add`.
/// They are useful when a set stores immutable value objects and callers want
/// to replace a matching instance with a new one.
extension SetExtension<E> on Set<E> {
  /// Replaces [oldItem] with [newItem] when [oldItem] exists in this set.
  ///
  /// If [oldItem] is absent, the set is left unchanged.
  void replace(E oldItem, E newItem) {
    if (contains(oldItem)) {
      remove(oldItem);
      add(newItem);
    }
  }

  /// Removes [toRemove] when present and always inserts [newItem].
  ///
  /// This is useful for "upsert" style operations where the new value should be
  /// present even if the old value was not found.
  void removeAndAdd(E toRemove, E newItem) {
    if (contains(toRemove)) {
      remove(toRemove);
    }
    add(newItem);
  }
}
