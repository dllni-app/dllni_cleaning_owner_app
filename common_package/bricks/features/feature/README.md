# feature

Mason brick to generate a clean-feature scaffold with optional usecases.

## Prompts

1. Feature name (`name`)
2. Comma-separated usecases (`usecases`)
3. For each usecase, model input:
   - Dart class name, or
   - JSON object (single line) to auto-generate a model
   - For class names, hook auto-detects class file in `lib/**`
   - If not found (or multiple matches), hook asks for model path under `lib/`
4. For each usecase, HTTP method:
   - `GET`, `POST`, `PUT`, `PATCH`, or `DELETE`
5. For each usecase, endpoint string:
   - Example: `auth/login`
   - Default: `/<feature>/<usecase_snake>`
6. For each usecase, response type:
   - `paginated` or `normal`

## Behavior

When usecases are provided, the hook will:

1. Generate `domain/usecases/*_use_case.dart`
2. Update `domain/repository/<feature>_repo.dart`
3. Generate/update `data/source/<feature>_remote_data_source.dart` with one API method per usecase
4. Update `data/repository/<feature>_repo_impl.dart` to call remote data source methods via `wrapHandlingException`
5. Update bloc files append-only/idempotently:
   - `view/manager/bloc/<feature>_event.dart`
   - `view/manager/bloc/<feature>_state.dart`
   - `view/manager/bloc/<feature>_bloc.dart`
6. If JSON is provided for a usecase model, generate `data/models/<usecase>_model.dart`
7. If class name is provided for a usecase model:
   - Detect class location from `lib/**/*.dart` (excluding generated `*.g.dart` and `*.freezed.dart`)
   - Resolve imports using detected/selected model file path

Bloc generation details:

1. `paginated` response type generates:
   - event with `EventWithReload` + `isReload`
   - state field `PaginationStateModel<T>?` with default `perPage: 10`
   - bloc handler with droppable transformer and pagination guard
2. `normal` response type generates:
   - event with required `params`
   - state model field + `<alias>Status` (`BlocStatus`)
   - bloc handler with loading/failed/success status flow

By default, the brick does not generate `<feature>_model.dart` anymore.

## Add Usecase to Existing Feature

To add new usecases after a feature already exists, run the same brick again
with the same feature name and only the new usecase names, using
`--on-conflict skip`.

Example:

```bash
mason make feature --name auth --usecases ResetPassword --on-conflict skip
```

This keeps existing files safe while hooks append/update usecase/repo/remote
data source wiring.

## Full usage guide

See `docs/feature_brick_usage.md` at the package root for detailed setup and examples.
