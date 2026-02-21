# common_package

Internal Flutter foundation package for fast, consistent app setup.

## What It Provides

- `bootstrapApp(...)` startup flow (no flavors required)
- Networking and error-handling helpers (`dio`, failures, interceptors)
- Notification helper (`firebase_messaging` + `awesome_notifications`)
- Common widgets/extensions/theme utilities
- Mason bricks for app bootstrap and feature scaffolding
- Route generation annotation (`@AutoRoutePage`) + builder config

## Using Mason Bricks in Your Flutter Project

Mason is a code generator that helps you scaffold Flutter projects quickly and consistently. This package provides two Mason bricks: `app_bootstrap` and `feature`.

### 1. Install Mason CLI

First, install Mason CLI globally using Dart:

```bash
dart pub global activate mason_cli
```

Make sure Mason is in your PATH. You can verify the installation:

```bash
mason --version
```

### 2. Add Bricks to Your Flutter Project

In your Flutter project root, create or update a `mason.yaml` file to reference the bricks from this package.

**Option A: If you have cloned the repository locally:**

```yaml
bricks:
  app_bootstrap:
    path: ../common_package/bricks/apps/app_bootstrap
  feature:
    path: ../common_package/bricks/features/feature
```

**Option B: Clone the repository to use the bricks:**

```bash
git clone https://github.com/Dllni-Com/flutter_common_package.git
```

Then reference it in `mason.yaml`:

```yaml
bricks:
  app_bootstrap:
    path: ../flutter_common_package/bricks/apps/app_bootstrap
  feature:
    path: ../flutter_common_package/bricks/features/feature
```

**Note:** Adjust the path based on where your Flutter project is located relative to the cloned `common_package` directory.

### 3. Get Mason Bricks

After adding the brick references, get them using:

```bash
mason get
```

This will download and cache the bricks locally, making them available for use in your project.

### 4. Use the Bricks

Once set up, you can use the bricks in your Flutter project:

- **App Bootstrap:** Generates the initial app structure with routing, dependency injection, and configuration
  ```bash
  mason make app_bootstrap --on-conflict overwrite
  ```

- **Feature:** Generates a clean feature scaffold with optional usecases
  ```bash
  mason make feature
  ```

For more details on each brick, see the individual README files:
- `bricks/apps/app_bootstrap/README.md`
- `bricks/features/feature/README.md`

## Quick Start (No Flavors)

1. Add dependency in your app `pubspec.yaml`:

```yaml
dependencies:
  common_package:
    git:
      url: https://github.com/Dllni-Com/flutter_common_package.git
```

2. Run bootstrap brick in your app:

```bash
mason make app_bootstrap --on-conflict overwrite
```

3. Generate routes and run:

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter run
```

## Bootstrap Helper Usage

```dart
import 'package:common_package/common_package.dart';
import 'package:flutter/material.dart';

Future<void> main() async {
  final navigatorKey = GlobalKey<NavigatorState>();

  await bootstrapApp(
    AppBootstrapConfig(
      navigatorKey: navigatorKey,
      app: MyApp(navigatorKey: navigatorKey),
      configureDependencies: () async {
        // Register your dependencies here.
      },
      enableNotifications: true,
    ),
  );
}
```

## Feature Generation Flow

After app bootstrap, generate features with:

```bash
mason make feature
```

For detailed feature brick usage, see `docs/feature_brick_usage.md`.

## Documentation

- `docs/app_bootstrap_usage.md`
- `docs/feature_brick_usage.md`
- `lib/notification_helper_usage.md`
