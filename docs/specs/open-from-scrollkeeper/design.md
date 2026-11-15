# Open from Scrollkeeper: design

## Contract
Scrollkeeper's `docs/specs/app-handoff/design.md` defines all of it:

- the library list, `library.json`, which Scrollkeeper writes in its folder in
  the App Group
  (`~/Library/Group Containers/<team ID>.io.github.scooper4711.tableside/Scrollkeeper/`),
  with every title, its cover and each edition's path relative to the shared
  download folder, and the Darwin notification
  `io.github.scooper4711.tableside.library-changed` it posts after each write;
- the requests, `scrollkeeper://open?sku=<SKU>&app=mapsmith` and
  `scrollkeeper://download?…`, which downloads without opening;
- the status links, `mapsmith://handoff?sku=<SKU>&state=downloading|done|failed`
  with `fraction` or `reason`.

The contract also has an index request (`scrollkeeper://index?app=…`), answered
with a title index file, which came before the shared library. Mapsmith used
it as a fallback and no longer does (R1.6): it sends no index request and has
no document type for the file.

The App Group lookup, the library list's format, the change notification and
the bridge that speaks this contract are tabletop-kit's `TablesideShared`
(`docs/specs/tableside-shared` there, R5 for the bridge), shared with
Scrollkeeper, which writes the list, and the other readers. Pluck uses the same
bridge with its own configuration.

## MapsmithCore
- `ScrollkeeperBridgeConfiguration.mapsmith` is how Mapsmith configures the
  shared `ScrollkeeperBridge`: app key and status scheme `mapsmith`; it lists
  the library's titles of kind "Maps" and, every title being a map, leaves the
  kind out of the subtitle and the search; it opens PDFs and images; it
  sends several requests side by side, so one map can download while another
  is asked for; and it doesn't ask for the index (`asksForIndex` is false), so
  without a library list it can show the bridge says `noSharedLibrary`,
  `unsupportedVersion` or `unreadable` and looks again when the list changes.
- Everything else is the shared bridge's: its `State`, `requestIndex()`,
  `open(_:)`, `download(_:)`, `receiveStatus(_:)`,
  `refreshLibrary()`, the `ScrollkeeperIndex` it lists and searches, and
  `ApplicationLauncher` with the Mac's `WorkspaceLauncher`. Its tests are in
  tabletop-kit; Mapsmith tests its configuration.

## App
- `AppDelegate` owns the bridge, made with `.mapsmith`, a `WorkspaceLauncher`
  and `ToolkitGroup.scrollkeeperFolder()`. `application(_:open:)` sends status
  links to it and everything else to the `DocumentRouter`, so the maps
  Scrollkeeper opens arrive like any Finder open; `openDocuments` sends the maps opened from the
  shared folder to the router too. At launch it keeps a
  `LibraryChangeObserver`, which calls `refreshLibrary()` each time Scrollkeeper
  rewrites the list.
- Each row of the list shows the map's cover (the shared
  `ScrollkeeperCoverThumbnail`, read off the main thread), or a map symbol.
- `Info.plist` declares the `mapsmith` URL scheme for the status links.
- `ScrollkeeperWindow` is a `Window` scene of its own, opened with
  `openWindow(id:)`, as in Pluck. It is not a sheet: the status links arrive
  as open events while it is up, and SwiftUI hands each of them a
  new document window (which then fails to show it as a map) when the
  frontmost document window has a sheet. The window closes when a request to
  open reaches `done`, just before the files arrive; the document window the
  command was chosen from, or the empty launch window, keeps the app from
  quitting meanwhile.

## Sandboxing
Mapsmith runs in the App Sandbox (see `app-sandbox`). Launch Services gives it
access to the maps Scrollkeeper opens in it. Reading the library list, the
covers and the shared downloads needs the App Group entitlement, which a build
signed with the team's Developer ID has; an ad hoc build has no list (R1.6).
