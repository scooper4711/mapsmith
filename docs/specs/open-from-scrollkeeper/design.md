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

Scrollkeeper also writes `library.json` in its folder in the App Group
(`~/Library/Group Containers/<team ID>.io.github.scooper4711.tableside/Scrollkeeper/`),
with every title, its cover and each edition's path relative to the shared
download folder, and posts the Darwin notification
`io.github.scooper4711.tableside.library-changed` after each write. Mapsmith
reads that directly when it is in the group and uses the index request only as
the fallback.

Pluck has the same bridge. When a third app needs it, the shared code moves
into a package (tabletop-kit's `TablesideShared`, tabletop-kit#22).

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
- `ScrollkeeperFolder.url()` finds Scrollkeeper's folder in the App Group: it
  reads the groups from Mapsmith's own entitlements
  (`SecTaskCopyValueForEntitlement`), so the code holds no team ID, and asks
  for the container of the one ending in `.io.github.scooper4711.tableside`.
  Nil outside the group (an ad hoc build, the tests).
- `ScrollkeeperLibrary` is a `Decodable` mirror of the parts of `library.json`
  Mapsmith uses. `mapIndex(in:)` turns its titles of kind "Maps" into
  `ScrollkeeperIndex` entries, with `coverURL` and, when the download folder
  is the shared one, `localFiles`: the first up-to-date single PDF or image,
  else the PDFs (or, without any, the images) under the first up-to-date
  unpacked archive. Neither field is decoded from the handed-over index.
- `ScrollkeeperBridge(launcher:libraryFolder:)` reads the library list first in
  `requestIndex()`: a missing, unreadable or newer list falls back to the index
  request. `refreshLibrary()` reads it again, only while the list shown came
  from it. `open(_:)` hands an entry's `localFiles` to `openDocuments`, set by
  the app, instead of sending a request.
- `ApplicationLauncher` is the protocol for "is this app installed", "open
  this URL in the background" and "launch this app". The app supplies an
  `NSWorkspace` version; tests supply a fake, as with `RecentDocumentStore`.

## App
- `AppDelegate` owns the bridge, made with `ScrollkeeperFolder.url()`.
  `application(_:open:)` sends status links and index files to it and
  everything else to the `DocumentRouter`, so the maps Scrollkeeper opens
  arrive like any Finder open; `openDocuments` sends the maps opened from the
  shared folder to the router too. At launch it registers for Scrollkeeper's
  Darwin notification (`notify_register_dispatch` on the main queue) and calls
  `refreshLibrary()`.
- Each row of the list shows the map's cover (`CoverThumbnail`, read off the
  main thread), or a map symbol.
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
access to the list and the maps Scrollkeeper opens in it. Reading the library
list, the covers and the shared downloads needs the App Group entitlement,
which a build signed with the team's Developer ID has.
