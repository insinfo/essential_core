## 1.2.0

- BREAKING CHANGE: Fixed `Filters` sorting behavior so `orderBy`/`orderDir` and `orderFields` no longer auto-synchronize, keeping simple datatable sorting independent from advanced multi-field flows.


## 1.1.0

- BREAKING CHANGE: Removed `CoreUtils`; its utility methods now live in `EssentialCoreUtils`.
- Added `error` and `templateOutletContext` to `DataFrame` for template-driven UI rendering scenarios.
- Exposed reusable `Filters` helpers and reserved keys to support custom parsing and serialization flows.


## 1.0.0

- Initial release of the shared foundational package.
