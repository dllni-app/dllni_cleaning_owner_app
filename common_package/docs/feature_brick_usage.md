# Mason Feature Brick Usage

This guide explains how to use the `feature` Mason brick from this package inside a Flutter project.

For no-flavors app startup generation first, see `docs/app_bootstrap_usage.md`.

## 1. Add the brick to your Flutter project

Create or update `mason.yaml` in your Flutter app:

```yaml
bricks:
  feature:
    path: <path-to-common_package>/bricks/features/feature
```

Example:

```yaml
bricks:
  feature:
    path: ../common_package/bricks/features/feature
```

Then run:

```bash
mason get
```

## 2. Generate a feature

Run:

```bash
mason make feature
```

You will be asked:

1. `What is your feature name?`
2. `Enter usecase names separated by commas`
3. For each usecase: `Model for <UsecaseName> (class name or JSON object in one line)`
4. For each usecase: `HTTP method for <UsecaseName> (GET, POST, PUT, PATCH, DELETE)`
5. For each usecase: `Endpoint for <UsecaseName>`
6. For each usecase: `Response type for <UsecaseName> (paginated or normal)`

## 3. Per-usecase inputs

For each usecase, provide:

1. Model input (class name or JSON in one line)
2. HTTP method
3. Endpoint string
4. Response type (`paginated` or `normal`)

### 3.1 Model input options

### Option A: Existing model class name

Input example:

```text
LoginModel
```

The hook behavior for class-name input:

1. Auto-search `lib/**/*.dart` for `class LoginModel`.
2. Ignore generated noise files (`*.g.dart`, `*.freezed.dart`).
3. If one match is found: use it directly.
4. If no match: prompt for model file path under `lib/`.
5. If multiple matches: show options and ask you to choose (index or path under `lib/`).

Manual path format:

```text
features/auth/data/models/login_model.dart
```

Imports are then generated relative to each target file from the resolved model location.

### Option B: JSON object (single line)

Input example:

```json
{"id":1,"name":"ahmad","isActive":true}
```

The hook will:

1. Create a model file named with the usecase, for example `login_model.dart`.
2. Create a root class named `<UsecaseName>Model` (example: `LoginModel`).
3. Add `fromJson` and `toJson` methods.
4. Add top helper functions for every generated class (root and nested), for example:
   - `loginModelFromJson(str)`
   - `loginModelToJson(LoginModel data)`
5. Wire that model type into:
   - `domain/usecases/<usecase>_use_case.dart`
   - `domain/repository/<feature>_repo.dart`
   - `data/source/<feature>_remote_data_source.dart`
   - `data/repository/<feature>_repo_impl.dart`

### 3.2 HTTP method options

Allowed values:

- `GET`
- `POST`
- `PUT`
- `PATCH`
- `DELETE`

### 3.3 Endpoint input

- Endpoint is used exactly as entered.
- Default value is:

```text
/<feature>/<usecase_snake>
```

### 3.4 Response type input

- Allowed values:
  - `paginated`
  - `normal`
- `paginated` generates pagination-oriented bloc/event/state wiring.
- `normal` generates standard status-based bloc/event/state wiring.

## 4. Generated structure (summary)

For feature `auth` and usecase `Login`, the brick generates/updates:

```text
lib/features/auth/domain/usecases/login_use_case.dart
lib/features/auth/domain/repository/auth_repo.dart
lib/features/auth/data/source/auth_remote_data_source.dart
lib/features/auth/data/repository/auth_repo_impl.dart
lib/features/auth/view/manager/bloc/auth_event.dart
lib/features/auth/view/manager/bloc/auth_state.dart
lib/features/auth/view/manager/bloc/auth_bloc.dart
lib/features/auth/data/models/login_model.dart   (when JSON is provided)
```

## 5. Generated remote data source behavior

For each usecase, the hook generates:

1. A remote method with signature:
   - `Future<ModelClass> methodName(UsecaseParams params)`
2. A `dioNetwork` call based on selected HTTP method.
3. Request mapping:
   - `POST/PUT/PATCH`: `data: params.getBody()`, `params: params.getParams()`
   - `GET/DELETE`: `params: params.getParams()`, `data: params.getBody().isEmpty ? null : params.getBody()`
4. Response mapping through:
   - `wrapHandlingApi(...)`
   - `<modelNameCamel>FromJson`

## 6. Generated repo implementation behavior

For each usecase method in `<feature>_repo_impl.dart`:

1. The hook injects `<Feature>RemoteDataSource`.
2. Method body is generated as:
   - `wrapHandlingException(tryCall: () => remoteDataSource.method(params))`
3. If a method already exists:
   - If it still contains `throw UnimplementedError()`, it is replaced with the generated implementation.
   - If it has custom logic, it is left unchanged.

## 7. Important notes

1. JSON input must be in one line in terminal prompt.
2. No default `<feature>_model.dart` is created when generating a feature.
3. If the model file already exists, JSON model generation is skipped (file is not overwritten).
4. Running the brick again is idempotent for imports and generated methods.
5. Existing custom repo method implementations are preserved.
6. Bloc/event/state updates are append-only and idempotent:
   - missing generated events/fields/handlers are appended
   - existing non-generated custom handlers/methods are not overwritten
7. Paginated item type is inferred from the model file (targeting `List<T>? data` first); fallback is `dynamic` with a hook warning.
8. For class-name models, import location is resolved from the selected/detected file under `lib/`.

## 8. Add usecase to existing feature (recommended)

When a feature already exists and you want to add a new usecase, run the same
brick again with:

1. the same feature name
2. only new usecase names
3. `--on-conflict skip`

Single usecase example:

```bash
mason make feature --name auth --usecases ResetPassword --on-conflict skip
```

Multiple usecases example:

```bash
mason make feature --name auth --usecases ResetPassword,RefreshToken --on-conflict skip
```

For each new usecase, answer:

1. model input (class name or one-line JSON)
2. HTTP method (`GET`, `POST`, `PUT`, `PATCH`, `DELETE`)
3. endpoint string (for example `auth/reset-password`)
4. response type (`paginated` or `normal`)

### 8.1 What gets generated/updated

For each new usecase, the hook updates:

1. `lib/features/<feature>/domain/usecases/<usecase>_use_case.dart` (new file)
2. `lib/features/<feature>/domain/repository/<feature>_repo.dart` (new method signature)
3. `lib/features/<feature>/data/source/<feature>_remote_data_source.dart` (new remote method)
4. `lib/features/<feature>/data/repository/<feature>_repo_impl.dart` (auto-wired repo call)
5. `lib/features/<feature>/view/manager/bloc/<feature>_event.dart` (new event class)
6. `lib/features/<feature>/view/manager/bloc/<feature>_state.dart` (new state fields/copyWith/constructor params)
7. `lib/features/<feature>/view/manager/bloc/<feature>_bloc.dart` (new dependency, registration, handler)
8. `lib/features/<feature>/data/models/<usecase>_model.dart` (if JSON model input was provided)

### 8.2 Why `--on-conflict skip`

`--on-conflict skip` prevents template files from overwriting your existing
feature files while still allowing hooks to append/update methods and imports.

### 8.3 Verification scenarios

1. Add one usecase: only new files/methods are added.
2. Add multiple usecases: each appears once, no duplicate imports/methods.
3. Re-run same usecase input: no duplicated generated methods/events/state fields/handlers.
4. Existing custom repo method logic is preserved; only stub methods using
   `throw UnimplementedError()` are upgraded.

### 8.4 Assumptions and defaults

1. Pass only new usecase names in `--usecases`.
2. Endpoint is used exactly as entered.
3. Default endpoint prompt is `/<feature>/<usecase_snake>`.
