# Ink cost: design

## Coverage (MapsmithCore)
- `InkCoverage` is the coverage of each ink in page-equivalents: `cyan`,
  `magenta`, `yellow` and `black`, where 1.0 is one sheet of the selected paper
  covered completely by that ink. Coverages add up across pages, and
  `coverage[ink]` looks one up by `InkColor`.
- `InkCoverageEstimator.coverage(map:plan:page:)` returns one `InkCoverage` per
  tile. It draws each tile, scaled down to 36 pixels per inch, into an 8-bit
  `CGContext` in the generic CMYK color space (`CGColorSpace.genericCMYK`) and
  averages each channel. Core Graphics does the RGB-to-CMYK separation,
  including black generation, so Mapsmith doesn't need its own. The average
  is weighted by the tile's printed area over the paper's area, so the white
  border and an edge tile's empty part count as uncovered paper.
- It uses the same rotated map and tile rectangles as `TileExporter`, so the
  estimate matches what is printed. It throws
  `TileExportError.imageProcessingFailed` with the step that failed.

## Prices (MapsmithCore)
- `InkSet` is one printer's `cartridges`. An `InkCartridge` has `name`, `ink`
  (`InkColor`: `.cyan`, `.magenta`, `.yellow`, `.black` or `.unused`),
  `ratedPages` and `price` (a `Decimal`).
- `InkSet.cost(of:)` applies R3.2: `price × (coverage[ink] / 0.05) /
  ratedPages`, summed over the used cartridges. A cartridge with no rated
  pages adds nothing.
- `InkSet.isComplete` is true when every used cartridge has a price above zero
  and rated pages. Only a complete set gives an estimate.
- `InkSet.defaults(from:)` builds a set from the supplies a printer reports,
  keeping ink cartridges and toner. Of several blacks only the one whose name
  contains "PG" (otherwise the first) is used. A printer that reports nothing
  gets cyan, magenta, yellow and black.
- `PrinterSupply` is a reported supply: name, color and type. Its `ink` comes
  from the color (each RGB channel high or low gives cyan, magenta, yellow or
  black), else from words in the name, else `.unused`.
  `PrinterSupply.list(names:colors:types:)` splits CUPS's comma-separated
  values, honoring backslash escapes and quotes. Some printers (a Xerox
  VersaLink) leave a comma inside a name unescaped, so a piece starting with a
  space joins the one before it; a serial number after a semicolon is dropped.
- `InkPriceBook` (`@Observable`, main actor) keeps a JSON-encoded `InkSet` per
  printer name in `UserDefaults` under `inkSet.<printer name>`.
  `completeSet(for:)` is the set used for estimates. A revision counter bumped
  on save makes views update when prices change.

## Printer supplies (Mapsmith)
- `PrinterSupplies.list(for:)` finds the CUPS destination whose queue name or
  `printer-info` is the printer's AppKit name, and reads its `marker-names`,
  `marker-colors` and `marker-types` options with `cupsGetOption`. It never
  reads `marker-levels`. The sandbox's `com.apple.security.print` entitlement
  covers this; if CUPS gives nothing, R1.2's fallback applies.

## UI (Mapsmith)
- The app's `InkPriceBook` belongs to `AppDelegate` and reaches document
  windows through the environment.
- `InkSettingsView` is the app's `Settings` scene. It picks a printer (the
  current one first) and edits its `InkSet`: one row per cartridge with its name, an ink picker, a price field in the
  region's currency (disabled for an unused cartridge) and a rated-pages field. A footer says where the rated yield is found. Each change
  is saved at once.
- `AppModel.inkEstimateKey` is what the estimate depends on: the selected map,
  the plan and the page. The inspector runs
  `AppModel.estimateInk()` in a `task(id:)` on that key, so a newer plan cancels
  an older estimate; the coverage is worked out in a detached task and kept in
  `AppModel.inkCoverage` with its key. `InkCostRow` in the Result section turns it into money with the
  selected printer's complete `InkSet`, so editing prices doesn't recalculate
  the coverage, and shows nothing without one.
- The amounts use `Decimal.FormatStyle.Currency` with the region's currency
  code: the whole map to the unit, a page to two decimals.
