// ignore_for_file: unintended_html_in_doc_comment

import 'dart:collection';
import 'dart:convert';

import 'serialize_base.dart';

/// Generic list or paged response wrapper shared by backend and frontend code.
class DataFrame<T> extends ListBase<T> {
  /// List of items contained in this frame.
  List<T> items = [];

  /// Total amount of records available in the original data source.
  int totalRecords = 0;

  /// Optional error payload associated with the current frame.
  dynamic error = '';

  /// Template context exposing this frame as the implicit value for UI
  /// template outlet bindings.
  late Map<String, dynamic> templateOutletContext;

  /// Creates a frame with [items], [totalRecords], and an optional [error]
  /// payload.
  DataFrame(
      {required this.items, required this.totalRecords, this.error = ''}) {
    templateOutletContext = {'\$implicit': this};
  }

  /// Creates an empty [DataFrame].
  factory DataFrame.newClear() => DataFrame<T>(items: [], totalRecords: 0);

  /// Builds a typed [DataFrame] from a map, optionally using a factory
  /// function to materialize each item.
  factory DataFrame.fromMapWithFactory(
    Map<String, dynamic> map,
    T Function(Map<String, dynamic>)? builder,
  ) {
    final data = <T>[];
    final isSerializeBase = <T>[] is List<SerializeBase>;

    if (isSerializeBase && builder == null) {
      throw Exception(
        'If T implements SerializeBase, builder cannot be null.',
      );
    }

    if (map['items'] case final List maps) {
      for (final item in maps) {
        final value = builder != null
            ? builder(Map<String, dynamic>.from(item as Map))
            : item as T;
        data.add(value);
      }
    }

    return DataFrame<T>(
      items: data,
      totalRecords: map['totalRecords'] as int? ?? 0,
    );
  }

  /// Converts the current items into a typed list using the provided factory
  /// when needed.
  List<D> toListOf<D>(D Function(Map<String, dynamic>) factory) {
    if (items.isEmpty) {
      return <D>[];
    }
    if (items.first is D) {
      return items.cast<D>().toList();
    }
    if (items.first is Map<String, dynamic>) {
      return items.map((e) => factory(e as Map<String, dynamic>)).toList();
    }
    return <D>[];
  }

  /// Converts this frame into a serializable map.
  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'totalRecords': totalRecords,
      'items': items,
    };
  }

  /// Returns [items] as a list of maps when possible.
  List<Map<String, dynamic>> get itemsAsMap {
    if (items.isEmpty) {
      return <Map<String, dynamic>>[];
    }

    final firstItem = items.first;

    if (firstItem is Map<String, dynamic> ||
        firstItem is LinkedHashMap<String, dynamic>) {
      return items.cast<Map<String, dynamic>>();
    }

    if (firstItem is SerializeBase) {
      return items.map((e) => (e as SerializeBase).toMap()).toList();
    }

    return <Map<String, dynamic>>[];
  }

  /// Serializes the frame into JSON.
  String toJson() {
    return jsonEncode(toMap(), toEncodable: _customJsonEncode);
  }

  /// Returns a debug-friendly string representation of this frame.
  @override
  String toString() {
    return 'instanceof DataFrame | ${toJson()}';
  }

  static dynamic _customJsonEncode(dynamic item) {
    if (item is DateTime) {
      return item.toIso8601String();
    }
    if (item is SerializeBase) {
      return item.toMap();
    }
    return item;
  }

  /// Removes an item and returns its original index, or `-1` if not found.
  int removeItem(T element) {
    final index = items.indexOf(element);
    items.remove(element);
    return index;
  }

  /// Returns the number of items currently stored in this frame.
  @override
  int get length => items.length;

  /// Resizes the underlying item collection to [maxLen].
  @override
  set length(int maxLen) {
    items.length = maxLen;
  }

  /// Returns the item at [index].
  @override
  T operator [](int index) => items[index];

  /// Replaces the item at [index] with [value].
  @override
  void operator []=(int index, T value) {
    items[index] = value;
  }

  /// Appends [element] to the end of the frame.
  @override
  void add(T element) {
    items.add(element);
  }

  /// Appends all values from [iterable] to the end of the frame.
  @override
  void addAll(Iterable<T> iterable) {
    items.addAll(iterable);
  }

  /// Inserts [element] into the frame at [index].
  @override
  void insert(int index, T element) {
    items.insert(index, element);
  }

  /// Removes and returns the item at [index].
  @override
  T removeAt(int index) {
    return items.removeAt(index);
  }

  /// Removes the first occurrence of [element] from the frame.
  @override
  bool remove(Object? element) {
    return items.remove(element);
  }
}
