# Open from Scrollkeeper: requirements

Scrollkeeper keeps the user's Paizo library. Mapsmith lets the user pick a map
they own by name, from the library Scrollkeeper shares, and have Scrollkeeper
deliver it when it isn't on disk yet, instead of finding the file in Finder.
The handoff contract is owned by Scrollkeeper:
[`docs/specs/app-handoff`](https://github.com/scooper4711/scrollkeeper/tree/main/docs/specs/app-handoff).

## R1 Finding a map
- R1.1 File ▸ Open from Scrollkeeper… (⇧⌘O) opens a search window, also when
  no map is open.
- R1.2 The window lists the map titles the user owns (Flip-Mats, Flip-Tiles,
  Map Packs, Poster Maps and the like) from the library Scrollkeeper shares
  through the Tableside Toolkit's App Group (Scrollkeeper's app-handoff
  requirements 5 and 6), at once and without starting Scrollkeeper, and shows
  each map's cover.
- R1.3 Typing narrows the list to titles whose title or series contains every
  typed word, ignoring case and accents. An empty search shows every title.
- R1.4 The window says when Scrollkeeper last updated the list.
- R1.5 The best match is selected as the user types, so Return opens it.
- R1.6 The shared library is the only source of the list: Mapsmith never asks
  Scrollkeeper to send it, on the Mac as on the iPad (ipad-app R2). A build
  outside the App Group, such as an ad hoc development build, has no list.
- R1.7 The list follows Scrollkeeper's changes while the window is open, such
  as a download finishing.

## R2 Opening a map
- R2.1 Choosing a title (double-click, or Return on the selection) asks
  Scrollkeeper, staying in the background, to open it in Mapsmith. A title on
  disk closes the window at once; for one that needs downloading the window
  stays, shows the download's progress, and closes when the files are on their
  way.
- R2.2 Scrollkeeper downloads the title when needed and sends its PDFs and
  images back; each opens in its own window (multiple-documents R1).
- R2.2a A title already up to date in Scrollkeeper's shared download folder
  opens straight from there, without asking Scrollkeeper, choosing the files
  as Scrollkeeper would: a single file first, otherwise an unpacked archive's
  PDFs, or its images when it has none. A title in a download folder the user
  chose, which Mapsmith can't read, is still asked for.
- R2.3 Titles that are not on disk yet show a cloud icon, and the open button
  reads "Download and Open" while one is selected.
- R2.4 Clicking the cloud asks Scrollkeeper, staying in the background, to
  download the title without opening it. A progress bar replaces the cloud
  while Scrollkeeper reports the download, and neither is shown once it is
  done.
- R2.6 When a request fails, the title shows a warning and the window shows
  Scrollkeeper's reason while the title is selected.
- R2.5 Mapsmith never signs in to Paizo or downloads files itself.

## R3 When the list is not available
- R3.1 When Scrollkeeper is not installed, the window says so and links to its
  download page.
- R3.2 When Scrollkeeper hasn't shared its library (it hasn't loaded one yet,
  for example because no one is signed in), the window says so, with a button
  to open Scrollkeeper, and lists the maps as soon as Scrollkeeper shares
  them. When the list can't be read, the window says so and offers to try
  again.
- R3.3 When the list is in a newer format than Mapsmith understands, the
  window asks the user to update Mapsmith.
