#!/usr/bin/env bash
set -euo pipefail

# One-shot macOS release pipeline for Flutter:
# 1) Build app (optional skip)
# 2) Sign app
# 3) Notarize app
# 4) Staple app
# 5) Create DMG
# 6) Sign DMG
# 7) Notarize DMG
# 8) Staple DMG
#
# Usage:
#   scripts/release_macos_dmg.sh \
#     --signing-identity "Developer ID Application: NAME (TEAMID)" \
#     --notary-profile "tmp-check"
#
# Optional:
#   --app-name "Deep Time"
#   --out-dir "dist/macos-release"
#   --skip-build

APP_NAME="Deep Time"
OUT_DIR="dist/macos-release"
SIGNING_IDENTITY="Developer ID Application: David Browning (QL5QBFGDB7)"
NOTARY_PROFILE="tmp-check"
SKIP_BUILD="false"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --app-name)
      APP_NAME="${2:-}"
      shift 2
      ;;
    --out-dir)
      OUT_DIR="${2:-}"
      shift 2
      ;;
    --signing-identity)
      SIGNING_IDENTITY="${2:-}"
      shift 2
      ;;
    --notary-profile)
      NOTARY_PROFILE="${2:-}"
      shift 2
      ;;
    --skip-build)
      SKIP_BUILD="true"
      shift
      ;;
    -h|--help)
      sed -n '1,120p' "$0"
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      exit 1
      ;;
  esac
done

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${REPO_ROOT}"

if [[ "${SKIP_BUILD}" != "true" ]]; then
  echo "[1/12] Building Flutter macOS release..."
  flutter build macos --release
else
  echo "[1/12] Skipping build."
fi

SOURCE_APP="build/macos/Build/Products/Release/${APP_NAME}.app"
if [[ ! -d "${SOURCE_APP}" ]]; then
  echo "App not found: ${SOURCE_APP}" >&2
  exit 1
fi

mkdir -p "${OUT_DIR}"

APP_PATH="${OUT_DIR}/${APP_NAME}.app"
APP_ZIP_PATH="${OUT_DIR}/${APP_NAME}.zip"
DMG_PATH="${OUT_DIR}/${APP_NAME}.dmg"

echo "[2/12] Staging app..."
rm -rf "${APP_PATH}"
cp -R "${SOURCE_APP}" "${APP_PATH}"

echo "[3/12] Removing AppleDouble sidecars from app..."
find "${APP_PATH}" -name '._*' -type f -delete || true

echo "[4/12] Clearing quarantine attrs..."
xattr -cr "${APP_PATH}" || true

echo "[5/12] Signing app..."
codesign --deep --force --options runtime --timestamp \
  --sign "${SIGNING_IDENTITY}" \
  "${APP_PATH}"

echo "[6/12] Verifying app signature..."
codesign --verify --deep --strict --verbose=2 "${APP_PATH}"

echo "[7/12] Zipping app for notarization..."
rm -f "${APP_ZIP_PATH}"
ditto -c -k --sequesterRsrc --keepParent "${APP_PATH}" "${APP_ZIP_PATH}"

echo "[8/12] Notarizing app zip..."
xcrun notarytool submit "${APP_ZIP_PATH}" \
  --keychain-profile "${NOTARY_PROFILE}" \
  --wait

echo "[9/12] Stapling app..."
xcrun stapler staple "${APP_PATH}"
spctl --assess --type execute --verbose "${APP_PATH}"

echo "[10/12] Creating DMG..."
rm -f "${DMG_PATH}"
hdiutil create -volname "${APP_NAME}" -srcfolder "${APP_PATH}" -ov -format UDZO "${DMG_PATH}"

echo "[11/12] Signing DMG..."
codesign --force --timestamp --sign "${SIGNING_IDENTITY}" "${DMG_PATH}"

echo "[12/12] Notarizing/stapling DMG and validating mounted app..."
xcrun notarytool submit "${DMG_PATH}" \
  --keychain-profile "${NOTARY_PROFILE}" \
  --wait
xcrun stapler staple "${DMG_PATH}"

ATTACH_OUTPUT="$(hdiutil attach -readonly -nobrowse "${DMG_PATH}")"
MOUNT_DEVICE="$(printf '%s\n' "${ATTACH_OUTPUT}" | awk '/^\/dev\/disk/ && /\/Volumes\// {print $1; exit}')"
MOUNT_POINT="$(printf '%s\n' "${ATTACH_OUTPUT}" | awk '/^\/dev\/disk/ && /\/Volumes\// {print $NF; exit}')"

if [[ -z "${MOUNT_DEVICE}" || -z "${MOUNT_POINT}" ]]; then
  echo "Failed to determine DMG mount point/device." >&2
  exit 1
fi

MOUNTED_APP="${MOUNT_POINT}/${APP_NAME}.app"
spctl --assess --type execute --verbose "${MOUNTED_APP}"
codesign --verify --deep --strict --verbose=2 "${MOUNTED_APP}"
hdiutil detach "${MOUNT_DEVICE}" >/dev/null

echo
echo "Done."
echo "App: ${APP_PATH}"
echo "App zip: ${APP_ZIP_PATH}"
echo "DMG: ${DMG_PATH}"
