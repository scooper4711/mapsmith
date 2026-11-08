# Ink cost: design

## Coverage (MapsmithCore)
- `InkCoverage` is the coverage of each ink in page-equivalents: `cyan`,
  `magenta`, `yellow` and `black`, where 1.0 is one sheet of the selected paper
  covered completely by that ink. It adds up across pages.
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
- `InkSet` is one printer's prices: `price` (a `Decimal`) and `cartridges`.
  An `InkCartridge` has `name`, `ink` (`InkColor`: `.cyan`, `.magenta`,
  `.yellow`, `.black` or `.unused`) and `ratedPages`.
- `InkSet.cost(of:)` takes an `InkCoverage` and applies R3.2:
  `price / usedCount × (coverage[ink] / 0.05) / ratedPages` for each used
  cartridge. A cartridge with no rated pages adds nothing; a set with no
  used cartridges costs nothing.
- `InkSet.defaults(from:)` builds a set from the cartridges a printer reports
  (`PrinterSupply`: name, color, type), choosing `ink` from the reported color
  and, among several blacks, the one whose name contains "PG" (otherwise the
  first). A printer that reports nothing gets cyan, magenta, yellow and black.
- `InkPriceStore` keeps a JSON-encoded `InkSet` per printer name in
  `UserDefaults` under `inkSet.<printer name>`.

## Printer supplies (Mapsmith)
- `PrinterSupplies.list(for:)` reads the CUPS printer options `marker-names`,
  `marker-colors` and `marker-types` with `cupsGetNamedDest` and
  `cupsGetOption`, keeping only `ink-cartridge` and `toner` supplies. Mapsmith
  reads only the names, never `marker-levels`.
- The sandbox's `com.apple.security.print` entitlement covers this. If CUPS
  gives nothing, the list is empty and R1.2's fallback applies.

## UI (Mapsmith)
- `InkSettingsView` is the Ink pane of the app's `Settings` scene. It picks a
  printer (the installed printers, the selected one first) and edits its
  `InkSet`: a price field, and one row per cartridge with its name, an ink
  picker and a rated-pages field. A caption says where the rated yield is
  found.
- `InkSet.isComplete` is true when the price is above zero and every used
  cartridge has rated pages. The Result section shows the estimate only then.
- `AppModel.inkEstimate` holds the map's total `InkCoverage` and the page
  count. It is recalculated in a detached task whenever `plan`, `page` or the
  loaded map changes, and a newer request cancels an older one. The inspector
  turns it into money with the selected printer's `InkSet`, so editing prices
  doesn't recalculate the coverage.
- The amounts use `Decimal.FormatStyle.Currency` with the region's currency
  code.
