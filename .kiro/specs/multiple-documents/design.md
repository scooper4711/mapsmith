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

`DocumentRouter` and `RecentDocuments` live in `FlipMapCore` so the existing
test target can cover them.

## Dropped image data

`MapDrop` handles drops through `onDrop` item providers instead of
`dropDestination(for: URL.self)`, which only sees files. A provider with a
real file URL is opened directly. Otherwise its image data (PNG when offered,
as it is lossless) is saved by `DroppedImageStore` into the app's cache folder
under an unused name, and that file is opened through the router. A promised
file is not treated as a file: it is matched by exact type, since the promise
is not readable.
