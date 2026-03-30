extension SetExtension<E> on Set<E> {
  // Replace an item in the Set with a new one
  void replace(E oldItem, E newItem) {
    if (contains(oldItem)) {
      remove(oldItem);
      add(newItem);
    }
  }

  void removeAndAdd(E toRemove, E newItem) {
    if (contains(toRemove)) {
      remove(toRemove);
    }
    add(newItem);
  }
}
