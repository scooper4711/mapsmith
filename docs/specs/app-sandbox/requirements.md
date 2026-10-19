# App Sandbox: requirements

Mapsmith runs in the macOS App Sandbox, as the other Tableside Toolkit apps
will, so it can be distributed through the Mac App Store and can only touch the
files the user gives it.

## R1 What still works
- R1.1 Opening maps from File ▸ Open, Finder, the Dock, a drop, and Open
  Recent, also after Mapsmith is relaunched.
- R1.2 Open from Scrollkeeper: the list of maps, download status and the maps
  Scrollkeeper opens in Mapsmith.
- R1.3 Printing, and exporting tiles to a PDF wherever the user saves it.
- R1.4 Images dragged in from another app, such as Pluck.

## R2 Moving in
- R2.1 On the first sandboxed launch, Mapsmith's preferences move into its
  container.
- R2.2 Files opened before the move are not in Open Recent any more, and
  windows aren't restored from before it; opening a file again brings it back.
