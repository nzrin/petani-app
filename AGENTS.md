# Project instructions

## App reference folder

- Use `/Volumes/Development/App/Flutter` as the main folder for app projects.
- When asked to reference another app, look for that app under this folder first.

## Crop harvest estimates

- Whenever adding or enabling a crop, add its sourced estimate to
  `assets/data/crop_harvest_estimates.json` in the same change. Keep the crop code
  identical to the crop catalog/database. The generic harvest catalog integrates
  the entry into Home and the planting-date help automatically.
- Verify a primary agricultural source, days/range, planting-date basis and
  milestone (first harvest, first yield, first flower or first tapping). Distinguish
  sowing from transplant dates and first yield from recurring harvests. Do not
  invent variety-specific timings; document any general planning fallback.
- Run `flutter test --no-pub test/crop_harvest_estimate_test.dart
  test/crop_selection_repository_test.dart test/crop_expansion_test.dart`.
  Coverage tests must include every available crop in both UI and SQLite catalogs.
