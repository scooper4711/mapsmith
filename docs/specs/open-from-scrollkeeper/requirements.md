# Open from Scrollkeeper: requirements

Scrollkeeper keeps the user's Paizo library. Mapsmith lets the user pick a map
they own by name and have Scrollkeeper deliver it, instead of finding the file
in Finder. The handoff contract is owned by Scrollkeeper:
[`docs/specs/app-handoff`](https://github.com/scooper4711/scrollkeeper/tree/main/docs/specs/app-handoff).

## R1 Finding a map
- R1.1 File ▸ Open from Scrollkeeper… (⇧⌘O) shows a search sheet on the
  frontmost window.
- R1.2 The sheet asks Scrollkeeper, which stays in the background, for the
  map titles the user owns (Flip-Mats, Flip-Tiles, Map Packs, Poster Maps and
  the like) and lists them. Until they arrive it says it is asking; after 15
  seconds without an answer it says Scrollkeeper may still be loading or need
  the user to sign in, with buttons to open Scrollkeeper and to try again.
- R1.3 Typing narrows the list to titles whose title or series contains every
  typed word, ignoring case and accents. An empty search shows every title.
- R1.4 The sheet says when Scrollkeeper last updated the list.
- R1.5 The best match is selected as the user types, so Return opens it.

## R2 Opening a map
- R2.1 Choosing a title (double-click, or Return on the selection) asks
  Scrollkeeper, staying in the background, to open it in Mapsmith. A title on
  disk closes the sheet at once; for one that needs downloading the sheet
  stays, shows the download's progress, and closes when the files are on their
  way.
- R2.2 Scrollkeeper downloads the title when needed and sends its PDFs and
  images back; each opens in its own window (multiple-documents R1).
- R2.3 Titles that are not on disk yet show a cloud icon, and the open button
  reads "Download and Open" while one is selected.
- R2.4 Clicking the cloud asks Scrollkeeper, staying in the background, to
  download the title without opening it. A progress bar replaces the cloud
  while Scrollkeeper reports the download, and neither is shown once it is
  done.
- R2.6 When a request fails, the title shows a warning and the sheet shows
  Scrollkeeper's reason while the title is selected.
- R2.5 Mapsmith never signs in to Paizo or downloads files itself.

## R3 When the list is not available
- R3.1 When Scrollkeeper is not installed, the sheet says so and links to its
  download page.
- R3.2 When Scrollkeeper can't send the list (for example, no one is signed
  in), the sheet shows its reason, with buttons to open Scrollkeeper and to
  try again. When the list can't be read, the sheet says so and offers to try
  again.
- R3.3 When the list is in a newer format than Mapsmith understands, the
  sheet asks the user to update Mapsmith.
