# iPad app: design

## Targets
- `MapsmithUI` (library) holds the SwiftUI app shared by both platforms:
  `MapsmithApp`, the views and `AppModel`. Platform code sits behind
  `#if os(macOS)` / `#if os(iOS)`, mostly in files of its own.
- `Mapsmith` (Mac executable) is `main.swift` calling `MapsmithApp.main()`, so
  `scripts/build-app.sh` and the release keep building `Mapsmith`.
- `ios/Mapsmith.xcodeproj` (scheme `Mapsmith-iPad`) is the iPad and iPhone app.
  Its only source is `ios/App/MapsmithMain.swift`; it links `MapsmithUI` from
  the local package. Signing, version and the App Group entitlement follow
  Field Guide's `ios/` folder.
- `MapsmithCore` stays platform-neutral (CoreGraphics, ImageIO).

## Scenes
- Mac: unchanged (`WindowGroup(for: URL.self)`, Open from Scrollkeeper window,
  Settings scene).
- iOS: one `WindowGroup` whose `PadRootView` owns an `AppModel`. `onOpenURL`
  and the file importer call `AppModel.open`, which replaces the shown file
  (R1.5). Open from Scrollkeeper and Ink Prices are sheets.

## Files the app may only read in place
`AppModel.open` starts security-scoped access to the URL and stops it for the
previous file. The PDF is read again for every render, so access lasts while
the file is shown. On the Mac `startAccessingSecurityScopedResource` returns
false for ordinary URLs and nothing changes.

## Printing (`PrintSetup`)
One type per platform with the same surface: `page`, `printerName`,
`paperName`.
- Mac: wraps `NSPrintInfo` as before.
- iOS: `PadPrintSetup` keeps a `PaperChoice` (named size) and a margin in
  `UserDefaults`; `page` is the paper inset by the margin. `TilePrinter` uses
  `UIPrintInteractionController` with a `UIPrintPageRenderer` that draws each
  tile-PDF page at the paper's origin with no scaling (printing a PDF as
  `printingItem` would scale it to the printable area). Its delegate's
  `choosePaper` picks `UIPrintPaper.bestPaper(forPageSize:withPapersFrom:)` for
  the chosen size.
- The printer for ink prices comes from `UIPrinterPickerController` and is
  remembered by display name, which keys `InkPriceBook` as the Mac's printer
  name does.

## Export
Both platforms render the tiles first and then present `.fileExporter` with a
`TilesPDF` (`FileDocument`). On the Mac this replaces the modal `NSSavePanel`
with the same save panel as a window sheet.

## Scrollkeeper on iOS
tabletop-kit's `ApplicationLauncher` has `takesRequests`. The Mac launcher
(`WorkspaceLauncher`, also tabletop-kit's) says yes; the iOS one (`PadLauncher`,
Mapsmith's) says no, checks for Scrollkeeper with
`canOpenURL("scrollkeeper://")` (listed in `LSApplicationQueriesSchemes`) and
opens it with `UIApplication.open`. When the launcher takes no requests,
`ScrollkeeperBridge.requestIndex` goes to `.noSharedLibrary` instead of asking,
and the browser shows Open Scrollkeeper for titles not downloaded (R2.3).
The browser view (`ScrollkeeperBrowser`) is shared; the Mac wraps it in its
window, the iPad in a sheet. Covers load through ImageIO as `CGImage`.

## Testing
- tabletop-kit's tests cover the bridge's iOS behavior; unit tests in
  `MapsmithCoreTests` cover the paper geometry (`PaperChoice` lives in
  `MapsmithCore`).
- `ios/UITests` opens the app in both orientations on an iPad simulator and
  screenshots the empty window and the inspector.
- On an iPhone the split view holds one column. `ContentView` asks for the detail column
  (`preferredCompactColumn`), hides the way back to the list while the file has fewer than two maps, and closes
  the inspector in a compact width, where it is a sheet over the window. In a compact width it also selects
  the first map of a newly opened file (R1.6). `PhoneLayoutUITests` covers it, with a two-page PDF the app
  draws for the launch argument `-UITestSamplePDF`; `make iphone-uitests` runs the UI tests on an iPhone
  simulator.

## About
`AboutInfo.mapsmith` (MapsmithUI) holds the app's name, description and contact link; tabletop-kit's `AppNotices`
adds the notices. The Mac app's commands include `AboutCommands`; the iPad app's include it too, with
`AboutWindow` as a second scene for its menu bar item, and the toolbar's About (`DocumentActions.showAbout`, nil
on the Mac) opens `AboutSheet`. `AboutUITests` opens it and finds the notice.
