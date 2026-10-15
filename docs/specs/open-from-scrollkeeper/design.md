# Open from Scrollkeeper: design

## Contract
Scrollkeeper's `docs/specs/app-handoff/design.md` defines both halves:

- the map index, `~/Library/Application Support/Scrollkeeper/Shared/maps.json`
  (`formatVersion`, `generatedAt`, `titles[{sku, title, series?, number?, downloaded}]`);
- the requests, `scrollkeeper://open?sku=<SKU>&app=mapsmith` and
  `scrollkeeper://download?…`, which downloads without opening.

`downloaded` is optional here: an older Scrollkeeper leaves it out, and then no
cloud icons are shown.

Mapsmith keeps its own `Codable` mirror of the index and does not depend on
ScrollkeeperKit. It reads `formatVersion` first and refuses versions it does
not know.

## MapsmithCore
- `ScrollkeeperMapIndex` decodes the index; `search(_:)` matches every word of
  the query, folded for case and diacritics, against title and series.
- `ScrollkeeperLibrary` locates Scrollkeeper and its index and returns a
  `ScrollkeeperLibrary.State`: `notInstalled`, `noCatalog`,
  `unsupportedVersion` or `loaded(index)`. The index location is a single
  constant, `ScrollkeeperLibrary.defaultIndexURL`.
- `ScrollkeeperLibrary` also builds the request URL and asks Scrollkeeper to
  open a title or to come forward.
- `PendingDownloads` holds the titles whose cloud was clicked. While it is not
  empty the sheet rereads the list every second, and `settle(with:)` drops the
  titles now downloaded.
- `ApplicationLauncher` is the protocol for "is this app installed", "open
  this URL" (in front or in the background) and "launch this app". The app supplies an `NSWorkspace` version;
  tests supply a fake, as with `RecentDocumentStore`.

## App
- `AppModel.showsScrollkeeperSearch` drives a `.sheet` on `ContentView`, so the
  command acts on the frontmost window (R1.5 of multiple-documents). A sheet
  rather than a separate window, because the app quits when its last window
  closes, which would happen before Scrollkeeper sends the files back.
- Files come back through `NSWorkspace.open(_:withApplicationAt:)` in
  Scrollkeeper, which arrives at `AppDelegate.application(_:open:)` and the
  `DocumentRouter` like any Finder open. No new code path.

## Sandboxing
Neither app is sandboxed. If they become sandboxed, the request and the files
coming back keep working; reading the index from Scrollkeeper's folder does
not. The index then moves to an App Group container shared by the Tableside
Toolkit apps, and only `ScrollkeeperLibrary.defaultIndexURL` changes here.
