# macOS Distribution (Developer ID + Notarization)

This is a step-by-step, non–Mac App Store distribution flow for a Flutter macOS app using Developer ID signing and Apple notarization. The result is a DMG (or ZIP) that opens cleanly on other Macs with minimal security warnings.

## Prerequisites

- Paid **Apple Developer Program** membership.
- A macOS machine with Xcode installed.
- Developer ID certificates in your Keychain:
  - **Developer ID Application**
  - **Developer ID Installer** (only needed if you later ship a .pkg; not required for DMG/ZIP)
- App-specific password or App Store Connect API key for notarization.
- Flutter installed and your macOS build working locally.

## 1) Build a Release App

From the repo root:

```bash
flutter clean
flutter pub get
flutter build macos --release
```

The output app bundle should be at:

```
build/macos/Build/Products/Release/<YourAppName>.app
```

## 2) Determine Identifiers

Pick values that match your app setup:

- **Bundle ID**: e.g. `com.yourcompany.deep-time`
- **App name**: `<YourAppName>.app`
- **Developer Team ID**: 10-character ID from Apple Developer portal
- **Developer ID Application** certificate name from Keychain

## 3) Code Sign the App

Sign the .app with the Developer ID Application cert.

```bash
codesign --force --options runtime --timestamp \
  --sign "Developer ID Application: YOUR NAME (TEAMID)" \
  "build/macos/Build/Products/Release/<YourAppName>.app"
```

Verify:

```bash
codesign --verify --deep --strict --verbose=2 \
  "build/macos/Build/Products/Release/<YourAppName>.app"
```

## 4) Create a DMG (Recommended) or ZIP

### Option A: DMG (best user experience)

Example with `create-dmg` (install via Homebrew):

```bash
brew install create-dmg

create-dmg \
  --volname "<YourAppName>" \
  --window-pos 200 120 \
  --window-size 800 400 \
  --icon-size 120 \
  --icon "<YourAppName>.app" 200 190 \
  --app-drop-link 600 185 \
  "dist/<YourAppName>.dmg" \
  "build/macos/Build/Products/Release/<YourAppName>.app"
```

### Option B: ZIP (simple but less polished)

```bash
ditto -c -k --sequesterRsrc --keepParent \
  "build/macos/Build/Products/Release/<YourAppName>.app" \
  "dist/<YourAppName>.zip"
```

## 5) Notarize the DMG/ZIP

You have two common options: **app-specific password** or **App Store Connect API key**. Choose one.

### Option A: App-Specific Password

Create an app-specific password in your Apple ID account.

```bash
xcrun notarytool submit "dist/<YourAppName>.dmg" \
  --apple-id "you@example.com" \
  --team-id "TEAMID" \
  --password "APP_SPECIFIC_PASSWORD" \
  --wait
```

### Option B: API Key (preferred for CI)

```bash
xcrun notarytool submit "dist/<YourAppName>.dmg" \
  --key "AuthKey_XXXXXXXXXX.p8" \
  --key-id "KEYID" \
  --issuer "ISSUER_ID" \
  --wait
```

## 6) Staple the Notarization Ticket

```bash
xcrun stapler staple "dist/<YourAppName>.dmg"
```

Verify:

```bash
xcrun stapler validate "dist/<YourAppName>.dmg"
spctl -a -vv "dist/<YourAppName>.dmg"
```

## 7) Distribute

Share the signed, notarized DMG/ZIP with testers or colleagues.

Best practice:
- Use a stable download link (e.g. private S3 bucket, Google Drive, or GitHub Releases).
- Avoid re-zipping after notarization.

## Optional: Sign a ZIP Instead of a DMG

If you choose ZIP distribution, notarize the ZIP directly and distribute it as-is. The user experience is slightly less polished but still works fine.

## Troubleshooting Notes

- If Gatekeeper still warns, ensure you are:
  - Signing the **.app** before packaging.
  - Notarizing the **DMG/ZIP**, not just the app.
  - Stapling the ticket **after** notarization.
- If notarization fails, run:

```bash
xcrun notarytool log <SUBMISSION_ID>
```

## Summary Checklist

1. `flutter build macos --release`
2. `codesign --options runtime --timestamp ... <YourAppName>.app`
3. Create DMG or ZIP
4. `xcrun notarytool submit ... --wait`
5. `xcrun stapler staple ...`
6. Distribute
