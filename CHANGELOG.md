## 1.3.0

- Updated `EssentialCoreUtils.validarCnpj` to support the Receita Federal alphanumeric CNPJ check-digit rules while preserving numeric CNPJ validation.
- Added comprehensive CNPJ validation coverage for legacy numeric values, alphanumeric values, masks, spaces, lowercase normalization, invalid check digits, and malformed inputs.
- Added a CNPJ validator benchmark and optimized validation to avoid regex/substrings in the hot path.
- Fixed CPF validation so repeated zeroes are rejected like every other repeated digit sequence.
- Added strict CNPJ validation mode, a raw input length guard, and faster static regular expressions for accent removal and e-mail validation.
- Added an accent removal benchmark.
- Added Portuguese-aware title case conversion with connector words, acronyms, punctuation, hyphen, and apostrophe handling.
- Added real service-name collection tests for Portuguese title case and expanded acronym/separator handling.
- Added custom lowercase word and acronym overrides to Portuguese title case conversion.
- Expanded Dartdoc and README documentation across public models, extensions, and utility helpers.
- Added framework-agnostic interactive text-mask logic with CPF, CNPJ, generic mask, cursor, and raw-value support.
- Improved interactive text masks with escaped literals, compiled patterns, normalized selection bounds, explicit numeric/alphanumeric CNPJ factories, and edit-aware cursor handling to avoid backspace traps around mask literals.

## 1.2.0

- BREAKING CHANGE: Fixed `Filters` sorting behavior so `orderBy`/`orderDir` and `orderFields` no longer auto-synchronize, keeping simple datatable sorting independent from advanced multi-field flows.


## 1.1.0

- BREAKING CHANGE: Removed `CoreUtils`; its utility methods now live in `EssentialCoreUtils`.
- Added `error` and `templateOutletContext` to `DataFrame` for template-driven UI rendering scenarios.
- Exposed reusable `Filters` helpers and reserved keys to support custom parsing and serialization flows.


## 1.0.0

- Initial release of the shared foundational package.
