# Multiple documents and Open Recent: design

## Windows

`WindowGroup(for: URL.self)` replaces the single `Window`. Each window owns an
`AppModel`; the `AppModel.shared` singleton goes away, and background tasks
capture their own model instead. SwiftUI brings the existing window forward
when a URL is opened twice.

Every open request (File ▸ Open, Open Recent, Finder, a drop) goes through
`DocumentRouter`: whichever window sees the pending URLs first opens a window
for each. The empty launch window closes as soon as any document window
exists. File-open events are taken from the app delegate rather than SwiftUI's
`onOpenURL`, which loses files when several arrive together; windows still
declare that they handle external events so SwiftUI does not add an empty
window per event.

Menu commands find the frontmost window's model through a focused scene value.

## Page setup

Each window gets a copy of `NSPrintInfo.shared`. Confirming Page Setup writes
the choice back to the shared instance, so later windows start from it.

## Open Recent

`RecentDocuments` wraps the system recent-documents list behind a
`RecentDocumentStore` protocol (so it can be tested) and keeps its own ordered
copy, because the system list updates late.

`DocumentRouter` and `RecentDocuments` live in `MapsmithCore` so the existing
test target can cover them.

## Dropped image data

`MapDrop` handles drops through `onDrop` item providers instead of
`dropDestination(for: URL.self)`, which only sees files. A provider with a
real file URL is opened directly. Otherwise its image data (PNG when offered,
as it is lossless) is saved by `DroppedImageStore` into the app's cache folder
under an unused name, and that file is opened through the router. A promised
file is not treated as a file: it is matched by exact type, since the promise
is not readable.

## New from Clipboard

`ClipboardMap` (in `MapsmithCore`, so it is tested) decides what to open from the clipboard's file URLs and
types: copied PDFs and images win, as in a drop, and copied files that are not maps open nothing, because Finder
also puts their icons on the clipboard as images. Otherwise the data type is PNG when offered, then any other
image, then a PDF. Pasted data goes through `DroppedImageStore` like a dropped image.

`ClipboardWatcher` (in `MapsmithUI`) keeps `hasMap` for the menu item. It looks only at the clipboard's types,
which needs no paste permission, when the app becomes active (maps are copied in other apps) and, on the iPad,
when the clipboard changes inside Mapsmith. Until the command is chosen, copied files are assumed to be maps,
since reading their URLs is what can ask for permission. The Mac menu sends what it opens to the app's router;
the iPad menu reaches the window's router through a focused scene value.
