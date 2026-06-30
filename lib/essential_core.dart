/// Shared foundational models, extensions, and utility helpers for Dart
/// packages and applications.
///
/// Import this library when consumers need the public API exposed by
/// `essential_core`, including:
///
/// - serialization contracts such as [SerializeBase];
/// - list and pagination payloads through [DataFrame];
/// - query helpers such as [Filter], [FilterSearchField], and [Filters];
/// - string and set extensions;
/// - validation, parsing, masking, and normalization helpers from
///   [EssentialCoreUtils].
/// - framework-agnostic text-mask helpers such as [InteractiveTextMask].
library;

export 'src/models/data_frame.dart';
export 'src/models/filter.dart';
export 'src/models/filter_search_field.dart';
export 'src/models/filters.dart';
export 'src/models/serialize_base.dart';

export 'src/extensions/iterable_extension.dart';
export 'src/extensions/string_extensions.dart';

export 'src/utils/essential_core_utils.dart';
export 'src/utils/interactive_text_mask.dart';
