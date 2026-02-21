## 0.0.1

- Added `AppBootstrapConfig` and `bootstrapApp(...)` for one-entry startup initialization.
- Replaced placeholder package API with a real export barrel in `lib/common_package.dart`.
- Added `app_bootstrap` Mason brick (no flavors) with post-gen pubspec/mason patching.
- Added docs for bootstrap usage and linked feature generation flow.
- Updated analysis configuration to exclude Mason template placeholder sources.
- Replaced placeholder tests with bootstrap and package export smoke coverage.
