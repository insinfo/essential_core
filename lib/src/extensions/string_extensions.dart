/// String formatting and comparison helpers used across the package.
extension StringExtensions on String {
  /// Returns this string with the first character uppercased and the
  /// remaining characters lowercased.
  String toCapitalized() =>
      length > 0 ? '${this[0].toUpperCase()}${substring(1).toLowerCase()}' : '';

  /// Normalizes repeated spaces and capitalizes each word in this string.
  String toTitleCase() => length > 0
      ? replaceAll(RegExp(' +'), ' ')
          .split(' ')
          .map((str) => str.toCapitalized())
          .join(' ')
      : '';

  /// Returns whether this string contains [secondString] ignoring case.
  bool containsIgnoreCase(String secondString) =>
      toLowerCase().contains(secondString.toLowerCase());

  /// Returns whether this string contains [secondString] ignoring accents and
  /// case.
  bool containsIgnoreAccents(String secondString) => withoutAccents
      .toLowerCase()
      .contains(secondString.withoutAccents.toLowerCase());

  /// Compares [a] and [b] ignoring case, treating two `null` values as equal.
  ///
  /// The extension receiver is not used and is kept for backward
  /// compatibility with the existing API.
  bool equalsIgnoreCase(String? a, String? b) =>
      (a == null && b == null) ||
      (a != null && b != null && a.toLowerCase() == b.toLowerCase());
}

/// Accent-insensitive normalization helpers for [String].
extension DiacriticsAwareString on String {
  static const diacritics =
      'ÀÁÂÃÄÅàáâãäåÒÓÔÕÕÖØòóôõöøÈÉÊËĚèéêëěðČÇçčÐĎďÌÍÎÏìíîïĽľÙÚÛÜŮùúûüůŇÑñňŘřŠšŤťŸÝÿýŽž';
  static const nonDiacritics =
      'AAAAAAaaaaaaOOOOOOOooooooEEEEEeeeeeeCCccDDdIIIIiiiiLlUUUUUuuuuuNNnnRrSsTtYYyyZz';

  /// Returns this string with known diacritic characters replaced by their
  /// non-accented equivalents.
  String get withoutAccents => splitMapJoin('',
      onNonMatch: (char) => char.isNotEmpty && diacritics.contains(char)
          ? nonDiacritics[diacritics.indexOf(char)]
          : char);
}
