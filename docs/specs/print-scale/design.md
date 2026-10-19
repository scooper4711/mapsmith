# Print scale: design

- `ScaleEntry` (MapsmithCore) is what the user typed: `pixelsPerSquare`,
  `squaresAcross` or `squaresDown`. `pixelsPerInch(mapSize:)` turns it into
  pixels per inch, nil when that isn't a positive, finite number;
  `squares(mapSize:pixelsPerInch:)` goes the other way for display.
- `AppModel.setScale(_:)` sets `manualPixelsPerInch` from an entry (nil clears
  it); `mapPixelSize` is the loaded map's size.
- `DeferredNumberField` keeps its own draft and commits it after
  `DeferredNumberField.pause` without a change (a `.task(id: draft)` that
  sleeps), or at once on Return. It takes the model's value again whenever that
  changes, so the three fields stay in step.
