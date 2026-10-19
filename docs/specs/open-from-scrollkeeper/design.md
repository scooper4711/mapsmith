# Open from Scrollkeeper: design

## Contract
Scrollkeeper's `docs/specs/app-handoff/design.md` defines all of it:

- the index request, `scrollkeeper://index?app=mapsmith`, which Scrollkeeper
  answers by opening a title index file (`mapsmith.scrollkeeperindex`) with
  Mapsmith (`formatVersion`, `generatedAt`,
  `titles[{sku, title, kind, series?, number?, downloaded}]`, maps only);
- the requests, `scrollkeeper://open?sku=<SKU>&app=mapsmith` and
  `scrollkeeper://download?…`, which downloads without opening;
- the status links, `mapsmith://handoff?sku=<SKU>&state=downloading|done|failed`
  with `fraction` or `reason`. A failed index request has an empty SKU.

Being handed the list as a file, rather than reading Scrollkeeper's folder,
works in the App Sandbox: Launch Services gives Mapsmith access to the files it
is asked to open. Mapsmith keeps its own `Decodable` mirror of the index and
does not depend on ScrollkeeperKit. It reads `formatVersion` first and refuses
versions it does not know.

Pluck has the same bridge. When a third app needs it, the shared code moves
into a package.

## MapsmithCore
- `ScrollkeeperIndex` decodes the index; `search(_:)` matches every word of
  the query, folded for case and diacritics, against title and series.
- `ScrollkeeperBridge`, `@Observable`, holds a `State` (`idle`,
  `notInstalled`, `waiting`, `unsupportedVersion`, `unreadable`,
  `failed(reason)` or `loaded(index)`) and the requests sent since the list was
  last asked for, by SKU. `requestIndex()` clears them and asks for the list;
  `receive(_:)` reads the file; `open(_:)` and `download(_:)` send a request in
  the background; `receiveStatus(_:)` moves a request through `requested`,
  `downloading(fraction)`, `done` and `failed(reason)`, and on `done` marks the
  title downloaded in the loaded index.
- `ApplicationLauncher` is the protocol for "is this app installed", "open
  this URL in the background" and "launch this app". The app supplies an
  `NSWorkspace` version; tests supply a fake, as with `RecentDocumentStore`.

## App
- `AppDelegate` owns the bridge. `application(_:open:)` sends status links and
  index files to it and everything else to the `DocumentRouter`, so the maps
  Scrollkeeper opens arrive like any Finder open.
- `Info.plist` declares the `mapsmith` URL scheme and imports Scrollkeeper's
  index type (`io.github.scooper4711.scrollkeeper.index`) as a document type.
- `ScrollkeeperWindow` is a `Window` scene of its own, opened with
  `openWindow(id:)`, as in Pluck. It is not a sheet: the list and the status
  links arrive as open events while it is up, and SwiftUI hands each of them a
  new document window (which then fails to show it as a map) when the
  frontmost document window has a sheet. The window closes when a request to
  open reaches `done`, just before the files arrive; the document window the
  command was chosen from, or the empty launch window, keeps the app from
  quitting meanwhile.

## Sandboxing
Mapsmith runs in the App Sandbox (see `app-sandbox`). Launch Services gives it
access to the list and the maps Scrollkeeper opens in it, so this feature
needs nothing more.
