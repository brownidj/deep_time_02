
# CURRENT_STATE
Bug: https://issuetracker.google.com/issues/518853233
## Code prompt

### Architecture & Separation of Concerns
- Establish an architecture that sets explicit boundaries between UI, domain, and infrastructure layers. This should be reflected in the directory structure.
- Avoid dumping new files in the project root; just keep main.py there.
- `main.py` or `main.dart` must not contain any wiring, domain logic, or infrastructure.
- Keep UI wiring, domain logic, and infrastructure separated. Domain must not import infra or UI.
- Prefer thin orchestrators and small, focused services. Use explicit service helpers for UI side effects.
- Avoid direct dialog/widget mutations across layers; use adapters/services (for example, `CategoryManagerUIService`, `AddEditStateService`).
- Keep init/builders as composition roots; do not leak logic into UI builders.
- Prefer explicit dependencies via small dataclasses/services rather than hidden attribute reach-through.

### Readability & Maintainability
- Use clear, short functions with a single responsibility. Extract helpers when logic grows.
- Avoid `getattr`/duck typing in production flow unless truly necessary; prefer adapters/registries.
- Write defensive UI code (best-effort; never crash), but keep error handling narrow and intentional.
- Keep naming consistent with existing patterns: `*Service`, `*Controller`, `*Coordinator`, `*Effects`, `*Rules`.
- Always add explicit error types in try/catch.
- Avoid code duplication.
- Avoid overly clever abstractions.

### File Size Constraint
- Keep each file under 300 lines. If a file approaches 300, split it into focused modules.
- Make a script to do this at regular intervals, adjusted for the local project.

Example:

```bash
#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="${1:-.}"
if ! command -v rg >/dev/null 2>&1; then
  echo "rg (ripgrep) is required." >&2
  exit 1
fi
rg --files "$ROOT_DIR" \
  | rg -v "^${ROOT_DIR}/assets/" \
  | rg -v "^${ROOT_DIR}/pubspec.lock$" \
  | rg -v "^${ROOT_DIR}/ios/Runner.xcodeproj/project.pbxproj$" \
  | rg -v "^${ROOT_DIR}/macos/Runner.xcodeproj/project.pbxproj$" \
  | xargs wc -l \
  | awk '$2 != "total" && $1 > 300 {print $1, $2; found=1} END{exit found?1:0}'
```

### Testing & Refactors
- Always consider adding new tests, even small ones, and always make appropriate suggestions.
- Add small pure tests for new services/helpers when behavior might regress.
- Preserve behavior; refactors should be test-driven and avoid hidden side effects.
- Add Flutter integration tests to test the UI, especially for iOS.
- Consider using Patrol for Android UI tests.
- Remind me to run tests when appropriate.
- Remind me to run manual tests when appropriate.
- Avoid leaving brittle wrappers behind when refactoring code.
- Always start major refactoring in a new branch.

### Coding Style
- Prefer explicit imports. Avoid large inline logic inside UI event handlers.
- Keep log noise low; log failures only in hot paths.

### Output
- Make changes in one pass; keep diffs minimal and focused.
- Maintain a `CURRENT_STATE.md` file that contains this prompt at the top of the file, then the state of the code base architecture, then a report of running any tests.

### Debugging
- Add a debugging code system that allows all debug code to be turned off.
- When debug code is added, make sure it complies with this prerequisite.

### Git
- Remind me to commit and push when appropriate.
- Before doing large-scale refactoring, remind me to change to a refactoring branch.

## If a database is required

### Database requirements
- Use the built-in `sqlite3` library unless there is a strong reason otherwise.
- Organize the code clearly, with separation between:
  1. database connection/setup
  2. schema creation
  3. CRUD operations
  4. utility/helper functions
- Include clear comments throughout.
- Use parameterized queries everywhere to prevent SQL injection.
- Use context managers or another safe pattern to ensure connections and transactions are handled correctly.
- Include proper error handling for database operations.
- Design the code so it can be reused in a larger application.

### Database expectations
- Create the database file if it does not already exist.
- Define a schema using `CREATE TABLE IF NOT EXISTS`.
- Include a primary key for each table.
- Add appropriate foreign keys, unique constraints, default values, and indexes where sensible.
- Enable foreign key enforcement.
- Include a function to initialize the database schema.

### Database coding expectations
- Use classes or well-structured functions, whichever is more appropriate for clarity and maintainability.
- Include type hints where reasonable.
- Avoid overly clever abstractions; prefer readable, practical code.
- Make the design easy to extend with additional tables later.
- Return query results in a convenient format, such as tuples, dictionaries, or lightweight objects, and be consistent.

### Database functionality to include
- Connect to the SQLite database.
- Initialize schema.
- Insert records.
- Fetch one record.
- Fetch multiple records.
- Update records.
- Delete records.
- Optionally search/filter records.
- Optionally support soft delete if appropriate.

### Database testing/demo expectations
- Include a short example showing how to initialize the database and perform basic CRUD operations.
- Include sample table definitions and example usage data.

### Database output expectations
- After the code, briefly explain the structure and design decisions.
- Do not omit important implementation details.

## Code base architecture state

Assessment date: 2026-05-21

### Overall status
- Layered architecture now exists: `lib/domain`, `lib/application`, `lib/app`, `lib/ui`, and `lib/infra`.
- The app boots through a small composition root and now presents a full-width timeline-first layout.
- SQLite-backed storage is in place to allow annual updates to time boundaries and fossil ranges.

### Implemented so far
- Database-backed timeline storage (divisions, taxa, fossil ranges) with schema, seed data, and repositories.
- Timeline service to load divisions/taxa and query overlapping fossil ranges.
- Added `TimelineLayoutService` to derive display-safe timeline segments from hierarchical divisions.
- Implemented a full-width continuous row UI with geological bands (eon/era) and interactive rows for period, epoch, stage, and representational life (RLife).
- Carboniferous continuity is handled in one strip by splitting into contiguous `Mississippian` then `Pennsylvanian` segments.
- Representational life (RLife) row renders period-aligned organism lists and uses period colors.
- Added an Events row with interval bars (e.g., GOE/GOBE) and point markers (e.g., PETM), aligned to timeline units.
- Embedded explicit per-division colors in `data/time_divisions.yaml` (every node has a `color`) and load them via a YAML palette repository; missing colors are treated as errors (no fallback). Palette keys are hierarchical paths to avoid float drift.
- Central debug gate (`AppDebug`) for logging.
- Added a pure unit test for timeline layout behavior (`test/timeline_layout_service_test.dart`).
- Added pure unit tests for deep-time palette anchors and interpolation behavior (`test/deep_time_palette_test.dart`).
- Geological time divisions captured in `data/time_divisions.yaml` and loaded into SQLite on first run.
- YAML data now uses `end_ma` values (boundary ages) plus optional `uncertainty_ma`; seeding derives start/end ranges from sibling boundaries.
- Mass extinction markers are rendered as small yellow triangles at period boundaries, with labels and tooltips.

### Code goodness (quality assessment)
- Strengths:
  - Clear separation of concerns with domain contracts and infra implementations.
  - UI stays free of database imports and relies on service orchestration.
  - Files are small and readable; no file exceeds 300 lines.
- Gaps and risks:
  - No database migrations/versioning yet, so schema changes are manual.
  - The in-memory test database helper is unused; no integration tests exercise SQLite.
  - Error handling is minimal for DB operations beyond the close path.
  - Geological boundary consistency (end date equals next start date) is not enforced by rules/constraints.
  - Geologic rank taxonomy now includes `stage`, but rank handling is still incomplete for other possible labels.
- There are few in-code comments, which is below the prompt expectation to include clear comments throughout.

### Architecture and separation of concerns
- `lib/main.dart` is a thin entry point that only calls `runApp`.
- Composition lives in `lib/app` with `AppDependencies` and `TimeApp`.
- Domain models and repository contracts are isolated in `lib/domain`.
- Infrastructure code lives in `lib/infra` with database setup, schema, seed data, and repository implementations.
- Palette loading is handled by `YamlTimelinePaletteRepository` in infra and exposed via `TimelineService` with validation that every division has a color. Seeding now reinitializes the DB if the division count changes.
- Layout derivation now lives in `lib/application/services/timeline_layout_service.dart` and helper modules (`timeline_layout_builder.dart`, `timeline_layout_rows.dart`, `timeline_layout_slots.dart`, `timeline_layout_rlife.dart`).
- UI remains split into screen/widget modules under `lib/ui` and consumes service output only.

### Readability and maintainability
- Services are small and focused (`TimelineService`, `TimelineLayoutService`).
- Timeline width and ordering math is extracted from widgets into a dedicated service for easier testing.
- Error handling is narrow; the database close path logs through `AppDebug`.

### File-size constraint compliance
- All Dart files are under 300 lines.
- `scripts/check_file_sizes.sh` now skips binary files and explicitly excludes `data/time_divisions.yaml`.

### Testing and refactor posture
- Added a small pure test for `TimelineService`.
- Added a small pure test for `TimelineLayoutService` (continuous ordering + Carboniferous split behavior).
- Integration and desktop UI tests are not yet in place.

### Debug gating status
- A central `AppDebug` gate exists in `lib/app/app_debug.dart`.

### Database design summary
- SQLite schema covers geologic divisions, paleontology taxa, and fossil ranges.
- Foreign keys and an index support integrity and lookups.
- Seed data provides an initial time scale slice and paleontology ranges.
- Fossil ranges are queried by overlap with division windows, allowing taxa to span multiple divisions.

## Tests run

Run date: 2026-05-21

1. `flutter analyze`
- Result: pass (no issues).

2. `./scripts/check_file_sizes.sh .`
- Result: pass.
