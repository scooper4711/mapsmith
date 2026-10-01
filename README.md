# Flip Map Printer

A macOS app that splits battle maps (Flip-Mats, PDFs, map images) into printer pages
at true scale — one grid square per inch — so they can be trimmed and taped together.

- **Open** a PDF or any image (⌘O, drag onto the window, or *Open With* in Finder).
  For PDFs, every large image in the document is shown as a thumbnail.
  Each file opens in its own window, and **File › Open Recent** lists the latest ones.
  Images dragged straight out of another app, such as a map from Pluck, can be dropped too.
- **Select** a map: its grid is detected and it is split into pages that fit the
  printable area of the current printer and paper (**File › Page Setup…**).
  Edge strips thinner than 0.5 in are trimmed rather than printed on their own pages,
  and the map is turned 90° when that uses fewer pages.
- **Print** the tiles directly (⌘P), or **Export** them as a PDF (⌘E).

Print at 100% scale. Each page keeps the printer's non-printable margin blank;
trim that border where pages meet.

## How the scale is found

Grid detection sums edge strength along every row and column of the map and finds the
repeat distance by autocorrelation. If no grid is found, the app falls back to the
PDF's own page scale or the image's DPI metadata, and you can always type the pixels per
grid square yourself in the Settings inspector.

## Building

Requires macOS 15+ and Xcode 16+ (Swift 6).

```sh
swift test                         # unit tests
scripts-build/bundle.sh            # builds "build/Flip Map Printer.app"
scripts-build/bundle.sh --install  # …and copies it to /Applications
```

Open `Package.swift` in Xcode to run and debug the app.

Real-map tests use PDFs in `TestData/`, which is gitignored (the sample maps are
copyrighted); those tests are skipped when the folder is empty.
