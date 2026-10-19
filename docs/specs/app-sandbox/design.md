# App Sandbox: design

- `Resources/Mapsmith.entitlements`: the App Sandbox, printing, and read-write
  access to files the user picks (File ▸ Open, the export save panel). Files
  opened from Finder, the Dock, Open Recent and by Scrollkeeper come through
  Launch Services, which grants access to them; Open Recent keeps that access
  across launches. No network access: Mapsmith makes no requests.
- `scripts/build-app.sh` signs ad hoc with the entitlements and copies
  `Resources/container-migration.plist` into the bundle's Resources. On the
  first sandboxed launch macOS moves the preferences
  (`com.github.scooper4711.Mapsmith.plist`, window layouts only) into
  `~/Library/Containers/com.github.scooper4711.Mapsmith`.
- `DroppedImageStore` writes dropped images under `temporaryDirectory`, which
  is inside the container.
- SwiftUI doesn't restore document windows in the sandbox: it would need a
  security-scoped bookmark for each file, which the restored URL doesn't carry.
  Mapsmith opens with its empty window instead.
