# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- On an iPhone, a file of several maps opens on its first map, with the list of maps a tap away

### Fixed
- The printer picker now appears on the iPad, from the settings and from Ink Prices
- An A3 page counts as two A4 pages of ink
- On an iPhone, Mapsmith opens on the map and not on an empty list
- On the Mac, the printer and paper chosen in Page Setup are remembered the next time Mapsmith opens

## [2.1.0] - 2026-11-21

### Added
- Add the About screen with Paizo's notices
- Add File › New from Clipboard
- Add the iPad app
- Let the Scrollkeeper bridge read only the shared library

### Fixed
- Ask Scrollkeeper on the iPad to download the chosen map

### Changed
- Update tabletop-kit to 1.11.4
- Time out CI jobs instead of waiting 6 hours
- Pin the GitHub actions to commit hashes
- Run the tests on the self-hosted Mac mini
- Require tabletop-kit 1.5.0
- Require tabletop-kit 1.4.1
- Drop the AI disclosure rule from CONTRIBUTING
- Number every build by the commits on main
- Number every build by the commits on main
- Use tabletop-kit 1.4.0
- Specify Mapsmith's About screen
- Read only Scrollkeeper's shared library for the map list
- Specify reading only Scrollkeeper's shared library
- Use the shared Scrollkeeper bridge from tabletop-kit
- Specify the shared Scrollkeeper bridge
- Share the app between the Mac and the iPad in MapsmithUI
- Add the iPad app spec

[2.1.0]: https://github.com/scooper4711/mapsmith/releases/tag/v2.1.0

## [2.0.0] - 2026-11-13

### Added
- Use tabletop-kit's shared empty window
- Call an unused cartridge "Exclude from estimate"
- Add a tooltip to the cartridge ink picker
- Price each ink cartridge individually
- Build Mapsmith for the Mac App Store
- Show the ink cost of a map in the inspector
- Estimate the ink a map needs and what it costs
- Read Scrollkeeper's library from the App Group

### Fixed
- Refuse a scale that needs more than ten pages across or down

### Changed
- Wrap a long help text line
- Say the ink settings only affect the cost estimate
- Explain unused cartridges and tighten the third-party note
- Explain where to find each cartridge's page yield
- Say what deleting the app leaves on a Mac
- Say where the review notes live and drop a wrong comment
- Use tabletop-kit 0.17.0
- Add ink cost spec
- Use tabletop-kit 0.16.0
- Use TablesideShared for Scrollkeeper's library
- Specify reading Scrollkeeper's shared library
- Welcome signed commits without requiring them
- Add a contributing guide

[2.0.0]: https://github.com/scooper4711/mapsmith/releases/tag/v2.0.0

## [1.2.1] - 2026-10-20

[1.2.1]: https://github.com/scooper4711/mapsmith/releases/tag/v1.2.1

## [1.2.0] - 2026-10-20

### Added
- Run Mapsmith in the App Sandbox
- Wait for typing to pause and scale by squares
- Ask Scrollkeeper for the map list and follow its status

### Fixed
- Switch the bundle ID to io.github.scooper4711.Mapsmith
- Keep Open from Scrollkeeper in front while it waits
- Open from Scrollkeeper in a window, not a sheet
- Bundle the universal binary from where SwiftPM built it

### Changed
- Specify running in the App Sandbox
- Specify entering the print scale
- Ask Scrollkeeper for the map list and show its progress
- Show the Open from Scrollkeeper sheet
- Say the maps are the ones you own
- Lead with printing any Paizo map you own on demand
- Allow trial release builds run by hand

[1.2.0]: https://github.com/scooper4711/mapsmith/releases/tag/v1.2.0

## [1.1.0] - 2026-10-15

### Added
- Skip edge strips under one inch by default
- Show and download maps that are not on disk yet
- Open maps from Scrollkeeper by name
- Read and search Scrollkeeper's list of owned maps

### Fixed
- Find the test bundle under newer SwiftPM layouts

### Changed
- Describe opening maps from Scrollkeeper
- Add open from Scrollkeeper spec
- Say the toolkit is Mac apps, two also on the iPad

[1.1.0]: https://github.com/scooper4711/mapsmith/releases/tag/v1.1.0

## [1.0.0] - 2026-10-15

### Added
- Initial release

[1.0.0]: https://github.com/scooper4711/mapsmith/releases/tag/v1.0.0
