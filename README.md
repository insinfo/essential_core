# essential_core

[![Dart CI](https://github.com/insinfo/essential_core/actions/workflows/dart_ci.yml/badge.svg?branch=main)](https://github.com/insinfo/essential_core/actions/workflows/dart_ci.yml)

`essential_core` is a small, framework-agnostic Dart package with reusable
models, filters, serialization contracts, string/set extensions, and utility
helpers that can be shared across backend, frontend, and other packages.

## Features

- `SerializeBase` for simple map-based serialization contracts.
- `DataFrame<T>` for paginated or generic list payloads.
- `Filter`, `FilterSearchField`, and `Filters` for query composition.
- String and set extensions for common text, Portuguese title case, and collection operations.
- Utility helpers for parsing, CPF/CNPJ validation, masking, e-mail validation, and accent removal.

## Installation

Add the package to your project:

```yaml
dependencies:
  essential_core: ^1.4.0
```

Then install dependencies:

```bash
dart pub get
```

This package targets Dart 3.6 or newer within the 3.x line.

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

Use simple sorting for datatable-style flows:

```dart
final filters = Filters(
  orderBy: 'createdAt',
  orderDir: 'desc',
);
```

Use `orderFields` only for advanced multi-field sorting flows:

```dart
final filters = Filters(
  orderFields: const [
    FilterOrderField(field: 'priority', direction: 'desc'),
    FilterOrderField(field: 'createdAt', direction: 'asc'),
  ],
);
```

`orderBy`/`orderDir` and `orderFields` are intentionally independent and are no
longer synchronized automatically.

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
final validCpf = EssentialCoreUtils.validarCPF('529.982.247-25');
```

Sanitize, format, generate, and validate CPF/CNPJ values:

```dart
final cpf = EssentialCoreUtils.gerarCpf();
final formattedCpf = EssentialCoreUtils.formatarCpf(cpf);
final rawCpf = EssentialCoreUtils.sanitizarCpf(formattedCpf);

final cnpj = EssentialCoreUtils.gerarCnpj(alfanumerico: true);
final formattedCnpj = EssentialCoreUtils.formatarCnpj(cnpj);
final rawCnpj = EssentialCoreUtils.sanitizarCnpj(formattedCnpj);
```

Mask documents for federal-style public display:

```dart
EssentialCoreUtils.mascararCpfGovernoFederal('123.456.789-10');
// ***.456.789-**

EssentialCoreUtils.mascararCnpjGovernoFederal('54.550.752/0001-55');
// 54.550.752/0001-55

EssentialCoreUtils.mascararDocumentoGovernoFederal('12345678910');
// ***.456.789-**
```

Use generic platform-agnostic helpers:

```dart
final options = EssentialCoreUtils.mergeDefaults(
  {'limit': 20},
  {'limit': 12, 'offset': 0},
);

final enabled = EssentialCoreUtils.parseBoolLoose('sim');
final safeHtml = EssentialCoreUtils.escapeHtml('<b>Ana & Bia</b>');
final email = EssentialCoreUtils.normalizeEmail('Some.One+Tag@GoogleMail.com');
```

Validate legacy numeric and alphanumeric CNPJ values:

```dart
final validNumericCnpj =
    EssentialCoreUtils.validarCnpj('54.550.752/0001-55');

final validAlphanumericCnpj =
    EssentialCoreUtils.validarCnpj('12ABC34501DE35');

final strictCnpj =
    EssentialCoreUtils.validarCnpj('12.ABC.345/01DE-35', strict: true);
```

Convert Portuguese text to title case while preserving connector words and
known acronyms:

```dart
'PARCELAMENTO DE IPTU'.toPortugueseTitleCase();
// Parcelamento de IPTU

"SANTA BÁRBARA D'OESTE".toPortugueseTitleCase();
// Santa Bárbara D'Oeste

'relatório conforme norma abc'.toPortugueseTitleCase(
  lowercaseWords: const ['conforme'],
  acronyms: const {'abc': 'ABC'},
);
// Relatório conforme Norma ABC
```

Use framework-agnostic interactive input masks:

```dart
final cpfMask = InteractiveTextMask.cpf();

final result = cpfMask.applyEdit(
  oldValue: MaskedTextValue.collapsed('123'),
  newValue: MaskedTextValue(
    text: '1234',
    selectionStart: 4,
    selectionEnd: 4,
  ),
);

result.text; // 123.4
result.selectionStart; // 5
result.rawText; // 1234
```

The same formatter can be adapted to browser inputs, AngularDart directives,
Flutter text fields, terminal prompts, or server-side normalization because it
does not import any UI or platform library.

Use `applyEdit(oldValue: ..., newValue: ...)` in UI adapters that can keep the
previous value; it handles insertion/deletion around literals more accurately.
Use `apply(value)` or `format(text)` for simpler normalization flows.

## Public API

- `DataFrame<T>`: list wrapper with serialization and conversion helpers.
- `SerializeBase`: contract used by serializable domain models.
- `Filter`: generic key/operator/value filter entry.
- `FilterSearchField`: search-field descriptor for UI and APIs.
- `Filters`: query object with pagination, simple sorting, advanced sorting, search, and custom filters.
- `StringExtensions`, `DiacriticsAwareString`, and `PtTitleCase`: text normalization and Portuguese title case helpers.
- `SetExtension`: set replacement helpers.
- `EssentialCoreUtils`: parsing, validation, masking, and text helpers.
- `InteractiveTextMask`, `MaskedTextValue`, `MaskedTextResult`, and `MaskToken`: framework-agnostic interactive text-mask helpers.

## Benchmarks

Microbenchmarks for hot-path helpers live under `benchmark/`:

```bash
dart run benchmark/cnpj_benchmark.dart
dart run benchmark/accents_benchmark.dart
```

Use the numbers as local comparisons before and after implementation changes;
absolute timings vary by machine and runtime conditions.

## Quality Checks

Run the same checks used in CI locally:

```bash
dart analyze
dart test
dart pub publish --dry-run
```

## Continuous Integration

The repository includes a GitHub Actions workflow at
`.github/workflows/dart_ci.yml` that runs on pushes to `main` and `master`, and
on pull requests. The workflow executes:

- `dart pub get`
- `dart analyze`
- `dart test`

## Publishing

Before publishing a new version:

1. Update `version` in `pubspec.yaml`.
2. Add the release notes to `CHANGELOG.md`.
3. Validate with `dart pub publish --dry-run`.
4. Publish with `dart pub publish`.
