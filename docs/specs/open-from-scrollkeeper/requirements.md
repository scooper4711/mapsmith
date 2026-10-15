# Open from Scrollkeeper: requirements

Scrollkeeper keeps the user's Paizo library. Mapsmith lets the user pick a map
they own by name and have Scrollkeeper deliver it, instead of finding the file
in Finder. The handoff contract is owned by Scrollkeeper:
[`docs/specs/app-handoff`](https://github.com/scooper4711/scrollkeeper/tree/main/docs/specs/app-handoff).

## R1 Finding a map
- R1.1 File ▸ Open from Scrollkeeper… (⇧⌘O) shows a search sheet on the
  frontmost window.
- R1.2 The sheet lists the map titles the user owns, as listed by
  Scrollkeeper: Flip-Mats, Flip-Tiles, Map Packs, Poster Maps and the like.
- R1.3 Typing narrows the list to titles whose title or series contains every
  typed word, ignoring case and accents. An empty search shows every title.
- R1.4 The sheet says when Scrollkeeper last updated the list.
- R1.5 The best match is selected as the user types, so Return opens it.

## R2 Opening a map
- R2.1 Choosing a title (double-click, or Return on the selection) closes the
  sheet and asks Scrollkeeper to open it in Mapsmith.
- R2.2 Scrollkeeper downloads the title when needed and sends its PDFs and
  images back; each opens in its own window (multiple-documents R1).
- R2.3 Titles that are not on disk yet show a cloud icon, and the open button
  reads "Download and Open" while one is selected.
- R2.4 Clicking the cloud asks Scrollkeeper, staying in the background, to
  download the title without opening it. A spinner replaces the cloud until
  Scrollkeeper's list shows the title downloaded; then neither is shown.
- R2.5 Mapsmith never signs in to Paizo or downloads files itself.

## R3 When the list is not available
- R3.1 When Scrollkeeper is not installed, the sheet says so and links to its
  download page.
- R3.2 When Scrollkeeper has not listed the library yet, the sheet asks the
  user to open Scrollkeeper and sign in, with a button that opens it.
- R3.3 When the list is in a newer format than Mapsmith understands, the
  sheet asks the user to update Mapsmith.
