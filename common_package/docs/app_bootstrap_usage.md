# App Bootstrap Brick Usage

This guide explains how to use the `app_bootstrap` Mason brick (no flavors).

## 1. Add brick reference in your app

In your Flutter app `mason.yaml`:

```yaml
bricks:
  app_bootstrap:
    path: <path-to-common_package>/bricks/apps/app_bootstrap
```

Example:

```yaml
bricks:
  app_bootstrap:
    path: ../common_package/bricks/apps/app_bootstrap
```

Then run:

```bash
mason get
```

## 2. Generate bootstrap

Run:

```bash
mason make app_bootstrap --on-conflict overwrite
```

Prompts:

1. `app_name`
2. `org_identifier`
3. `base_url`
4. `default_locale` (`en` or `ar`)
5. `enable_notifications` (`true` or `false`)

## 3. Generated files

Main generated files:

```text
lib/main.dart
lib/app.dart
lib/core/app_config.dart
lib/core/di/injection.dart
lib/core/routes/app_router.dart
lib/generated/app_routes.g.dart
lib/features/home/view/home_screen.dart
assets/translations/en.json
assets/translations/ar.json
mason.yaml
```

## 4. Hook behavior

The post-gen hook updates:

1. `pubspec.yaml` dependencies/dev_dependencies
2. `flutter.assets` to include `assets/translations/`
3. `mason.yaml` to include the `feature` brick path

Hook is idempotent and avoids duplicate entries.

## 5. Next commands

After generation:

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter run
```

## 6. Then generate features

Once app bootstrap is ready:

```bash
mason make feature
```

For feature details, see `docs/feature_brick_usage.md`.

## 7. Troubleshooting

1. If route generation fails, re-run build runner.
2. If notifications are not needed yet, set `enable_notifications` to `false`.
3. If your repo layout differs, update the generated `mason.yaml` feature path.
