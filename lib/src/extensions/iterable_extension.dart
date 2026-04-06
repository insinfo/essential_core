/// Convenience helpers for replacing values in a [Set].
extension SetExtension<E> on Set<E> {
  /// Replaces [oldItem] with [newItem] when [oldItem] exists in this set.
  void replace(E oldItem, E newItem) {
    if (contains(oldItem)) {
      remove(oldItem);
      add(newItem);
    }
  }

  /// Removes [toRemove] when present and always inserts [newItem].
  void removeAndAdd(E toRemove, E newItem) {
    if (contains(toRemove)) {
      remove(toRemove);
    }
    add(newItem);
  }
}
