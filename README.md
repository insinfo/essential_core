# essential_core

[![Dart CI](https://github.com/insinfo/essential_core/actions/workflows/dart_ci.yml/badge.svg?branch=main)](https://github.com/insinfo/essential_core/actions/workflows/dart_ci.yml)

`essential_core` is a small, framework-agnostic Dart package with reusable
models, filters, serialization contracts, string/set extensions, and utility
helpers that can be shared across backend, frontend, and other packages.

## Features

- `SerializeBase` for simple map-based serialization contracts.
- `DataFrame<T>` for paginated or generic list payloads.
- `Filter`, `FilterSearchField`, and `Filters` for query composition.
- String and set extensions for common text and collection operations.
- Utility helpers for parsing, validation, masking, and accent removal.

## Installation

Add the package to your project:

```yaml
dependencies:
  essential_core: ^1.0.0
```

Then install dependencies:

```bash
dart pub get
```

## Usage

Import the package entrypoint:

```dart
import 'package:essential_core/essential_core.dart';
```

Create and serialize filters:

```dart
final filters = Filters(
  limit: 20,
  offset: 0,
  searchString: 'john',
  orderBy: 'name',
  orderDir: 'asc',
  additionalFilters: {
    'status': 'active',
    'teamId': 10,
  },
);

filters.addSearchInField(
  FilterSearchField(label: 'Name', field: 'name', active: true),
);

final queryParams = filters.getParams();
```

Work with paginated payloads:

```dart
class User implements SerializeBase {
  final int id;
  final String name;

  User({required this.id, required this.name});

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'] as int,
      name: map['name'] as String,
    );
  }

  @override
  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
      };
}

final users = DataFrame<User>.fromMapWithFactory(
  {
    'totalRecords': 2,
    'items': [
      {'id': 1, 'name': 'Ana'},
      {'id': 2, 'name': 'Bruno'},
    ],
  },
  User.fromMap,
);

final json = users.toJson();
```

Use the exported helpers:

```dart
final normalized = 'Informação Útil'.withoutAccents;
final contains = 'Essential Core'.containsIgnoreCase('core');
final masked = EssentialCoreUtils.hidePartsOfString('1234567890');
final validCpf = CoreUtils.validarCPF('529.982.247-25');
```

## Public API

- `DataFrame<T>`: list wrapper with serialization and conversion helpers.
- `SerializeBase`: contract used by serializable domain models.
- `Filter`: generic key/operator/value filter entry.
- `FilterSearchField`: search-field descriptor for UI and APIs.
- `Filters`: query object with pagination, sort, search, and custom filters.
- `StringExtensions` and `DiacriticsAwareString`: text normalization helpers.
- `SetExtension`: set replacement helpers.
- `CoreUtils` and `EssentialCoreUtils`: parsing, validation, masking, and text helpers.

## Quality Checks

Run the same checks used in CI locally:

```bash
dart format --output=none --set-exit-if-changed .
dart analyze
dart test
dart pub publish --dry-run
```

## Continuous Integration

The repository includes a GitHub Actions workflow at
`.github/workflows/dart_ci.yml` that runs on pushes to `main` and `master`, and
on pull requests. The workflow executes:

- `dart pub get`
- `dart format --output=none --set-exit-if-changed .`
- `dart analyze`
- `dart test`

## Publishing

Before publishing a new version:

1. Update `version` in `pubspec.yaml`.
2. Add the release notes to `CHANGELOG.md`.
3. Validate with `dart pub publish --dry-run`.
4. Publish with `dart pub publish`.
