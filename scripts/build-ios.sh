#!/bin/sh
# SPDX-License-Identifier: AGPL-3.0-only
set -eu
HARMONY_VARIANT=${1:?Use unsigned-device or simulator}
HARMONY_SHA=$(git rev-parse HEAD)
HARMONY_CHANNEL=$(git branch --show-current)
case "$HARMONY_VARIANT" in
    unsigned-device) HARMONY_SDK=iphoneos; HARMONY_DEST='generic/platform=iOS';;
    simulator) HARMONY_SDK=iphonesimulator; HARMONY_DEST='generic/platform=iOS Simulator';;
    *) echo 'Unsupported build variant' >&2; exit 2;;
esac
mkdir -p artifacts
xcodebuild -project Harmony.xcodeproj -scheme Harmony -configuration Release -sdk "$HARMONY_SDK" -destination "$HARMONY_DEST" -derivedDataPath .build/ios CODE_SIGNING_ALLOWED=NO HARMONY_COMMIT="$HARMONY_SHA" build
HARMONY_PRODUCT=".build/ios/Build/Products/Release-$HARMONY_SDK/Harmony.app"
test -x "$HARMONY_PRODUCT/Harmony"
plutil -extract CFBundleIdentifier raw "$HARMONY_PRODUCT/Info.plist" | grep -qx it.xarber.harmony
lipo -archs "$HARMONY_PRODUCT/Harmony"
HARMONY_NAME="Harmony-v0.1.0-$HARMONY_CHANNEL-$HARMONY_VARIANT-$(git rev-parse --short HEAD)"
if [ "$HARMONY_VARIANT" = unsigned-device ]; then
    mkdir -p .build/ipa/Payload
    ditto "$HARMONY_PRODUCT" .build/ipa/Payload/Harmony.app
    ditto -c -k --keepParent .build/ipa/Payload "artifacts/$HARMONY_NAME.ipa"
else
    ditto -c -k --keepParent "$HARMONY_PRODUCT" "artifacts/$HARMONY_NAME.app.zip"
fi
shasum -a 256 artifacts/* > artifacts/SHA256SUMS.txt
python3 - "$HARMONY_SHA" "$HARMONY_CHANNEL" "$HARMONY_VARIANT" <<'PY'
import json,sys
from pathlib import Path
Path('artifacts/build.json').write_text(json.dumps({'version':'0.1.0','build':1,'commit':sys.argv[1],'channel':sys.argv[2],'variant':sys.argv[3],'signed':False},indent=2)+'\n')
PY
