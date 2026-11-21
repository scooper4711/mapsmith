# iPad app: requirements

Mapsmith also runs on the iPad (and the iPhone, which gets the same layout in a
compact width). It prints the same true-scale tiles as the Mac app: one grid
square per inch, ready to trim and tape together.

## R1 Opening a map
- R1.1 With no map open, the window offers Open… and Open from Scrollkeeper…,
  as on the Mac.
- R1.2 Open… shows the system file browser for PDFs and images. The file is
  read in place; it is not copied into Mapsmith.
- R1.3 A PDF or image shared to Mapsmith from Files or another app ("Open in
  Mapsmith") opens in the window, replacing the map shown.
- R1.4 A PDF or image dropped on the window opens, as on the Mac.
- R1.5 The iPad shows one map at a time; opening another replaces it.
- R1.6 An iPhone shows one screen at a time. It opens on the map, or on the
  two ways in when no map is open, never on the list of maps. The list is
  reached only when the file holds more than one map, and choosing a map
  there shows it. The settings open when asked for.

## R2 Open from Scrollkeeper
- R2.1 Open from Scrollkeeper… lists the maps the user owns from
  Scrollkeeper's library in the Tableside Toolkit's App Group, with covers and
  the same search as on the Mac.
- R2.2 A map Scrollkeeper has downloaded opens straight from the shared folder.
- R2.3 Scrollkeeper on the iPad takes no requests from other apps, so a map
  not downloaded yet has an Open Scrollkeeper button instead of a download
  button; once Scrollkeeper has downloaded it, it opens in Mapsmith.
- R2.4 The list is read again when Mapsmith comes back to the foreground and
  when Scrollkeeper says its library changed.
- R2.5 When there is no shared library (Scrollkeeper isn't installed or hasn't
  loaded the library yet), the sheet says so and offers to open Scrollkeeper,
  or to get it when it isn't installed.

## R3 Paper and printing
- R3.1 The iPad has no Page Setup. The inspector has a paper picker (US
  Letter, US Legal, A4, A3, Tabloid) and a margin, the printer's unprintable
  border, defaulting to 1/4 in, which fits most AirPrint printers. Both are
  remembered.
- R3.2 Tiles are planned for the chosen paper's printable area, as on the Mac.
- R3.3 Print shows the system print panel and prints every page at 100%
  scale: the page is never scaled to fit the printer's printable area, and the
  printer is asked for the chosen paper size.
- R3.4 Export saves the tiles as a PDF through the system file browser.

## R4 Ink cost
- R4.1 The printer the ink prices belong to is chosen with the system printer
  picker and remembered.
- R4.2 Ink Prices… (toolbar) shows the same cartridge settings as the Mac's
  Settings, starting from cyan, magenta, yellow and black, since AirPrint
  doesn't list a printer's supplies.

## R5 Layout
- R5.1 The map list, preview and inspector fit in landscape and portrait.
- R5.2 The Mac app keeps working as before.

## R6 About
- R6.1 Every version has an About screen with the notice Paizo's Community Use Policy prescribes and the
  trademark line (tabletop-kit R6): on the Mac, About Mapsmith in the app menu; on the iPad and iPhone, About in
  the toolbar, and on the iPad also About Mapsmith in the menu bar's app menu, which otherwise opens an empty
  window.
