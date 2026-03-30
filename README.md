# essential_core

`essential_core` contains small, framework-agnostic building blocks that can be
shared across Dart backends, frontends, and reusable packages.

## Goals

- Provide foundational contracts and DTOs with no UI dependency.


## Included types

- `SerializeBase`: serialization contract for map-based DTOs.
- `DataFrame<T>`: generic paged/list response wrapper.
- `Filter`: simple key/operator/value filter entry.
- `FilterSearchField`: describes which field should receive a text search.
- `Filters`: generic pagination, search, sorting, and custom filter model.


## Example

```dart
import 'package:essential_core/essential_core.dart';

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

final queryParams = filters.getParams();
```
