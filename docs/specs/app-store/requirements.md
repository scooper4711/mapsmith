# Mac App Store build: requirements

Mapsmith 2.0 is listed on the Mac App Store beside its notarized disk image (tabletop-kit#26). The packaging steps
are tabletop-kit's `scripts/package-appstore.sh` (its `appstore-build` spec).

## R1 The build
- R1.1 `CHANNEL=appstore scripts/build-app.sh` (or `make appstore`) builds the package `build/appstore/Mapsmith.pkg`
  from the same sources as the disk image; Mapsmith has no updater or payment link to leave out.
- R1.2 The build number (`BUILD_NUMBER`) is apart from the version and increases with every upload.
- R1.3 The bundle declares `ITSAppUsesNonExemptEncryption` as false, a copyright line and the real version.

## R2 Privacy
- R2.1 A privacy manifest ships in the bundle: no tracking, no data collected, and no required-reason APIs while
  Mapsmith uses none.
- R2.2 `PRIVACY.md` is the privacy policy, linked from the Help menu, and says Mapsmith makes no network requests.

## R3 Review
- R3.1 `APP-STORE-REVIEW.md` holds the review notes, with a use named for every entitlement.
