# app_bootstrap

Generates a no-flavors Flutter app bootstrap using `common_package`.

## What it creates

- `lib/main.dart`
- `lib/app.dart`
- `lib/core/app_config.dart`
- `lib/core/di/injection.dart`
- `lib/core/routes/app_router.dart`
- `lib/generated/app_routes.g.dart` (safe placeholder)
- `assets/translations/en.json`
- `assets/translations/ar.json`
- `lib/features/home/view/home_screen.dart`

The hook also patches:

- `pubspec.yaml` dependencies/dev_dependencies/assets
- `mason.yaml` with `feature` brick reference
