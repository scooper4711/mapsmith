# App Sandbox: design

- `Resources/Mapsmith.entitlements`: the App Sandbox, printing, and read-write
  access to files the user picks (File ▸ Open, the export save panel). Files
  opened from Finder, the Dock, Open Recent and by Scrollkeeper come through
  Launch Services, which grants access to them; Open Recent keeps that access
  across launches. No network access: Mapsmith makes no requests.
- `scripts/build-app.sh` signs with the entitlements and copies
  `Resources/container-migration.plist` into the bundle's Resources. On the
  first sandboxed launch macOS moves the preferences
  (`com.github.scooper4711.Mapsmith.plist`, window layouts only) into
  `~/Library/Containers/com.github.scooper4711.Mapsmith`.
- **Signing.** `scripts/sign-app.sh` signs the app with the first Developer ID
  Application certificate in the keychain, with the hardened runtime and a
  secure timestamp, or ad hoc when there is none (`SIGNING_IDENTITY` overrides
  it). On GitHub, `scripts/add-signing-certificate.sh` puts the certificate from
  the `DEVELOPER_ID_CERTIFICATE` and `DEVELOPER_ID_CERTIFICATE_PASSWORD` secrets
  into a temporary keychain; without it a release fails and a trial build is
  signed ad hoc. For a release, `scripts/notarize.sh` signs the disk image, has
  Apple's notary service check it (the `NOTARY_APPLE_ID`, `NOTARY_TEAM_ID` and
  `NOTARY_PASSWORD` secrets, or a notarytool keychain profile on a Mac) and
  staples the ticket to it. The team ID is kept only in the secrets and the
  keychain.
- `DroppedImageStore` writes dropped images under `temporaryDirectory`, which
  is inside the container.
- SwiftUI doesn't restore document windows in the sandbox: it would need a
  security-scoped bookmark for each file, which the restored URL doesn't carry.
  Mapsmith opens with its empty window instead.
